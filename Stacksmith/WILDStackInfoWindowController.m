//
//  WILDStackInfoWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDStackInfoWindowController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardView.h"
#import "WILDStack.h"
#import "UKHelperMacros.h"


static NSSize		sPopUpMenuSizes[] =
{
	{ 416, 240 },
	{ 512, 342 },
	{ 640, 400 },
	{ 640, 480 },
	{ 576, 720 },
	{ -1, -1 },
	{ -2, -2 },
	{ 0, 0 }
};
#define NUM_POPUP_MENU_SIZES	(sizeof(sPopUpMenuSizes) / sizeof(NSSize))


@implementation WILDStackInfoWindowController

@synthesize cardView = mCardView;
@synthesize stack = mStack;

@synthesize nameField = mNameField;
@synthesize IDField = mIDField;
@synthesize cardCountField = mCardCountField;
@synthesize backgroundCountField = mBackgroundCountField;
@synthesize editScriptButton = mEditScriptButton;
@synthesize widthField = mWidthField;
@synthesize heightField = mHeightField;

@synthesize sizePopUpButton = mSizePopUpButton;

-(id)	initWithStack: (WILDStack*)inStack ofCardView: (WILDCardView*)owningView
{
	if(( self = [super initWithWindowNibName: NSStringFromClass([self class])] ))
	{
		mStack = [inStack retain];
		mCardView = [owningView retain];
		
		[self setShouldCascadeWindows: NO];
	}
	
	return self;
}

-(void)	dealloc
{
	DESTROY_DEALLOC( mCardView );
	DESTROY_DEALLOC( mStack );
	
	DESTROY_DEALLOC( mEditScriptButton );
	DESTROY_DEALLOC( mNameField );
	DESTROY_DEALLOC( mIDField );
	DESTROY_DEALLOC( mCardCountField );
	DESTROY_DEALLOC( mBackgroundCountField );
	DESTROY_DEALLOC( mWidthField );
	DESTROY_DEALLOC( mHeightField );
	
	DESTROY_DEALLOC(mSizePopUpButton);
	
	[super dealloc];
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	[mNameField setStringValue: [mStack name]];
	if( [[mStack document] fileName] == nil )
		[mNameField setEnabled: NO];
	
	unsigned long	numCards = [[mStack cards] count];
	[mCardCountField setStringValue: [NSString stringWithFormat: @"Contains %ld cards.", numCards]];

	unsigned long	numBackgrounds = [[mStack backgrounds] count];
	[mBackgroundCountField setStringValue: [NSString stringWithFormat: @"Contains %ld backgrounds.", numBackgrounds]];
	
	[self updateCardSizePopUpAndFields];
}


-(void)	updateCardSizePopUpAndFields
{
	NSSize		cardSize = [mStack cardSize];
	if( (cardSize.width <= 1 || cardSize.height <= 1) )
		cardSize = NSMakeSize(512, 342);
	
	BOOL		foundSomething = NO;
	for( int x = 0; x < NUM_POPUP_MENU_SIZES; x++ )
	{
		if( sPopUpMenuSizes[x].width == cardSize.width
			|| sPopUpMenuSizes[x].height == cardSize.height )
		{
			[mSizePopUpButton selectItemAtIndex: x];
			foundSomething = YES;
			break;
		}
	}
	
	if( !foundSomething )
		[mSizePopUpButton selectItemAtIndex: [mSizePopUpButton numberOfItems] -1];
	else
	{
		[mWidthField setEnabled: NO];
		[mHeightField setEnabled: NO];
	}
	
	[mWidthField setIntValue: cardSize.width];
	[mHeightField setIntValue: cardSize.height];
}


-(IBAction)	showWindow: (id)sender
{
	NSRect	sourceRect = [[mCardView visibleObjectForWILDObject: mStack] frameInScreenCoordinates];
	
	[[self window] makeKeyAndOrderFrontWithZoomEffectFromRect: sourceRect];
}


-(IBAction)	doOKButton: (id)sender
{
	if( [[mStack document] fileName] == nil )
		[mStack setName: [mNameField stringValue]];
	
	NSSize	newSize = NSMakeSize( [mWidthField intValue], [mHeightField intValue] );
	[mStack setCardSize: newSize];
	
	[mStack updateChangeCount: NSChangeDone];

	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mStack] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doCancelButton: (id)sender
{
	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mStack] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doEditScriptButton: (id)sender
{
	NSRect		box = [mEditScriptButton convertRect: [mEditScriptButton bounds] toView: nil];
	NSRect		wFrame = [[self window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDScriptEditorWindowController*	se = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mStack] autorelease];
	[se setGlobalStartRect: box];
	[[[[self window] windowController] document] addWindowController: se];
	[se showWindow: self];
}


-(IBAction)	sizePopUpSelectionChanged: (id)sender
{
	NSUInteger	selectedItem = [mSizePopUpButton indexOfSelectedItem];
	BOOL		shouldEnableFields = (selectedItem == ([mSizePopUpButton numberOfItems] -1));
	
	[mWidthField setEnabled: shouldEnableFields];
	[mHeightField setEnabled: shouldEnableFields];
	
	NSSize		currentSize = sPopUpMenuSizes[selectedItem];
	
	if( currentSize.width == -1 )
	{
		currentSize = [[mCardView window] contentRectForFrameRect: [[mCardView window] frame]].size;
		[mWidthField setIntValue: currentSize.width];
		[mHeightField setIntValue: currentSize.height];
	}
	else if( currentSize.width == -2 )
	{
		currentSize = [[[mCardView window] screen] frame].size;
		[mWidthField setIntValue: currentSize.width];
		[mHeightField setIntValue: currentSize.height];
	}
	else if( currentSize.width == 0 )
	{
		currentSize = NSMakeSize( [mWidthField intValue], [mHeightField intValue] );
	}
	else
	{
		[mWidthField setIntValue: currentSize.width];
		[mHeightField setIntValue: currentSize.height];
	}
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%@ Info", [mStack displayName]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@ Info", [mStack displayName]]
											action: nil keyEquivalent: @"" atIndex: 0];
	[newItem setImage: [mStack displayIcon]];
	
	return YES;
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	NSButton*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	[btn setImage: [mStack displayIcon]];
}

@end
