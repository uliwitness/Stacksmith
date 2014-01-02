//
//  WILDDocument.m
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

/*!
	@header WILDDocument
	Stacksmith's main document class.
*/

#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDCard.h"
#import "WILDXMLUtils.h"
#import "WILDCardViewController.h"
#import "WILDCardView.h"
#import "NSFileHandle+UKReadLinewise.h"
#import "UKProgressPanelController.h"
#import "NSView+SizeWindowForViewSize.h"
#import "WILDStyleEntry.h"
#import "WILDMediaEntry.h"
#import "UKRandomInteger.h"
#import "WILDCardWindowController.h"
#import <Quartz/Quartz.h>
#import "NSFileManager+NameForTempFile.h"
#import "WILDSearchPaths.h"
#import "UKHelperMacros.h"
#import "WILDXMLUtils.h"
#import "LEOContextGroup.h"
#include "CDocument.h"
#include "CPartRegistration.h"


@interface WILDDocument ()
{
	Calhoun::CDocument		mDocument;
}

@end


/*!
	@class WILDDocument
	A document referencing the Stacksmith file on disk, containing one or more stacks, plus any information global to the file.
*/

@implementation WILDDocument

/*!
	@method		init
	@abstract	Default constructor, used both for loading stacks from disk and for creating a completely new stack on creation.
	@seealso	//leo_ref/occ/instm/WILDDocument/readFromURL:ofType:error: -readFromURL:ofType:error:
*/

