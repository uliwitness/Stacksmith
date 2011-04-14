//
//  WILDAppDelegate.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDAppDelegate : NSResponder <NSApplicationDelegate>
{
	IBOutlet NSMenu*	mToolsMenu;
	BOOL				mPeeking;
	BOOL				mBackgroundEditMode;
}


-(IBAction)	toggleBackgroundEditMode: (id)sender;
-(IBAction)	toolsMenuRowDummyAction: (id)sender;
-(IBAction)	orderFrontMessageBox: (id)sender;
-(IBAction)	orderFrontStandardAboutPanel: (id)sender;
-(IBAction)	goHelp: (id)sender;

@end
