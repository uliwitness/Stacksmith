//
//  UKPropagandaFieldInfoWindowController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 03.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class UKPropagandaPart;
@class UKPropagandaWindowBodyView;


@interface UKPropagandaFieldInfoWindowController : NSWindowController
{
	UKPropagandaPart*				mPart;				// The card/bg part we're editing.
	UKPropagandaWindowBodyView*		mCardView;			// BG parts can have different values/contents on each card, so we need to know which one.
	IBOutlet NSTextField*			mNameField;
	IBOutlet NSTextField*			mButtonNumberField;
	IBOutlet NSTextField*			mButtonNumberLabel;
	IBOutlet NSTextField*			mPartNumberField;
	IBOutlet NSTextField*			mPartNumberLabel;
	IBOutlet NSTextField*			mIDField;
	IBOutlet NSTextField*			mIDLabel;
	IBOutlet NSPopUpButton*			mStylePopUp;
	IBOutlet NSButton*				mLockTextSwitch;
	IBOutlet NSButton*				mDontWrapSwitch;
	IBOutlet NSButton*				mAutoSelectSwitch;
	IBOutlet NSButton*				mMultipleLinesSwitch;
	IBOutlet NSButton*				mWideMarginsSwitch;
	IBOutlet NSButton*				mFixedLineHeightSwitch;
	IBOutlet NSButton*				mShowLinesSwitch;
	IBOutlet NSButton*				mAutoTabSwitch;
	IBOutlet NSButton*				mDontSearchSwitch;
	IBOutlet NSButton*				mSharedTextSwitch;
	IBOutlet NSButton*				mEnabledSwitch;
	IBOutlet NSButton*				mVisibleSwitch;
	IBOutlet NSTextView*			mContentsTextField;
}

-(id)		initWithPart: (UKPropagandaPart*)inPart ofCardView: (UKPropagandaWindowBodyView*)owningView;

-(IBAction)	doEditScriptButton: (id)sender;
-(IBAction)	doOKButton: (id)sender;
-(IBAction)	doCancelButton: (id)sender;

@end
