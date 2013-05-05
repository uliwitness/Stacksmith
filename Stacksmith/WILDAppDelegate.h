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
	BOOL				mPeeking;
	BOOL				mBackgroundEditMode;
	id					mFlagsChangedEventMonitor;
	IBOutlet NSMenuItem	*mNewObjectSeparator;
}


-(IBAction)	orderFrontMessageBox: (id)sender;
-(IBAction)	orderFrontStandardAboutPanel: (id)sender;
-(IBAction)	goHelp: (id)sender;

@end