-(id)	init;
{
    self = [super init];
    if( self )
	{
		mMediaIDSeed = 128;
		mStackIDSeed = 1;
		
		mFontIDTable = [[NSMutableDictionary alloc] init];
		mTextStyles = [[NSMutableDictionary alloc] init];
		mMediaList = [[NSMutableArray alloc] init];
		mStacks = [[NSMutableArray alloc] init];
		[mStacks addObject: [[[WILDStack alloc] initWithDocument: self] autorelease]];
 
		NSString*	appVersion = [NSString stringWithFormat: @"Stacksmith %@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]];
		mCreatedByVersion = [appVersion retain];
		mLastCompactedVersion = [appVersion retain];
		mFirstEditedVersion = [appVersion retain];
		mLastEditedVersion = [appVersion retain];

		NSError	*	outError = nil;
		[self loadStandardResourceTableReturningError: &outError];
	}
    return self;
}


-(void)	dealloc
{
	DESTROY_DEALLOC(mErrorsAndWarnings);
	DESTROY_DEALLOC(mFontIDTable);
	DESTROY_DEALLOC(mTextStyles);
	DESTROY_DEALLOC(mMediaList);
	DESTROY_DEALLOC(mStacks);
	DESTROY_DEALLOC(mCreatedByVersion);
	DESTROY_DEALLOC(mLastCompactedVersion);
	DESTROY_DEALLOC(mFirstEditedVersion);
	DESTROY_DEALLOC(mLastEditedVersion);
	
	if( mContextGroup )
	{
		LEOContextGroupRelease( mContextGroup );
		mContextGroup = NULL;
	}
	
	[super dealloc];
}


/*!
	@method		makeWindowControllers
	@abstract	Add a window controller for each stack's window.
*/

-(void)	makeWindowControllers;
{
	for( WILDStack* currStack in mStacks )
	{
		WILDCardWindowController*	cardWC = [[WILDCardWindowController alloc] initWithStack: currStack];
		[self addWindowController: cardWC];
		[cardWC release];
	}
}


//- (NSString *)windowNibName
//{
//    // Override returning the nib file name of the document
//    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
//    return @"WILDDocument";
//}
//
//- (void)windowControllerDidLoadNib:(NSWindowController *) aController
//{
//    [super windowControllerDidLoadNib: aController];
//
//	if( [self fileURL] )
//	{
//		NSString*	iconPath = [[[self fileURL] path] stringByAppendingPathComponent: @"Icon\r"];
//		if( ![[NSFileManager defaultManager] fileExistsAtPath: iconPath] )
//			[self performSelector: @selector(generatePreview) withObject: nil afterDelay: 0.0];
//	}
//}


/*!
	@method		fileHandle:ofImporterDidReadLine:
	@abstract	Called to parse each line output by stackimport when importing a HyperCard stack. Fills our errors/warnings list and updates progress display.
*/

-(void)	fileHandle: (NSFileHandle*)fh ofImporterDidReadLine: (NSString*)currLine;
{
	if( !currLine )
	{
		[[UKProgressPanelController sharedProgressController] setDoubleValue: [[UKProgressPanelController sharedProgressController] maxValue]];
		return;
	}
	
	if( [currLine hasPrefix: @"Progress: "] )
	{
		NSRange		theOfRange = [currLine rangeOfString: @" of "];
		NSString*	currVal = [currLine substringWithRange: NSMakeRange( 10, theOfRange.location -10 )];
		NSString*	maxVal = [currLine substringFromIndex: theOfRange.location +theOfRange.length];
		[[UKProgressPanelController sharedProgressController] setIndeterminate: NO];
		[[UKProgressPanelController sharedProgressController] setMaxValue: [maxVal integerValue]];
		[[UKProgressPanelController sharedProgressController] setDoubleValue: [currVal integerValue]];
	}
	else if( [currLine hasPrefix: @"Status: "] )
	{
		[[UKProgressPanelController sharedProgressController] setStringValue: [currLine substringFromIndex: 8]];
	}
	else
	{
		[mErrorsAndWarnings addObject: currLine];
		NSLog( @"%@", currLine );
	}
}


/*!
	@method		writeToURL:ofType:forSaveOperation:originalContentsURL:error:
	@abstract	Write any changes to this document back out to disk.
	@seealso	//leo_ref/occ/instm/WILDDocument/readFromURL:ofType:error:	-readFromURL:ofType:error:
*/

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError;
{
	if( ![[NSFileManager defaultManager] fileExistsAtPath: [absoluteURL path]] )
	{
		if( ![[NSFileManager defaultManager] createDirectoryAtPath: [absoluteURL path] withIntermediateDirectories:NO attributes: nil error: outError] )
			return NO;
	}
	
	NSMutableString	*	tocXmlString = [NSMutableString stringWithString:
											@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
												"<!DOCTYPE stackfile PUBLIC \"-//Apple, Inc.//DTD stackfile V 2.0//EN\" \"\" >\n"
												"<stackfile>\n"];
	
	// Write out each stack:
	for( WILDStack * currStack in mStacks )
	{
		NSString	*	stackFileName = nil;
		NSURL		*	stackURL = nil;
		stackFileName = [NSString stringWithFormat: @"stack_%lld.xml", [currStack stackID]];
		stackURL = [absoluteURL URLByAppendingPathComponent: stackFileName];
		
		if( ![[currStack xmlStringForWritingToURL: absoluteURL forSaveOperation: saveOperation originalContentsURL: absoluteOriginalContentsURL error: outError] writeToURL: stackURL atomically: YES encoding: NSUTF8StringEncoding error:outError] )
			return NO;
		[tocXmlString appendFormat: @"\t<stack id=\"%1$lld\" file=\"stack_%1$lld.xml\" name=\"%2$@\" />\n", [currStack stackID], WILDStringEscapedForXMLAttribute(currStack.name)];
	}
	
	DESTROY(mLastEditedVersion);
	mLastEditedVersion = [[NSString stringWithFormat: @"Stacksmith %@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]] retain];
	
	// Write TOC:
	[tocXmlString appendFormat: @"\t<createdByVersion>%@</createdByVersion>\n", mCreatedByVersion];
	[tocXmlString appendFormat: @"\t<lastCompactedVersion>%@</lastCompactedVersion>\n", mLastCompactedVersion];
	[tocXmlString appendFormat: @"\t<lastEditedVersion>%@</lastEditedVersion>\n", mLastEditedVersion];
	[tocXmlString appendFormat: @"\t<firstEditedVersion>%@</firstEditedVersion>\n", mFirstEditedVersion];

	// Write media entries:
	for( WILDMediaEntry	*	currMedia in mMediaList )
	{
		if( ![currMedia isBuiltIn] )
		{
			if( ![currMedia writeToFolderURLIfNeeded: absoluteURL withOriginalFolderURL: absoluteOriginalContentsURL forSaveOperation: saveOperation] )
				return NO;
			[tocXmlString appendString: [currMedia xmlString]];
		}
	}
	
	[tocXmlString appendString: @"</stackfile>\n"];
	NSURL	*	tocURL = [absoluteURL URLByAppendingPathComponent: @"toc.xml"];
	if( ![tocXmlString writeToURL: tocURL atomically: YES encoding: NSUTF8StringEncoding error:outError] )
		return NO;
		
	return YES;
}


/*!
	@method		loadStandardResourceTableReturningError:
	@abstract	Load built-in standard media table so others can access it: (ICONs, PICTs, CURSs and SNDs)
	@param		outError		If en error occurs, this will return an error object.
*/

-(BOOL)	loadStandardResourceTableReturningError: (NSError**)outError;
{
	NSXMLDocument	*	stdDoc = [[[NSXMLDocument alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"resources" ofType: @"xml"]]
														options: 0 error: outError] autorelease];
	if( !stdDoc )
		return NO;
	NSXMLElement	*	stdStackfileElement = [stdDoc rootElement];
	NSArray			*	pictures = [stdStackfileElement elementsForName: @"media"];
	for( NSXMLElement* thePic in pictures )
	{
		NSString	*	iconID = [[[thePic elementsForName: @"id"] objectAtIndex: 0] stringValue];
		NSString	*	iconName = [[[thePic elementsForName: @"name"] objectAtIndex: 0] stringValue];
		NSString	*	fileName = [[[thePic elementsForName: @"file"] objectAtIndex: 0] stringValue];
		NSString	*	type = [[[thePic elementsForName: @"type"] objectAtIndex: 0] stringValue];
		NSPoint			pos = WILDPointFromSubElementInElement( @"hotspot", thePic );
		[self addMediaFile: fileName withType: type name: iconName andID: [iconID integerValue] hotSpot: pos
			imageOrCursor: nil isBuiltIn: YES];
	}
	
	return YES;
}


/*!
	@method		readFromURL:ofType:error:
	@abstract	Load data from a stack XML file into this stack object.
	@seealso	//leo_ref/occ/instm/WILDDocument/init	-init
	@seealso	//leo_ref/occ/instm/WILDDocument/writeToURL:ofType:forSaveOperation:originalContentsURL:error: -writeToURL:ofType:forSaveOperation:originalContentsURL:error:
*/

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;
{
	NSURL*		tocURL = absoluteURL;
	BOOL		isDir = NO;
	if( [[NSFileManager defaultManager] fileExistsAtPath: [absoluteURL path] isDirectory: &isDir] && !isDir )
	{
		ASSIGN(mErrorsAndWarnings,[NSMutableArray array]);
		
		[[UKProgressPanelController sharedProgressController] setIndeterminate: YES];
		[[UKProgressPanelController sharedProgressController] setStringValue: @"Converting HyperCard Stack..."];
		[[UKProgressPanelController sharedProgressController] show];
		
		NSTask*	converterTask = [[[NSTask alloc] init] autorelease];
		[converterTask setLaunchPath: [[NSBundle mainBundle] pathForResource: @"stackimport" ofType: @""]];
		[converterTask setArguments: [NSArray arrayWithObject: [absoluteURL path]]];
		NSPipe*			thePipe = [NSPipe pipe];
		[converterTask setStandardOutput: [thePipe fileHandleForWriting]];
		[converterTask setStandardError: [thePipe fileHandleForWriting]];
		NSFileHandle*	theFileHandle = [thePipe fileHandleForReading];
		[theFileHandle readLinesToEndOfFileNotifyingTarget: self newLineSelector: @selector(fileHandle:ofImporterDidReadLine:)];
		[converterTask launch];
		[converterTask waitUntilExit];
		
		if( [[absoluteURL pathExtension] isEqualToString: @"stak"] )
			absoluteURL = [[absoluteURL URLByDeletingPathExtension] URLByAppendingPathExtension: @"xstk"];
		else
			absoluteURL = [absoluteURL URLByAppendingPathExtension: @"xstk"];
		[self setFileURL: absoluteURL];

		[[UKProgressPanelController sharedProgressController] hide];
		
		[self updateChangeCount: NSChangeReadOtherContents];
	}
	
	tocURL = [absoluteURL URLByAppendingPathComponent: @"toc.xml"];
	
	#if TEST_PORTABLE_DOCUMENT
	Calhoun::CDocument::SetStandardResourcesPath( [[[NSBundle mainBundle] pathForResource: @"resources" ofType: @"xml"] UTF8String] );
	
	mDocument.LoadFromURL( [[tocURL absoluteString] UTF8String], [](Calhoun::CDocument * inDocument)
	{
		Calhoun::CStack		*		theCppStack = inDocument->GetStack( 0 );
		theCppStack->Load( [inDocument](Calhoun::CStack* inStack)
		{
			inStack->GetCard(0)->Load( [inDocument,inStack](Calhoun::CLayer*inCard)
			{
				inDocument->Dump();
			} );
		} );
	});
	
	return YES;
	#endif
	
	NSXMLDocument*	xmlDoc = [[[NSXMLDocument alloc] initWithContentsOfURL: tocURL
														options: 0 error: outError] autorelease];
	if( !xmlDoc && *outError )
	{
		NSLog( @"%@", *outError );
		return NO;
	}
	
	NSXMLElement	*	stackfileElement = [xmlDoc rootElement];
	
	// Load read/written version numbers so we can conditionally react to them:
	mCreatedByVersion = [WILDStringFromSubElementInElement( @"createdByVersion", stackfileElement ) retain];
	mLastCompactedVersion = [WILDStringFromSubElementInElement( @"lastCompactedVersion", stackfileElement ) retain];
	mFirstEditedVersion = [WILDStringFromSubElementInElement( @"firstEditedVersion", stackfileElement ) retain];
	mLastEditedVersion = [WILDStringFromSubElementInElement( @"lastEditedVersion", stackfileElement ) retain];
		
	
	// Load font table so others can access it:
	NSArray			*	fonts = [stackfileElement elementsForName: @"font"];
	for( NSXMLElement* theFontElem in fonts )
	{
		NSString	*	fontID = [[[theFontElem elementsForName: @"id"] objectAtIndex: 0] stringValue];
		NSString	*	fontName = [[[theFontElem elementsForName: @"name"] objectAtIndex: 0] stringValue];
		[self addFont: fontName withID: [fontID integerValue]];
	}
	
	// Load style table so others can access it:
	NSArray			*	pictures = [stackfileElement elementsForName: @"styleentry"];
	int					x = 0;
	for( NSXMLElement* thePic in pictures )
	{
		NSArray		*	fontElems = [thePic elementsForName: @"font"];
		NSString	*	fontName = ([fontElems count] > 0) ? [[fontElems objectAtIndex: 0] stringValue] : nil;
		NSArray		*	idElems = [thePic elementsForName: @"id"];
		NSString	*	styleID = ([idElems count] > 0) ? [[idElems objectAtIndex: 0] stringValue] : nil;
		NSArray		*	textStyles = WILDStringsFromSubElementInElement( @"textStyle",thePic);
		NSArray		*	sizeElems = [thePic elementsForName: @"size"];
		NSString	*	fontSize = ([sizeElems count] > 0) ? [[sizeElems objectAtIndex: 0] stringValue] : nil;
		[self addStyleFormatWithID: styleID ? [styleID intValue] : x
								forFontName: fontName
								     size: fontSize ? [fontSize intValue] : -1
								   styles: textStyles];
		x++;
	}
	
	[mMediaList removeAllObjects];
	
	[self loadStandardResourceTableReturningError: outError];
	
	// Load media table of this document so others can access it: (ICONs, PICTs, CURSs and SNDs)
	pictures = [stackfileElement elementsForName: @"media"];
	for( NSXMLElement* thePic in pictures )
	{
		NSString	*	iconID = [[[thePic elementsForName: @"id"] objectAtIndex: 0] stringValue];
		NSString	*	iconName = [[[thePic elementsForName: @"name"] objectAtIndex: 0] stringValue];
		NSString	*	fileName = [[[thePic elementsForName: @"file"] objectAtIndex: 0] stringValue];
		NSString	*	type = [[[thePic elementsForName: @"type"] objectAtIndex: 0] stringValue];
		NSPoint			pos = WILDPointFromSubElementInElement( @"hotspot", thePic );
		[self addMediaFile: fileName withType: type name: iconName andID: [iconID integerValue] hotSpot: pos
			imageOrCursor: nil isBuiltIn: NO];
	}
	
	// Create a stack root object:
	BOOL				success = NO;
	NSArray			*	stacks = [stackfileElement elementsForName: @"stack"];
	[mStacks removeAllObjects];
	
	for( NSXMLElement* currStackElem in stacks )
	{
		NSXMLNode	*	theFileAttr = [currStackElem attributeForName: @"file"];
		NSString	*	theFileName = [theFileAttr stringValue];
		if( theFileName )
		{
			NSURL		*	theFileURL = [absoluteURL URLByAppendingPathComponent: theFileName];
			NSXMLDocument*	theDoc = [[NSXMLDocument alloc] initWithContentsOfURL: theFileURL options: 0
										error: outError];
			
			WILDStack*	currStack = [[WILDStack alloc] initWithXMLDocument: theDoc
												document: self error: outError];
			if( !currStack )
			{
				[theDoc release];
				return NO;
			}
			
			[mStacks addObject: currStack];
			[theDoc release];
			[currStack release];
			
			success = YES;
		}
	}
	
	return success;
}


-(void)		addFont: (NSString*)fontName withID: (WILDObjectID)fontID
{
	[mFontIDTable setObject: fontName forKey: [NSNumber numberWithLongLong: fontID]];
}


-(NSString*)	fontNameForID: (WILDObjectID)fontID
{
	return [mFontIDTable objectForKey: [NSNumber numberWithLongLong: fontID]];
}


-(void)		addStyleFormatWithID: (WILDObjectID)styleID forFontName: (NSString*)fontName size: (NSInteger)fontSize styles: (NSArray*)fontStyles
{
	WILDStyleEntry*	pse = [[[WILDStyleEntry alloc] initWithFontName: fontName fontSize: fontSize
			styles: fontStyles] autorelease];
	
	[mTextStyles setObject: pse forKey: [NSNumber numberWithInteger: styleID]];
}


-(void)	provideStyleFormatWithID: (NSInteger)oneBasedIdx font: (NSString**)outFontName
			size: (NSInteger*)outFontSize styles: (NSArray**)outFontStyles
{
	WILDStyleEntry*	pse = [mTextStyles objectForKey: [NSNumber numberWithInteger: oneBasedIdx]];
	if( pse )
	{
		*outFontName = [pse fontName];
		*outFontSize = [pse fontSize];
		*outFontStyles = [pse styles];
	}
}


-(WILDObjectID)	uniqueIDForStack
{
	BOOL			notUnique = YES;
	
	while( notUnique )
	{
		notUnique = NO;
		
		for( WILDStack* currStack in mStacks )
		{
			if( [currStack stackID] == mStackIDSeed )
			{
				notUnique = YES;
				mStackIDSeed++;
				break;
			}
		}
	}
	
	return mStackIDSeed;
}


-(WILDObjectID)	uniqueIDForMedia
{
	BOOL			notUnique = YES;
	
	while( notUnique )
	{
		notUnique = NO;
		
		for( WILDMediaEntry* currPict in mMediaList )
		{
			if( [currPict pictureID] == mMediaIDSeed )
			{
				notUnique = YES;
				mMediaIDSeed++;
				break;
			}
		}
	}
	
	return mMediaIDSeed;
}


-(WILDStack*)	stackNamed: (NSString*)inName
{
	if( [inName rangeOfString: @"/"].location != NSNotFound )
	{
		if( [inName caseInsensitiveCompare: [self fileURL].path] != NSOrderedSame )
			return [mStacks objectAtIndex: 0];
		if( [[inName stringByDeletingLastPathComponent] caseInsensitiveCompare: [self fileURL].path] != NSOrderedSame )
			return nil;
		else
			inName = [inName lastPathComponent];
	}
	
	for( WILDStack* currStack in mStacks )
	{
		if( [[[currStack name] stringByDeletingPathExtension] caseInsensitiveCompare: inName] == NSOrderedSame
			|| [[currStack name] caseInsensitiveCompare: inName] == NSOrderedSame )
			return currStack;
	}
	
	if( [inName caseInsensitiveCompare: [[self fileURL] lastPathComponent]] == NSOrderedSame
		|| [inName caseInsensitiveCompare: [[[self fileURL] lastPathComponent] stringByDeletingPathExtension]] == NSOrderedSame )
		return [mStacks objectAtIndex: 0];
	
	return nil;
}


-(WILDStack*)	stackWithID: (WILDObjectID)inID;
{
	for( WILDStack* currStack in mStacks )
	{
		if( [currStack stackID] == inID )
			return currStack;
	}
	
	return nil;
}


-(WILDStack*)	mainStack
{
	return [mStacks objectAtIndex: 0];
}


-(NSURL*)	URLForImageNamed: (NSString*)theName
{
	NSURL*	theURL = [[self fileURL] URLByAppendingPathComponent: theName];
	if( ![theURL checkResourceIsReachableAndReturnError: nil] )
		theURL = [[NSBundle mainBundle] URLForImageResource: theName];
	if( [theURL checkResourceIsReachableAndReturnError: nil] )
		return theURL;
	else
		return nil;
}


-(NSImage*)	imageNamed: (NSString*)theName
{
	NSURL*		imgURL = [[self fileURL] URLByAppendingPathComponent: theName];
	NSImage*	img = [[[NSImage alloc] initWithContentsOfURL: imgURL] autorelease];
	if( !img )
		img = [NSImage imageNamed: theName];
	else
		[img setName: theName];
	return img;
}


//-(NSImage*)	imageForPatternAtIndex: (NSInteger)idx
//{
//	NSImage*	img = [mPatterns objectAtIndex: idx];
//	if( [img isKindOfClass: [NSImage class]] )
//		return img;	// Already cached.
//	
//	img = [self imageNamed: (NSString*)img];
//	if( img )
//		[mPatterns replaceObjectAtIndex: idx withObject: img];
//	
//	return img;
//}


-(void)	addMediaFile: (NSString*)fileName withType: (NSString*)type
			name: (NSString*)iconName andID: (WILDObjectID)iconID hotSpot: (NSPoint)pos
			imageOrCursor: (id)imgOrCursor isBuiltIn: (BOOL)isBuiltIn
{
	NSURL*				fileURL = nil;
	if( fileName )
		fileURL = [self URLForImageNamed: fileName];
	WILDMediaEntry*		pentry = [[[WILDMediaEntry alloc] initWithFilename: [fileURL path]
																withType: type name: iconName andID: iconID hotSpot: pos] autorelease];
	if( imgOrCursor )
		[pentry setImageMovieOrCursor: imgOrCursor];
	if( isBuiltIn )
		[pentry setIsBuiltIn: YES];
	[mMediaList addObject: pentry];
}


-(NSURL*)		URLForMediaOfType: (NSString*)typ name: (NSString*)theName
{
	theName = [theName lowercaseString];
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [[currPic pictureType] isEqualToString: typ]
			&& [[currPic name] isEqualToString: theName] )
		{
			return [[self fileURL] URLByAppendingPathComponent: [currPic filename]];
			break;
		}
	}
	
	return nil;
}


