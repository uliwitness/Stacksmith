//
//  UKPropagandaDocument.m
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaDocument.h"
#import "UKPropagandaStack.h"
#import "UKPropagandaCard.h"
#import "UKPropagandaXMLUtils.h"
#import "UKPropagandaCardViewController.h"
#import "UKPropagandaWindowBodyView.h"
#import "NSFileHandle+UKReadLinewise.h"
#import "UKProgressPanelController.h"
#import "NSView+SizeWindowForViewSize.h"
#import "AGIconFamily.h"
#import <Quartz/Quartz.h>


@implementation UKPropagandaDocument

- (id)init
{
    self = [super init];
    if (self)
	{
		
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
}


-(void)	dealloc
{
	[mCardViewController release];
	mCardViewController = nil;
	
	[mStack release];
	mStack = nil;
	
	[mErrorsAndWarnings release];
	mErrorsAndWarnings = nil;
	
	[super dealloc];
}


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"UKPropagandaDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib: aController];

	// Make sure window fits the cards:
	NSSize		cardSize = [mStack cardSize];
	if( cardSize.width == 0 || cardSize.height == 0 )
		cardSize = NSMakeSize( 512, 342 );
	[mView sizeWindowForViewSize: cardSize];
	
	[aController setShouldCloseDocument: YES];
	
	mCardViewController = [[UKPropagandaCardViewController alloc] init];
	[mCardViewController setView: mView];
	[mCardViewController loadCard: [[mStack cards] objectAtIndex: 0]];
	
	if( [self fileURL] )
	{
		NSString*	iconPath = [[[self fileURL] path] stringByAppendingPathComponent: @"Icon\r"];
		if( ![[NSFileManager defaultManager] fileExistsAtPath: iconPath] )
			[self performSelector: @selector(generatePreview) withObject: nil afterDelay: 0.0];
	}
}


-(void)	fileHandle: (NSFileHandle*)fh ofImporterDidReadLine: (NSString*)currLine
{
	[[UKProgressPanelController sharedProgressController] setStringValue: currLine];
}


