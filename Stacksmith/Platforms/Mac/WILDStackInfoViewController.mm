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


struct WILDStackInfoViewControllerSize
{
	NSSize		size;
	NSString*	name;
};


static WILDStackInfoViewControllerSize		sPopUpMenuSizes[] =
{
	{ {416, 240}, @"Small" },
	{ {512, 342}, @"Classic" },
	{ {640, 400}, @"PowerBook" },
	{ {640, 480}, @"Large" },
	{ {576, 720}, @"MacPaint" },
	{ {800, 600}, @"Original iMac" },
	{ {1366, 768}, @"MacBook Air 11\"" },
	{ {1440, 900}, @"MacBook Air 13\"" },
	{ {1280,720}, @"720p (HD Ready)" },
	{ {1920,1080}, @"1080p (Full HD)" },
	{ {2560,1440}, @"iMac 5K" },
	{ {3840,2160}, @"2160p (UHDTV 4K)" },
	{ {-1, -1}, @"Window" },
	{ {-2, -2}, @"Screen" },
	{ {0, 0}, @"Custom" }	// Must be last, used as terminator.
};


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
@synthesize stylePopUpButton = mStylePopUpButton;
@synthesize resizableSwitch = mResizableSwitch;

-(id)	initWithConcreteObject: (CStack*)inStack
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
	[mBackgroundCountField setStringValue: [NSString stringWithFormat: @"Contains %zu backgrounds.", numBackgrounds]];
	
	int x = 0;
	for( ; sPopUpMenuSizes[x].size.width != 0; x++ )
	{
		[mSizePopUpButton addItemWithTitle: sPopUpMenuSizes[x].name];
	}
	[mSizePopUpButton addItemWithTitle: sPopUpMenuSizes[x].name];	// We also want a "Custom" item that doubles as the list terminator.
	[self updateCardSizePopUpAndFields];
	
	[mStylePopUpButton selectItemWithTag: mStack->GetStyle()];
	
	[mIDField setIntegerValue: mStack->GetID()];
	
	[mResizableSwitch setState: mStack->IsResizable() ? NSControlStateValueOn : NSControlStateValueOff];
}


-(void)	updateCardSizePopUpAndFields
{
	NSSize		cardSize = { (CGFloat)mStack->GetCardWidth(), (CGFloat)mStack->GetCardHeight() };
	if( (cardSize.width <= 1 || cardSize.height <= 1) )
		cardSize = NSMakeSize(512, 342);
	
	BOOL		foundSomething = NO;
	for( NSUInteger x = 0; sPopUpMenuSizes[x].size.width != 0; x++ )
	{
		NSSize	currSize = sPopUpMenuSizes[x].size;
		if( currSize.width == -2 )	// "Screen".
		{
			NSWindow	*wd = self.view.window.parentWindow;
			currSize = [[wd screen] frame].size;
		}
		if( currSize.width == cardSize.width
			&& currSize.height == cardSize.height )
		{
			[mSizePopUpButton selectItemAtIndex: x];
			foundSomething = YES;
			break;
		}
	}
	
	if( !foundSomething )	// Use last item, which is "Custom".
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
	NSSize		currentSize = sPopUpMenuSizes[selectedItem].size;
	NSWindow	*wd = self.view.window.parentWindow;
	
	if( currentSize.width == -1 )	// "Window".
	{
		currentSize = [wd contentRectForFrameRect: [wd frame]].size;
		mStack->SetCardWidth( currentSize.width );
		mStack->SetCardHeight( currentSize.height );
	}
	else if( currentSize.width == -2 )	// "Screen".
	{
		currentSize = [[wd screen] frame].size;
		mStack->SetCardWidth( currentSize.width );
		mStack->SetCardHeight( currentSize.height );
	}
	else if( currentSize.width == 0 )	// "Custom".
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


-(IBAction)	stylePopUpSelectionChanged: (id)sender
{
	TStackStyle theStyle = (TStackStyle) [mStylePopUpButton selectedItem].tag;
	
	mStack->SetStyle( theStyle );
}



-(IBAction)	doApplySizeButton: (id)sender
{
	NSSize	currentSize = NSMakeSize( [mWidthField intValue], [mHeightField intValue] );
	mStack->SetCardWidth( currentSize.width );
	mStack->SetCardHeight( currentSize.height );
}


-(IBAction)	doResizableSwitchChanged: (id)sender
{
	mStack->SetResizable( mResizableSwitch.state == NSControlStateValueOn );
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == mNameField )
	{
		mStack->SetName( [mNameField stringValue].UTF8String );
	}
}

@end