-(QTMovie*)		movieOfType: (NSString*)typ name: (NSString*)theName
{
	theName = [theName lowercaseString];
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [[currPic pictureType] isEqualToString: typ]
			&& [[currPic name] isEqualToString: theName] )
		{
			if( ![currPic imageMovieOrCursor] )
			{
				QTMovie*	img = [[[QTMovie alloc] initWithURL: [[self fileURL] URLByAppendingPathComponent: [currPic filename]] error: nil] autorelease];
				if( !img )
					img = [[[QTMovie alloc] initWithFile: [[NSBundle mainBundle] pathForResource: [currPic filename] ofType: @""] error: nil] autorelease];
				[currPic setImageMovieOrCursor: img];
				return img;
			}
			else
				return [currPic imageMovieOrCursor];
			break;
		}
	}
	
	return nil;
}


-(QTMovie*)		movieOfType: (NSString*)typ id: (WILDObjectID)theID
{
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [currPic pictureID] == theID
			&& [[currPic pictureType] isEqualToString: typ] )
		{
			if( ![currPic imageMovieOrCursor] )
			{
				QTMovie*	img = [[[QTMovie alloc] initWithURL: [[self fileURL] URLByAppendingPathComponent: [currPic filename]] error: nil] autorelease];
				if( !img )
					img = [[[QTMovie alloc] initWithFile: [currPic filename] error: nil] autorelease];
				[currPic setImageMovieOrCursor: img];
				return img;
			}
			else
				return [currPic imageMovieOrCursor];
			break;
		}
	}
	
	return nil;
}