-(void)	fileHandle: (NSFileHandle*)fh ofImporterDidReadErrorLine: (NSString*)currLine
{
	[[UKProgressPanelController sharedProgressController] setStringValue: currLine];
	[mErrorsAndWarnings addObject: currLine];
	NSLog( @"%@", currLine );
}


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSURL*		tocURL = absoluteURL;
	NSString*	folderPath = nil;
	BOOL		isDir = NO;
	if( [[NSFileManager defaultManager] fileExistsAtPath: [absoluteURL path] isDirectory: &isDir] && !isDir )
	{
		[mErrorsAndWarnings release];
		mErrorsAndWarnings = nil;
		mErrorsAndWarnings = [[NSMutableArray alloc] init];
		
		[[UKProgressPanelController sharedProgressController] setIndeterminate: YES];
		[[UKProgressPanelController sharedProgressController] setStringValue: @"Converting HyperCard Stack..."];
		[[UKProgressPanelController sharedProgressController] show];
		
		NSTask*	converterTask = [[[NSTask alloc] init] autorelease];
		[converterTask setLaunchPath: [[NSBundle mainBundle] pathForResource: @"stackimport" ofType: @""]];
		[converterTask setArguments: [NSArray arrayWithObject: [absoluteURL path]]];
		[[converterTask standardError] readLinesToEndOfFileNotifyingTarget: self newLineSelector: @selector(fileHandle:ofImporterDidReadErrorLine:)];
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
	
	// Create a stack root object:
	NSXMLElement	*	stackfileElement = [xmlDoc rootElement];
	NSXMLElement	*	stackElement = [[stackfileElement elementsForName: @"stack"] objectAtIndex: 0];
	
	[mStack release];
	mStack = [[UKPropagandaStack alloc] initWithXMLElement: stackElement
								path: folderPath];
	
	// Load font table so others can access it:
	NSArray			*	fonts = [stackfileElement elementsForName: @"font"];
	for( NSXMLElement* theFontElem in fonts )
	{
		NSString	*	fontID = [[[theFontElem elementsForName: @"id"] objectAtIndex: 0] stringValue];
		NSString	*	fontName = [[[theFontElem elementsForName: @"name"] objectAtIndex: 0] stringValue];
		[mStack addFont: fontName withID: [fontID integerValue]];
	}
	
	// Load style table so others can access it:
	NSArray			*	pictures = [stackfileElement elementsForName: @"styleentry"];
	for( NSXMLElement* thePic in pictures )
	{
		NSArray		*	fontElems = [thePic elementsForName: @"font"];
		NSString	*	fontID = ([fontElems count] > 0) ? [[fontElems objectAtIndex: 0] stringValue] : nil;
		NSArray		*	textStyles = UKPropagandaStringsFromSubElementInElement( @"textStyle",thePic);
		NSArray		*	sizeElems = [thePic elementsForName: @"size"];
		NSString	*	fontSize = ([sizeElems count] > 0) ? [[sizeElems objectAtIndex: 0] stringValue] : nil;
		[mStack addStyleFormatForFontID: fontID ? [fontID intValue] : -1
								   size: fontSize ? [fontSize intValue] : -1
								   styles: textStyles];
	}
	
	// Load standard picture table so others can access it: (ICONs, PICTs, CURSs and SNDs)
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
		NSPoint			pos = UKPropagandaPointFromSubElementInElement( @"hotspot", thePic );
		[mStack addMediaFile: fileName withType: type name: iconName andID: [iconID integerValue] hotSpot: pos];
	}
	
	// Load media table so others can access it: (ICONs, PICTs, CURSs and SNDs)
	pictures = [stackfileElement elementsForName: @"media"];
	for( NSXMLElement* thePic in pictures )
	{
		NSString	*	iconID = [[[thePic elementsForName: @"id"] objectAtIndex: 0] stringValue];
		NSString	*	iconName = [[[thePic elementsForName: @"name"] objectAtIndex: 0] stringValue];
		NSString	*	fileName = [[[thePic elementsForName: @"file"] objectAtIndex: 0] stringValue];
		NSString	*	type = [[[thePic elementsForName: @"type"] objectAtIndex: 0] stringValue];
		NSPoint			pos = UKPropagandaPointFromSubElementInElement( @"hotspot", thePic );
		[mStack addMediaFile: fileName withType: type name: iconName andID: [iconID integerValue] hotSpot: pos];
	}
		
	//NSLog( @"%@", mStack );
	
	// Load backgrounds:
	NSArray			*	backgrounds = [stackfileElement elementsForName: @"background"];
	for( NSXMLElement* theBgElem in backgrounds )
	{
		[mStack addBackground: [[[UKPropagandaBackground alloc] initWithXMLElement: theBgElem forStack: mStack] autorelease]];
	}
	
	// Load AddColor background elements:
	backgrounds = [stackfileElement elementsForName: @"addcolorbackground"];
	for( NSXMLElement* theBkgdElem in backgrounds )
	{
		NSString				*	bkgdID = [[[theBkgdElem elementsForName: @"id"] objectAtIndex: 0] stringValue];
		UKPropagandaBackground	*	bkgd = [mStack backgroundWithID: [bkgdID integerValue]];
		
		[bkgd loadAddColorObjects: theBkgdElem];
	}
	
	// Load cards:
	NSArray			*	cards = [stackfileElement elementsForName: @"card"];
	for( NSXMLElement* theCardElem in cards )
	{
		[mStack addCard: [[[UKPropagandaCard alloc] initWithXMLElement: theCardElem forStack: mStack] autorelease]];
	}

	// Load AddColor card elements:
	cards = [stackfileElement elementsForName: @"addcolorcard"];
	for( NSXMLElement* theCardElem in cards )
	{
		NSString			*	cardID = [[[theCardElem elementsForName: @"id"] objectAtIndex: 0] stringValue];
		UKPropagandaCard	*	card = [mStack cardWithID: [cardID integerValue]];
		
		[card loadAddColorObjects: theCardElem];
	}
	
	// Build a list of all page tables in the stack:
	NSMutableDictionary	*	pageTables = [NSMutableDictionary dictionary];
	NSArray				*	ptElems = [stackfileElement elementsForName: @"pagetable"];
	
	for( NSXMLElement* ptElem in ptElems )
	{
		NSInteger		theTableID = UKPropagandaIntegerFromSubElementInElement( @"id", ptElem );
		NSArray		*	cardsElems = [ptElem elementsForName: @"cards"];
		NSXMLElement* 	ptCardsElem = (cardsElems && [cardsElems count] > 0) ? [cardsElems objectAtIndex: 0] : nil;
		NSArray		*	orderedCardIDs = UKPropagandaIntegersFromSubElementInElement( @"cardID", ptCardsElem );
		[pageTables setObject: orderedCardIDs forKey: [NSNumber numberWithInteger: theTableID]];
	}
	
	// Now go through them *in order* and build an ordered list of cards:
	NSArray		*	ptlElems = [stackfileElement elementsForName: @"pagetablelist"];
	NSXMLElement* 	ptlElem = (ptlElems && [ptlElems count] > 0) ? [ptlElems objectAtIndex: 0] : nil;
	NSArray		*	pagetableIDs = UKPropagandaIntegersFromSubElementInElement( @"pagetable", ptlElem );
	NSMutableArray*	orderedCards = [NSMutableArray array];
	
	for( NSNumber* currPagetableID in pagetableIDs )
	{
		NSArray*	orderedCardIDs = [pageTables objectForKey: currPagetableID];
		for( NSNumber* currCardID in orderedCardIDs )
		{
			UKPropagandaCard*	theCard = [mStack cardWithID: [currCardID integerValue]];
			if( theCard )
				[orderedCards addObject: theCard];
		}
	}
	
	// Actually re-order cards:
	if( [orderedCards count] == [[mStack cards] count] )
		[mStack setCards: orderedCards];
	
	// Make sure window fits the cards:
	NSSize		cardSize = [mStack cardSize];
	if( cardSize.width == 0 || cardSize.height == 0 )
		cardSize = NSMakeSize( 512, 342 );
	[mView sizeWindowForViewSize: cardSize];
	
	[mCardViewController loadCard: [[mStack cards] objectAtIndex: 0]];
		
	if( [self fileURL] )
	{
		NSString*	iconPath = [[[self fileURL] path] stringByAppendingPathComponent: @"Icon\r"];
		if( ![[NSFileManager defaultManager] fileExistsAtPath: iconPath] )
			[self performSelector: @selector(generatePreview) withObject: nil afterDelay: 0.0];
	}

	return YES;
}


