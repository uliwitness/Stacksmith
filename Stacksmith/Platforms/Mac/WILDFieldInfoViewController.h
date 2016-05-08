//
//  WILDFieldInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartInfoViewController.h"

@interface WILDFieldInfoViewController : WILDPartInfoViewController
{
	NSPopUpButton*		mStylePopUp;
	NSButton*			mLockTextSwitch;
	NSButton*			mAutoSelectSwitch;
	NSButton*			mMultipleLinesSwitch;
	NSButton*			mSharedTextSwitch;
	NSButton*			mDontWrapSwitch;
	NSButton*			mDontSearchSwitch;
	NSButton*			mHorizontalScrollerSwitch;
	NSButton*			mVerticalScrollerSwitch;
	NSButton*			mAutoTabSwitch;
}

@property (retain) IBOutlet NSPopUpButton*		stylePopUp;
@property (retain) IBOutlet NSButton*			lockTextSwitch;
@property (retain) IBOutlet NSButton*			autoSelectSwitch;
@property (retain) IBOutlet NSButton*			multipleLinesSwitch;
@property (retain) IBOutlet NSButton*			sharedTextSwitch;
@property (retain) IBOutlet NSButton*			dontWrapSwitch;
@property (retain) IBOutlet NSButton*			dontSearchSwitch;
@property (retain) IBOutlet NSButton*			horizontalScrollerSwitch;
@property (retain) IBOutlet NSButton*			verticalScrollerSwitch;
@property (retain) IBOutlet NSButton*			autoTabSwitch;

-(IBAction)	doAutoSelectSwitchToggled: (id)sender;
-(IBAction)	doMultipleLinesSwitchToggled: (id)sender;
-(IBAction)	doSharedTextSwitchToggled: (id)sender;
-(IBAction)	doLockTextSwitchToggled: (id)sender;
-(IBAction)	doDontWrapSwitchToggled: (id)sender;
-(IBAction) doDontSearchSwitchToggled: (id)sender;
-(IBAction)	doHorizontalScrollerSwitchToggled: (id)sender;
-(IBAction)	doVerticalScrollerSwitchToggled: (id)sender;
-(IBAction) doStylePopUpChanged: (id)sender;
-(IBAction)	doAutoTabSwitchToggled: (id)sender;

@end