-(NSImage*)		pictureOfType: (NSString*)typ name: (NSString*)theName
{
	assert(![typ isEqualToString: @"cursor"]);
	assert(![typ isEqualToString: @"sound"]);
	
	theName = [theName lowercaseString];
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [[currPic pictureType] isEqualToString: typ]
			&& [[currPic name] isEqualToString: theName] )
		{
			if( ![currPic imageMovieOrCursor] )
			{
				NSImage*	img = [[[NSImage alloc] initWithContentsOfFile: [currPic filename]] autorelease];
				[currPic setImageMovieOrCursor: img];
				return img;
			}
			else
				return [currPic imageMovieOrCursor];
			break;
		}
	}
	
	return nil;
}


-(NSImage*)		pictureOfType: (NSString*)typ id: (WILDObjectID)theID
{
	assert(![typ isEqualToString: @"cursor"]);
	assert(![typ isEqualToString: @"sound"]);
	
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [currPic pictureID] == theID
			&& [[currPic pictureType] isEqualToString: typ] )
		{
			if( ![currPic imageMovieOrCursor] )
			{
				NSImage*	img = [[[NSImage alloc] initWithContentsOfFile: [currPic filename]] autorelease];
				[currPic setImageMovieOrCursor: img];
				return img;
			}
			else
				return [currPic imageMovieOrCursor];
			break;
		}
	}
	
	return nil;
}


