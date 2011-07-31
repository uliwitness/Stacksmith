//
//  WILDButtonInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartInfoViewController.h"

@interface WILDButtonInfoViewController : WILDPartInfoViewController
{
	NSPopUpButton*		mStylePopUp;
	NSPopUpButton*		mFamilyPopUp;
	NSButton*			mShowNameSwitch;
	NSButton*			mAutoHighlightSwitch;
	NSButton*			mHighlightedSwitch;
	NSButton*			mSharedHighlightSwitch;
}

@property (retain) IBOutlet NSPopUpButton*		stylePopUp;
@property (retain) IBOutlet NSPopUpButton*		familyPopUp;
@property (retain) IBOutlet NSButton*			showNameSwitch;
@property (retain) IBOutlet NSButton*			autoHighlightSwitch;
@property (retain) IBOutlet NSButton*			highlightedSwitch;
@property (retain) IBOutlet NSButton*			sharedHighlightSwitch;

-(IBAction)	doAutoHighlightSwitchToggled:(id)sender;
-(IBAction)	doHighlightedSwitchToggled:(id)sender;
-(IBAction)	doHighlightedSwitchToggled:(id)sender;
-(IBAction)	doSharedHighlightSwitchToggled:(id)sender;
-(IBAction) doFamilyPopUpChanged:(id)sender;
-(IBAction) doStylePopUpChanged:(id)sender;

@end
