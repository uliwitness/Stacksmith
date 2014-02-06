//
//  WILDGroupInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartInfoViewController.h"


@interface WILDGroupInfoViewController : WILDPartInfoViewController <NSPopoverDelegate>
{
	NSPopUpButton*		mStylePopUp;
	NSButton*			mShowNameSwitch;
	NSButton*			mHorizontalScrollerSwitch;
	NSButton*			mVerticalScrollerSwitch;
	NSTextField*		mContentWidthField;
	NSTextField*		mContentHeightField;
}

@property (retain) IBOutlet NSPopUpButton*		stylePopUp;
@property (retain) IBOutlet NSButton*			showNameSwitch;
@property (retain) IBOutlet NSButton*			horizontalScrollerSwitch;
@property (retain) IBOutlet NSButton*			verticalScrollerSwitch;
@property (retain) IBOutlet NSTextField*		contentWidthField;
@property (retain) IBOutlet NSTextField*		contentHeightField;

-(IBAction)	doHorizontalScrollerSwitchToggled: (id)sender;
-(IBAction)	doVerticalScrollerSwitchToggled: (id)sender;
-(IBAction) doStylePopUpChanged:(id)sender;

@end