-(NSInteger)	numberOfPictures
{
	NSInteger		numPics = 0;
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [[currPic pictureType] isEqualToString: @"icon"] )
			numPics++;
	}
	
	return numPics;
}


-(NSImage*)		pictureAtIndex: (NSInteger)idx
{
	NSInteger		numPics = 0;
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [[currPic pictureType] isEqualToString: @"icon"] )
		{
			if( numPics == idx )
			{
				if( ![currPic imageMovieOrCursor] )
				{
					NSImage*	img = [[[NSImage alloc] initWithContentsOfFile: [currPic filename]] autorelease];
					[currPic setImageMovieOrCursor: img];
					return img;
				}
				else
					return [currPic imageMovieOrCursor];
			}
			numPics++;
		}
	}
	
	return nil;
}


-(void)	infoForPictureAtIndex: (NSInteger)idx name: (NSString**)outName id: (WILDObjectID*)outID
			image: (NSImage**)outImage fileName: (NSString**)outFileName isBuiltIn: (BOOL*)isBuiltIn
{
	NSInteger		numPics = 0;
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [[currPic pictureType] isEqualToString: @"icon"] )
		{
			if( numPics == idx )
			{
				if( outImage )
				{
					if( ![currPic imageMovieOrCursor] )
					{
						*outImage = [[[NSImage alloc] initWithContentsOfFile: [currPic filename]] autorelease];
						[currPic setImageMovieOrCursor: *outImage];
					}
					else
						*outImage = [currPic imageMovieOrCursor];
				}

				if( outName )
					*outName = [currPic name];
				if( outID )
					*outID = [currPic pictureID];
				if( outFileName )
					*outFileName = [currPic filename];
				if( isBuiltIn )
					*isBuiltIn = [currPic isBuiltIn];
			}
			numPics++;
		}
	}
}



