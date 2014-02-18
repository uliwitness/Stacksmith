//
//  WILDStackInfoViewController.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDStackInfoViewController.h"
#import "CStack.h"
#import "UKHelperMacros.h"
#import "NSWindow+ULIZoomEffect.h"
#import "WILDUserPropertyEditorController.h"


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


using namespace Carlson;


@implementation WILDStackInfoViewController

@synthesize nameField = mNameField;
@synthesize IDField = mIDField;
@synthesize cardCountField = mCardCountField;
@synthesize backgroundCountField = mBackgroundCountField;
@synthesize editScriptButton = mEditScriptButton;
@synthesize applySizeButton = mApplySizeButton;
@synthesize widthField = mWidthField;
@synthesize heightField = mHeightField;
@synthesize userPropertyEditButton = mUserPropertyEditButton;
@synthesize sizePopUpButton = mSizePopUpButton;
@synthesize resizableSwitch = mResizableSwitch;

-(id)	initWithStack: (CStack*)inStack
{
	if(( self = [super initWithNibName: NSStringFromClass([self class]) bundle: nil] ))
	{
		mStack = (CStack*)inStack->Retain();
	}
	
	return self;
}

-(void)	dealloc
{
	mStack->Release();
	
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
	
	[self.userPropertyEditor setPropertyContainer: mStack];
		
	[mNameField setStringValue: [NSString stringWithUTF8String: mStack->GetName().c_str()]];
	
	size_t	numCards = mStack->GetNumCards();
	[mCardCountField setStringValue: [NSString stringWithFormat: @"Contains %zu cards.", numCards]];

	size_t	numBackgrounds = mStack->GetNumBackgrounds();
	[mBackgroundCountField setStringValue: [NSString stringWithFormat: @"Contains %ld backgrounds.", numBackgrounds]];
	
	[self updateCardSizePopUpAndFields];
	
	[mResizableSwitch setState: mStack->IsResizable() ? NSOnState : NSOffState];
}


-(void)	updateCardSizePopUpAndFields
{
	NSSize		cardSize = { (CGFloat)mStack->GetCardWidth(), (CGFloat)mStack->GetCardHeight() };
	if( (cardSize.width <= 1 || cardSize.height <= 1) )
		cardSize = NSMakeSize(512, 342);
	
	BOOL		foundSomething = NO;
	for( NSUInteger x = 0; x < NUM_POPUP_MENU_SIZES; x++ )
	{
		if( sPopUpMenuSizes[x].width == cardSize.width
			&& sPopUpMenuSizes[x].height == cardSize.height )
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
	mOldCustomSize = cardSize;
	
	[mWidthField setIntValue: cardSize.width];
	[mHeightField setIntValue: cardSize.height];
}


-(IBAction)	doEditScriptButton: (id)sender
{
	mStack->OpenScriptEditorAndShowLine( SIZE_T_MAX );
}


-(IBAction)	sizePopUpSelectionChanged: (id)sender
{
	NSInteger	selectedItem = [mSizePopUpButton indexOfSelectedItem];
	BOOL		shouldEnableFields = NO;
	NSSize		currentSize = sPopUpMenuSizes[selectedItem];
	NSWindow	*wd = self.view.window.parentWindow;
	
	if( currentSize.width == -1 )
	{
		currentSize = [wd contentRectForFrameRect: [wd frame]].size;
		mStack->SetCardWidth( currentSize.width );
		mStack->SetCardHeight( currentSize.height );
	}
	else if( currentSize.width == -2 )
	{
		currentSize = [[wd screen] frame].size;
		mStack->SetCardWidth( currentSize.width );
		mStack->SetCardHeight( currentSize.height );
	}
	else if( currentSize.width == 0 )
	{
		currentSize = NSMakeSize( mOldCustomSize.width, mOldCustomSize.height );
		shouldEnableFields = YES;
	}
	else
	{
		mStack->SetCardWidth( currentSize.width );
		mStack->SetCardHeight( currentSize.height );
	}
	
	[mWidthField setIntValue: currentSize.width];
	[mHeightField setIntValue: currentSize.height];
	
	[mApplySizeButton setEnabled: shouldEnableFields];
	[mWidthField setEnabled: shouldEnableFields];
	[mHeightField setEnabled: shouldEnableFields];
}


-(IBAction)	doApplySizeButton: (id)sender
{
	NSSize	currentSize = NSMakeSize( [mWidthField intValue], [mHeightField intValue] );
	mStack->SetCardWidth( currentSize.width );
	mStack->SetCardHeight( currentSize.height );
}


-(IBAction)	doResizableSwitchChanged: (id)sender
{
	mStack->SetResizable( mResizableSwitch.state == NSOnState );
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == mNameField )
	{
		mStack->SetName( [mNameField stringValue].UTF8String );
	}
}

@end
