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
}

@property (retain) IBOutlet NSPopUpButton*		stylePopUp;
@property (retain) IBOutlet NSButton*			showNameSwitch;

-(IBAction) doStylePopUpChanged:(id)sender;

@end