-(NSCursor*)	cursorWithName: (NSString*)theName
{
	theName = [theName lowercaseString];
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [[currPic pictureType] isEqualToString: @"cursor"]
			&& [[currPic name] isEqualToString: theName])
		{
			if( ![currPic imageMovieOrCursor] )
			{
				NSImage*	img = [[[NSImage alloc] initWithContentsOfFile: [currPic filename]] autorelease];
				NSCursor*	curs = [[[NSCursor alloc] initWithImage: img hotSpot: [currPic hotSpot]] autorelease];
				[currPic setImageMovieOrCursor: curs];
				return curs;
			}
			else
				return [currPic imageMovieOrCursor];
			break;
		}
	}
	
	if( [theName isEqualToString: @"hand"] )
		return [NSCursor pointingHandCursor];
	else
		return nil;
}


-(NSCursor*)	cursorWithID: (WILDObjectID)theID
{
	for( WILDMediaEntry* currPic in mMediaList )
	{
		if( [currPic pictureID] == theID
			&& [[currPic pictureType] isEqualToString: @"cursor"] )
		{
			if( ![currPic imageMovieOrCursor] )
			{
				NSImage*	img = [[[NSImage alloc] initWithContentsOfFile: [currPic filename]] autorelease];
				NSCursor*	curs = [[[NSCursor alloc] initWithImage: img hotSpot: [currPic hotSpot]] autorelease];
				[currPic setImageMovieOrCursor: curs];
				return curs;
			}
			else
				return [currPic imageMovieOrCursor];
			break;
		}
	}
	
	if( theID == 128 )
		return [NSCursor pointingHandCursor];
	else
		return nil;
}


