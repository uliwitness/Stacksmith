//
//  WILDStackInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDStackInfoViewController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardView.h"
#import "WILDStack.h"
#import "UKHelperMacros.h"
#import "NSWindow+ULIZoomEffect.h"
#import "WILDNotifications.h"


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


@implementation WILDStackInfoViewController

@synthesize cardView = mCardView;
@synthesize stack = mStack;

@synthesize nameField = mNameField;
@synthesize IDField = mIDField;
@synthesize cardCountField = mCardCountField;
@synthesize backgroundCountField = mBackgroundCountField;
@synthesize editScriptButton = mEditScriptButton;
@synthesize applySizeButton = mApplySizeButton;
@synthesize widthField = mWidthField;
@synthesize heightField = mHeightField;

@synthesize sizePopUpButton = mSizePopUpButton;

-(id)	initWithStack: (WILDStack*)inStack ofCardView: (WILDCardView*)owningView
{
	if(( self = [super initWithNibName: NSStringFromClass([self class]) bundle: nil] ))
	{
		mStack = [inStack retain];
		mCardView = [owningView retain];
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


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	[mNameField setStringValue: [mStack name]];
	if( [[mStack document] fileURL] == nil )
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
	for( NSUInteger x = 0; x < NUM_POPUP_MENU_SIZES; x++ )
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
	{
		[mSizePopUpButton selectItemAtIndex: [mSizePopUpButton numberOfItems] -1];
		[mWidthField setEnabled: YES];
		[mHeightField setEnabled: YES];
		[mApplySizeButton setEnabled: YES];
	}
	else
	{
		[mWidthField setEnabled: NO];
		[mHeightField setEnabled: NO];
		[mApplySizeButton setEnabled: NO];
	}
	
	[mWidthField setIntValue: cardSize.width];
	[mHeightField setIntValue: cardSize.height];
}


//-(IBAction)	doOKButton: (id)sender
//{
//	if( [[mStack document] fileURL] == nil )
//		[mStack setName: [mNameField stringValue]];
//	
//	NSSize	newSize = NSMakeSize( [mWidthField intValue], [mHeightField intValue] );
//	[mStack setCardSize: newSize];
//	
//	[mStack updateChangeCount: NSChangeDone];
//
//	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mStack] frameInScreenCoordinates];
//	[[self window] orderOutWithZoomEffectToRect: destRect];
//	[self close];
//}
//
//
//-(IBAction)	doCancelButton: (id)sender
//{
//	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mStack] frameInScreenCoordinates];
//	[[self window] orderOutWithZoomEffectToRect: destRect];
//	[self close];
//}


-(IBAction)	doEditScriptButton: (id)sender
{
	NSRect		box = [mEditScriptButton convertRect: [mEditScriptButton bounds] toView: nil];
	NSRect		wFrame = [[self.view window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDScriptEditorWindowController*	se = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mStack] autorelease];
	[se setGlobalStartRect: box];
	[[mStack document] addWindowController: se];
	[se showWindow: self];
}


-(IBAction)	sizePopUpSelectionChanged: (id)sender
{
	NSInteger	selectedItem = [mSizePopUpButton indexOfSelectedItem];
	BOOL		shouldEnableFields = (selectedItem == ([mSizePopUpButton numberOfItems] -1));
	
	[mWidthField setEnabled: shouldEnableFields];
	[mHeightField setEnabled: shouldEnableFields];
	
	NSSize		currentSize = sPopUpMenuSizes[selectedItem];
	
	if( currentSize.width == -1 )
	{
		currentSize = [[mCardView window] contentRectForFrameRect: [[mCardView window] frame]].size;
		[mWidthField setIntValue: currentSize.width];
		[mHeightField setIntValue: currentSize.height];
		[mStack setCardSize: currentSize];
	}
	else if( currentSize.width == -2 )
	{
		currentSize = [[[mCardView window] screen] frame].size;
		[mWidthField setIntValue: currentSize.width];
		[mHeightField setIntValue: currentSize.height];
		[mStack setCardSize: currentSize];
	}
	else if( currentSize.width == 0 )
	{
		currentSize = NSMakeSize( [mWidthField intValue], [mHeightField intValue] );
		[mStack setCardSize: currentSize];
	}
	else
	{
		[mWidthField setIntValue: currentSize.width];
		[mHeightField setIntValue: currentSize.height];
	}
}


-(IBAction)	doApplySizeButton: (id)sender
{
	NSSize	currentSize = NSMakeSize( [mWidthField intValue], [mHeightField intValue] );
	[mStack setCardSize: currentSize];
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == mNameField )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDStackWillChangeNotification object: mStack userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(name), WILDAffectedPropertyKey,
										nil]];

		[mStack setName: [mNameField stringValue]];
			
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDStackWillChangeNotification object: mStack userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(name), WILDAffectedPropertyKey,
										nil]];
		[mStack updateChangeCount: NSChangeDone];
	}
}

@end
