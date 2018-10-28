//
//  WILDButtonInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDButtonInfoViewController.h"
#import "WILDMediaPickerViewController.h"
#import "CButtonPartMac.h"
#import "UKHelperMacros.h"


using namespace Carlson;


static 	NSArray*	sStylesInMenuOrder = nil;


@implementation WILDButtonInfoViewController

@synthesize iconButton = mIconButton;
@synthesize stylePopUp = mStylePopUp;
@synthesize familyPopUp = mFamilyPopUp;
@synthesize showNameSwitch = mShowNameSwitch;
@synthesize autoHighlightSwitch = mAutoHighlightSwitch;
@synthesize highlightedSwitch = mHighlightedSwitch;
@synthesize sharedHighlightSwitch = mSharedHighlightSwitch;

-(void)	dealloc
{
	[mIconPopover close];
	DESTROY_DEALLOC(mIconPopover);
	DESTROY_DEALLOC(mStylePopUp);
	DESTROY_DEALLOC(mFamilyPopUp);
	DESTROY_DEALLOC(mShowNameSwitch);
	DESTROY_DEALLOC(mAutoHighlightSwitch);
	DESTROY_DEALLOC(mHighlightedSwitch);
	DESTROY_DEALLOC(mSharedHighlightSwitch);
	DESTROY_DEALLOC(mIconButton);
	
	[super dealloc];
}


-(void)	loadView
{
	[super loadView];
	
	if( !sStylesInMenuOrder )
	{
		sStylesInMenuOrder = [@[@(EButtonStyleRectangle),
								@(EButtonStyleRoundrect),
								@(EButtonStyleOval),
								@(EButtonStyleStandard),
								@(EButtonStyleDefault),
								@(EButtonStyleCheckBox),
								@(EButtonStyleRadioButton),
								@(EButtonStylePopUp)] retain];
	}
	
	CButtonPartMac*	bpm = (CButtonPartMac*)part;
	[mStylePopUp selectItemAtIndex: [sStylesInMenuOrder indexOfObject: @(bpm->GetStyle())]];
	[mFamilyPopUp selectItemAtIndex: part->GetFamily()];

	[mShowNameSwitch setState: bpm->GetShowName()];
	[mAutoHighlightSwitch setState: bpm->GetAutoHighlight()];
	[mHighlightedSwitch setState: bpm->GetHighlight()];
	[mSharedHighlightSwitch setState: bpm->GetSharedHighlight()];
	[self.bevelSlider setDoubleValue: bpm->GetBevelWidth()];
	[self.bevelAngleSlider setDoubleValue: bpm->GetBevelAngle()];
}


-(IBAction)	doShowNameSwitchToggled:(id)sender
{
	((CButtonPartMac*)part)->SetShowName( [mShowNameSwitch state] == NSControlStateValueOn );
}


-(IBAction)	doSharedHighlightSwitchToggled: (id)sender
{
	((CButtonPartMac*)part)->SetSharedHighlight( [mSharedHighlightSwitch state] == NSControlStateValueOn );
}


-(IBAction)	doHighlightedSwitchToggled:(id)sender
{
	((CButtonPartMac*)part)->SetHighlight( [mHighlightedSwitch state] == NSControlStateValueOn );
}


-(IBAction)	doAutoHighlightSwitchToggled:(id)sender
{
	((CButtonPartMac*)part)->SetAutoHighlight( [mAutoHighlightSwitch state] == NSControlStateValueOn );
}


-(IBAction) doFamilyPopUpChanged:(id)sender
{
	((CButtonPartMac*)part)->SetFamily( [mFamilyPopUp indexOfSelectedItem] );
}


-(IBAction) doStylePopUpChanged:(id)sender
{
	((CButtonPartMac*)part)->SetStyle( (TButtonStyle) [[sStylesInMenuOrder objectAtIndex: [mStylePopUp indexOfSelectedItem]] intValue] );
}


-(IBAction)	doShowIconPicker: (id)sender
{
	[mIconPopover close];
	DESTROY(mIconPopover);
	
	WILDMediaPickerViewController	*	iconPickerViewController = [[[WILDMediaPickerViewController alloc] initWithPart: (CButtonPart*)part] autorelease];
	
	mIconPopover = [[NSPopover alloc] init];
	[mIconPopover setDelegate: self];
	[mIconPopover setBehavior: NSPopoverBehaviorTransient];
	[mIconPopover setContentViewController: iconPickerViewController];
	[mIconPopover showRelativeToRect: [mIconButton bounds] ofView: mIconButton preferredEdge: NSMaxXEdge];
}

-(IBAction)	doBevelSliderChanged: (id)sender
{
	((CButtonPartMac*)part)->SetBevelWidth( self.bevelSlider.doubleValue );
}

-(IBAction)	doBevelAngleSliderChanged: (id)sender
{
	((CButtonPartMac*)part)->SetBevelAngle( self.bevelAngleSlider.doubleValue );
}


-(void)	popoverDidClose: (NSNotification *)notification
{
	DESTROY(mIconPopover);
}

@end