-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind
{
	id<WILDVisibleObject>	foundVisibleObject = nil;
	
	for( WILDCardWindowController* currWindow in [self windowControllers] )
	{
		if( [currWindow stack] == inObjectToFind )
			foundVisibleObject = currWindow;
		else
			foundVisibleObject = [currWindow visibleObjectForWILDObject: inObjectToFind];
		
		if( foundVisibleObject )
			break;
	}
	
	return foundVisibleObject;
}


-(struct LEOContextGroup*)	scriptContextGroupObject
{
	if( !mContextGroup )
		mContextGroup = LEOContextGroupCreate();
	
	return mContextGroup;
}


-(WILDCard*)	currentCard
{
	if( [[self windowControllers] count] == 0 )
		[self makeWindowControllers];
	WILDCardWindowController*	theWC = [[self windowControllers] objectAtIndex: 0];
	return [theWC currentCard];
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@<%p> { file = %@ }", [self class], [self class], [self fileURL]];
}


+(WILDStack*)	frontStackNamed: (NSString*)stackName
{
	WILDStack	*	theStack = nil;
	WILDDocument*	frontDoc = nil;
	NSArray*		docs = [NSApp orderedDocuments];
	for( WILDDocument* currDoc in docs )
	{
		if( [currDoc isKindOfClass: [WILDDocument class]] )
		{
			frontDoc = currDoc;
			if( stackName )
				theStack = [frontDoc stackNamed: stackName];
			else
				theStack = [frontDoc mainStack];
			if( theStack )
				break;
		}
	}
	
	return theStack;
}


