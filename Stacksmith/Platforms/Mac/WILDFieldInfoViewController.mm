//
//  WILDFieldInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDFieldInfoViewController.h"
#import "WILDMediaPickerViewController.h"
#import "UKHelperMacros.h"
#import "CFieldPart.h"


using namespace Carlson;


static 	NSArray*	sStylesInMenuOrder = nil;


@implementation WILDFieldInfoViewController

@synthesize stylePopUp = mStylePopUp;
@synthesize lockTextSwitch = mLockTextSwitch;
@synthesize autoSelectSwitch = mAutoSelectSwitch;
@synthesize multipleLinesSwitch = mMultipleLinesSwitch;
@synthesize sharedTextSwitch = mSharedTextSwitch;
@synthesize dontWrapSwitch = mDontWrapSwitch;
@synthesize dontSearchSwitch = mDontSearchSwitch;
@synthesize horizontalScrollerSwitch = mHorizontalScrollerSwitch;
@synthesize verticalScrollerSwitch = mVerticalScrollerSwitch;

-(void)	dealloc
{
	DESTROY_DEALLOC(mStylePopUp);
	DESTROY_DEALLOC(mLockTextSwitch);
	DESTROY_DEALLOC(mAutoSelectSwitch);
	DESTROY_DEALLOC(mMultipleLinesSwitch);
	DESTROY_DEALLOC(mSharedTextSwitch);
	DESTROY_DEALLOC(mDontWrapSwitch);
	DESTROY_DEALLOC(mDontSearchSwitch);
	DESTROY_DEALLOC(mHorizontalScrollerSwitch);
	DESTROY_DEALLOC(mVerticalScrollerSwitch);
	
	[super dealloc];
}


-(void)	loadView
{
	[super loadView];
	
	if( !sStylesInMenuOrder )
		sStylesInMenuOrder = [@[@(EFieldStyleRectangle),
								@(EFieldStyleStandard),
								@(EFieldStylePopUp)] retain];
	
	[mStylePopUp selectItemAtIndex: [sStylesInMenuOrder indexOfObject: @(((CFieldPart*)part)->GetStyle())]];

	[mLockTextSwitch setState: ((CFieldPart*)part)->GetLockText()];
	[mAutoSelectSwitch setState: ((CFieldPart*)part)->GetAutoSelect()];
	[mMultipleLinesSwitch setState: ((CFieldPart*)part)->GetCanSelectMultipleLines()];
	[mSharedTextSwitch setState: ((CFieldPart*)part)->GetSharedText()];
	[mDontWrapSwitch setState: ((CFieldPart*)part)->GetDontWrap()];
	[mDontSearchSwitch setState: ((CFieldPart*)part)->GetDontSearch()];
	[mHorizontalScrollerSwitch setState: ((CFieldPart*)part)->GetHasHorizontalScroller()];
	[mVerticalScrollerSwitch setState: ((CFieldPart*)part)->GetHasVerticalScroller()];
}


-(IBAction)	doAutoSelectSwitchToggled: (id)sender
{
	((CFieldPart*)part)->SetAutoSelect( [mAutoSelectSwitch state] == NSOnState );
}


-(IBAction)	doMultipleLinesSwitchToggled: (id)sender
{
	((CFieldPart*)part)->SetCanSelectMultipleLines( [mMultipleLinesSwitch state] == NSOnState );
}


-(IBAction)	doSharedTextSwitchToggled: (id)sender
{
	((CFieldPart*)part)->SetSharedText( [mSharedTextSwitch state] == NSOnState );
}


-(IBAction)	doLockTextSwitchToggled: (id)sender
{
	((CFieldPart*)part)->SetLockText( [mLockTextSwitch state] == NSOnState );
}


-(IBAction)	doDontWrapSwitchToggled: (id)sender
{
	((CFieldPart*)part)->SetDontWrap( [mDontWrapSwitch state] == NSOnState );
}


-(IBAction) doDontSearchSwitchToggled: (id)sender
{
	((CFieldPart*)part)->SetDontSearch( [mDontSearchSwitch state] == NSOnState );
}


-(IBAction)	doHorizontalScrollerSwitchToggled: (id)sender
{
	((CFieldPart*)part)->SetHasHorizontalScroller( [mHorizontalScrollerSwitch state] == NSOnState );
}


-(IBAction)	doVerticalScrollerSwitchToggled: (id)sender
{
	((CFieldPart*)part)->SetHasVerticalScroller( [mVerticalScrollerSwitch state] == NSOnState );
}


-(IBAction) doStylePopUpChanged:(id)sender
{
	((CFieldPart*)part)->SetStyle( (TFieldStyle) [[sStylesInMenuOrder objectAtIndex: [mStylePopUp indexOfSelectedItem]] intValue] );
}

@end
