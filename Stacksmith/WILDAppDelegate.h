//
//  WILDAppDelegate.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WILDTemplateProjectPickerController;


@interface WILDAppDelegate : NSResponder <NSApplicationDelegate>
{
	BOOL									mPeeking;
	BOOL									mBackgroundEditMode;
	id										mFlagsChangedEventMonitor;
	IBOutlet NSMenuItem			*			mNewObjectSeparator;
	IBOutlet NSMenuItem			*			mLockPseudoMenu;
	IBOutlet NSPanel			*			mToolPanel;
	IBOutlet NSButton			*			mBrowseToolButton;
	IBOutlet NSButton			*			mPointerToolButton;
	IBOutlet NSButton			*			mEditTextToolButton;
	IBOutlet NSButton			*			mOvalToolButton;
	IBOutlet NSButton			*			mRectangleToolButton;
	IBOutlet NSButton			*			mRoundrectToolButton;
	IBOutlet NSButton			*			mStackInfoButton;
	IBOutlet NSButton			*			mBackgroundInfoButton;
	IBOutlet NSButton			*			mCardInfoButton;
	IBOutlet NSButton			*			mEditBackgroundButton;
	IBOutlet NSButton			*			mMessageBoxButton;
	IBOutlet NSButton			*			mMessageWatcherButton;
	IBOutlet NSButton			*			mStackCanvasButton;
	IBOutlet NSButton			*			mGoPrevButton;
	IBOutlet NSButton			*			mGoNextButton;
	NSWindow					*			mObservedMainWindow;
	WILDTemplateProjectPickerController*	mTemplatePickerWindow;
}


-(IBAction)	orderFrontMessageBox: (id)sender;
-(IBAction)	orderFrontStandardAboutPanel: (id)sender;
-(IBAction)	goHelp: (id)sender;
-(IBAction)	goHome: (id)sender;

-(void)	checkForScriptToResume: (id)sender;

@end