+(WILDStack*)	openStackNamed: (NSString*)stackName
{
	NSString*	stackFilePath = stackName;
	WILDStack*	theStack = [self frontStackNamed: stackName];
	if( !theStack )
	{
		BOOL		isFolder = NO;
		if( ![[NSFileManager defaultManager] fileExistsAtPath: stackName isDirectory: &isFolder] || !isFolder )
		{
			stackFilePath = [stackName stringByDeletingLastPathComponent];
			if( ![[NSFileManager defaultManager] fileExistsAtPath: stackFilePath isDirectory: &isFolder] || !isFolder )
			{
				stackFilePath = nil;
				for( NSString* currPath in [[WILDSearchPaths sharedSearchPaths] paths] )
				{
					NSString*	currFullPath = [currPath stringByAppendingPathComponent: stackName];
					if( [[NSFileManager defaultManager] fileExistsAtPath: currFullPath isDirectory: &isFolder] && isFolder )
						stackFilePath = currFullPath;
					if( !stackFilePath )
					{
						currFullPath = [[currPath stringByAppendingPathComponent: stackName] stringByDeletingPathExtension];
						if( [[NSFileManager defaultManager] fileExistsAtPath: currFullPath isDirectory: &isFolder] && isFolder )
							stackFilePath = currFullPath;
					}
					if( !stackFilePath )
					{
						currFullPath = [[currPath stringByAppendingPathComponent: stackName] stringByAppendingPathExtension: @"xstk"];
						if( [[NSFileManager defaultManager] fileExistsAtPath: currFullPath isDirectory: &isFolder] && isFolder )
							stackFilePath = currFullPath;
					}
					
					if( stackFilePath )
						break;
				}
				
				if( !stackFilePath )
					return nil;
			}
		}
		
		NSError			*	err = nil;
		WILDDocument	*	theDoc = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: [NSURL fileURLWithPath: stackFilePath] display: NO error: &err];
		theStack = [theDoc stackNamed: stackName];
	}
	
	return theStack;
}


+(BOOL)	autosavesInPlace
{
	return YES;
}

@end