-(void)	generatePreview
{
	@try
	{
		NSImage*		cardSnapshot = nil;
		NSRect			theBox = [mView bounds];
		
		cardSnapshot = [[[NSImage alloc] initWithSize: theBox.size] autorelease];
		[cardSnapshot lockFocus];
			[[mView layer] renderInContext: [[NSGraphicsContext currentContext] graphicsPort]];
		[cardSnapshot unlockFocus];
		
		NSImage*			stackIcon = [NSImage imageNamed: @"Stack"];
		CGDataProviderRef	fileProvider = CGDataProviderCreateWithURL( (CFURLRef) [[NSBundle mainBundle] URLForResource: @"Stack-Mask" withExtension: @"png"] );
		[(id)fileProvider autorelease];
		CGImageRef			maskImage = CGImageCreateWithPNGDataProvider( fileProvider, NULL, false, kCGRenderingIntentDefault );
		[(id)maskImage autorelease];
		NSRect				iconBox = NSZeroRect;
		iconBox.size = [stackIcon size];
		NSImage*			thumbImg = [[[NSImage alloc] initWithSize: iconBox.size] autorelease];
		[thumbImg lockFocus];
			[stackIcon drawInRect: iconBox fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1.0];

			// Fit the snapshot into rect of first card of icon:
			NSRect				possibleThumbBox = NSMakeRect( 36, 60, iconBox.size.width -72, iconBox.size.height -34 -160 );
			NSRect				thumbBox = theBox;
			thumbBox.size.width = possibleThumbBox.size.width;
			thumbBox.size.height = thumbBox.size.height / (theBox.size.width / possibleThumbBox.size.width);
			if( thumbBox.size.height > possibleThumbBox.size.height )
			{
				thumbBox.size.height = possibleThumbBox.size.height;
				thumbBox.size.width = thumbBox.size.width / (theBox.size.height / possibleThumbBox.size.height);
			}
			
			// Center in possible thumb box
			thumbBox.origin.x = possibleThumbBox.origin.x +truncf((possibleThumbBox.size.width -thumbBox.size.width) /2);
			thumbBox.origin.y = possibleThumbBox.origin.y +truncf((possibleThumbBox.size.height -thumbBox.size.height) /2);
			
			CGContextRef	theCtx = [[NSGraphicsContext currentContext] graphicsPort];
			CGContextSetBlendMode( theCtx, kCGBlendModeDarken );
			CGContextSetAlpha( theCtx, 0.8 );
			CGContextDrawImage( theCtx, NSRectToCGRect( thumbBox ), [cardSnapshot CGImageForProposedRect: NULL context: nil hints: nil] );
		[thumbImg unlockFocus];
		
		[[cardSnapshot TIFFRepresentation] writeToURL: [[self fileURL] URLByAppendingPathComponent: @"preview.tiff"] atomically: YES];
		
		AGIconFamily*	theIcon = [AGIconFamily iconFamilyWithThumbnailsOfImage: thumbImg
									imageInterpolation: NSImageInterpolationMedium];
		[theIcon setAsCustomIconForURL: [self fileURL]];
		[[thumbImg TIFFRepresentation] writeToURL: [[self fileURL] URLByAppendingPathComponent: @"thumbnail.tiff"] atomically: YES];
	}
	@catch( NSException * e )
	{
		NSLog( @"%@", e );
	}
}

@end
