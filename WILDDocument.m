//
//  WILDDocument.m
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDCard.h"
#import "WILDXMLUtils.h"
#import "WILDCardViewController.h"
#import "WILDCardView.h"
#import "NSFileHandle+UKReadLinewise.h"
#import "UKProgressPanelController.h"
#import "NSView+SizeWindowForViewSize.h"
#import "AGIconFamily.h"
#import "WILDStyleEntry.h"
#import "WILDMediaEntry.h"
#import "UKRandomInteger.h"
#import "WILDCardWindowController.h"
#import <Quartz/Quartz.h>


@implementation WILDDocument

- (id)init
{
    self = [super init];
    if( self )
	{
		mFontIDTable = [[NSMutableDictionary alloc] init];
		mTextStyles = [[NSMutableDictionary alloc] init];
		mMediaList = [[NSMutableArray alloc] init];
		mStacks = [[NSMutableArray alloc] init];
		[mStacks addObject: [[[WILDStack alloc] initWithDocument: self] autorelease]];
    }
    return self;
}


-(void)	dealloc
{
	DESTROY(mErrorsAndWarnings);
	DESTROY(mFontIDTable);
	DESTROY(mTextStyles);
	DESTROY(mMediaList);
	DESTROY(mStacks);
	
	[super dealloc];
}


-(void)	makeWindowControllers
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


-(void)	fileHandle: (NSFileHandle*)fh ofImporterDidReadLine: (NSString*)currLine
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


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSURL*		tocURL = absoluteURL;
	NSString*	folderPath = nil;
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
	}
	
	tocURL = [absoluteURL URLByAppendingPathComponent: @"toc.xml"];
	folderPath = [absoluteURL path];
	
	NSXMLDocument*	xmlDoc = [[[NSXMLDocument alloc] initWithContentsOfURL: tocURL
														options: 0 error: outError] autorelease];
	if( *outError )
	{
		NSLog( @"%@", *outError );
		return NO;
	}
	
	NSXMLElement	*	stackfileElement = [xmlDoc rootElement];
	
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
	
	// Load built-in standard picture table so others can access it: (ICONs, PICTs, CURSs and SNDs)
	NSXMLDocument	*	stdDoc = [[[NSXMLDocument alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"resources" ofType: @"xml"]]
														options: 0 error: outError] autorelease];
	NSXMLElement	*	stdStackfileElement = [stdDoc rootElement];
	pictures = [stdStackfileElement elementsForName: @"media"];
	for( NSXMLElement* thePic in pictures )
	{
		NSString	*	iconID = [[[thePic elementsForName: @"id"] objectAtIndex: 0] stringValue];
		NSString	*	iconName = [[[thePic elementsForName: @"name"] objectAtIndex: 0] stringValue];
		NSString	*	fileName = [[[thePic elementsForName: @"file"] objectAtIndex: 0] stringValue];
		NSString	*	type = [[[thePic elementsForName: @"type"] objectAtIndex: 0] stringValue];
		NSPoint			pos = WILDPointFromSubElementInElement( @"hotspot", thePic );
		[self addMediaFile: fileName withType: type name: iconName andID: [iconID integerValue] hotSpot: pos
			imageOrCursor: nil];
	}
	
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
			imageOrCursor: nil];
	}
	
	// Create a stack root object:
	NSArray			*	stacks = [stackfileElement elementsForName: @"stack"];
	[mStacks removeAllObjects];
	
	for( NSXMLElement* currStackElem in stacks )
	{
		NSXMLNode	*	theFileAttr = [currStackElem attributeForName: @"file"];
		NSString	*	theFileName = [theFileAttr stringValue];
		NSURL		*	theFileURL = [absoluteURL URLByAppendingPathComponent: theFileName];
		NSXMLDocument*	theDoc = [[NSXMLDocument alloc] initWithContentsOfURL: theFileURL options: 0
									error: outError];
		
		WILDStack*	currStack = [[WILDStack alloc] initWithXMLDocument: theDoc
											document: self];
		[mStacks addObject: currStack];
		[theDoc release];
		[currStack release];
	}
	
	return YES;
}


//-(void)	generatePreview
//{
//	@try
//	{
//		NSImage*		cardSnapshot = nil;
//		NSRect			theBox = [mView bounds];
//		
//		cardSnapshot = [[[NSImage alloc] initWithSize: theBox.size] autorelease];
//		[cardSnapshot lockFocus];
//			[[mView layer] renderInContext: [[NSGraphicsContext currentContext] graphicsPort]];
//		[cardSnapshot unlockFocus];
//		
//		NSImage*			stackIcon = [NSImage imageNamed: @"Stack"];
//		CGDataProviderRef	fileProvider = CGDataProviderCreateWithURL( (CFURLRef) [[NSBundle mainBundle] URLForResource: @"Stack-Mask" withExtension: @"png"] );
//		[(id)fileProvider autorelease];
//		CGImageRef			maskImage = CGImageCreateWithPNGDataProvider( fileProvider, NULL, false, kCGRenderingIntentDefault );
//		[(id)maskImage autorelease];
//		NSRect				iconBox = NSZeroRect;
//		iconBox.size = [stackIcon size];
//		NSImage*			thumbImg = [[[NSImage alloc] initWithSize: iconBox.size] autorelease];
//		[thumbImg lockFocus];
//			[stackIcon drawInRect: iconBox fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1.0];
//
//			// Fit the snapshot into rect of first card of icon:
//			NSRect				possibleThumbBox = NSMakeRect( 36, 60, iconBox.size.width -72, iconBox.size.height -34 -160 );
//			NSRect				thumbBox = theBox;
//			thumbBox.size.width = possibleThumbBox.size.width;
//			thumbBox.size.height = thumbBox.size.height / (theBox.size.width / possibleThumbBox.size.width);
//			if( thumbBox.size.height > possibleThumbBox.size.height )
//			{
//				thumbBox.size.height = possibleThumbBox.size.height;
//				thumbBox.size.width = thumbBox.size.width / (theBox.size.height / possibleThumbBox.size.height);
//			}
//			
//			// Center in possible thumb box
//			thumbBox.origin.x = possibleThumbBox.origin.x +truncf((possibleThumbBox.size.width -thumbBox.size.width) /2);
//			thumbBox.origin.y = possibleThumbBox.origin.y +truncf((possibleThumbBox.size.height -thumbBox.size.height) /2);
//			
//			CGContextRef	theCtx = [[NSGraphicsContext currentContext] graphicsPort];
//			CGContextSetBlendMode( theCtx, kCGBlendModeDarken );
//			CGContextSetAlpha( theCtx, 0.8 );
//			CGContextDrawImage( theCtx, NSRectToCGRect( thumbBox ), [cardSnapshot CGImageForProposedRect: NULL context: nil hints: nil] );
//		[thumbImg unlockFocus];
//		
//		[[cardSnapshot TIFFRepresentation] writeToURL: [[self fileURL] URLByAppendingPathComponent: @"preview.tiff"] atomically: YES];
//		
//		AGIconFamily*	theIcon = [AGIconFamily iconFamilyWithThumbnailsOfImage: thumbImg
//									imageInterpolation: NSImageInterpolationMedium];
//		[theIcon setAsCustomIconForURL: [self fileURL]];
//		[[thumbImg TIFFRepresentation] writeToURL: [[self fileURL] URLByAppendingPathComponent: @"thumbnail.tiff"] atomically: YES];
//	}
//	@catch( NSException * e )
//	{
//		NSLog( @"%@", e );
//	}
//}

-(void)		addFont: (NSString*)fontName withID: (NSInteger)fontID
{
	[mFontIDTable setObject: fontName forKey: [NSNumber numberWithInteger: fontID]];
}


-(NSString*)	fontNameForID: (NSInteger)fontID
{
	return [mFontIDTable objectForKey: [NSNumber numberWithInteger: fontID]];
}


-(void)		addStyleFormatWithID: (NSInteger)styleID forFontName: (NSString*)fontName size: (NSInteger)fontSize styles: (NSArray*)fontStyles
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


-(NSInteger)	uniqueIDForMedia
{
	NSInteger	mediaID = UKRandomInteger();
	BOOL		notUnique = YES;
	
	while( notUnique )
	{
		notUnique = NO;
		
		for( WILDMediaEntry* currPict in mMediaList )
		{
			if( [currPict pictureID] == mediaID )
			{
				notUnique = YES;
				mediaID = UKRandomInteger();
				break;
			}
		}
	}
	
	return mediaID;
}


-(NSString*)	URLForImageNamed: (NSString*)theName
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
			name: (NSString*)iconName andID: (NSInteger)iconID hotSpot: (NSPoint)pos
			imageOrCursor: (id)imgOrCursor
{
	NSURL*				fileURL = [self URLForImageNamed: fileName];
	WILDMediaEntry*	pentry = [[[WILDMediaEntry alloc] initWithFilename: [fileURL path]
																withType: type name: iconName andID: iconID hotSpot: pos] autorelease];
	if( imgOrCursor )
		[pentry setImageMovieOrCursor: imgOrCursor];
	[mMediaList addObject: pentry];
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


-(QTMovie*)		movieOfType: (NSString*)typ id: (NSInteger)theID
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


-(NSImage*)		pictureOfType: (NSString*)typ id: (NSInteger)theID
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


-(void)	infoForPictureAtIndex: (NSInteger)idx name: (NSString**)outName id: (NSInteger*)outID
			image: (NSImage**)outImage fileName: (NSString**)outFileName
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


-(NSCursor*)	cursorWithID: (NSInteger)theID
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

@end
