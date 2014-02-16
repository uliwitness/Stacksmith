//
//  WILDStackInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


namespace Carlson
{
	class CStack;
}
@class WILDUserPropertyEditorController;


@interface WILDStackInfoViewController : NSViewController
{
	Carlson::CStack	*	mStack;
	
	NSTextField		*	mNameField;
	NSTextField		*	mIDField;
	NSTextField		*	mBackgroundCountField;
	NSTextField		*	mCardCountField;
	NSButton		*	mEditScriptButton;
	NSButton		*	mApplySizeButton;
	NSTextField		*	mWidthField;
	NSTextField		*	mHeightField;
	NSButton		*	mUserPropertyEditButton;
	NSPopUpButton	*	mSizePopUpButton;
	NSButton		*	mResizableSwitch;
}

@property (retain) IBOutlet	NSButton		*	editScriptButton;
@property (retain) IBOutlet	NSButton		*	applySizeButton;
@property (retain) IBOutlet	NSTextField		*	nameField;
@property (retain) IBOutlet	NSTextField		*	IDField;
@property (retain) IBOutlet	NSTextField		*	cardCountField;
@property (retain) IBOutlet	NSTextField		*	backgroundCountField;
@property (retain) IBOutlet	NSTextField		*	widthField;
@property (retain) IBOutlet	NSTextField		*	heightField;
@property (retain) IBOutlet	NSButton		*	userPropertyEditButton;
@property (retain) IBOutlet	NSPopUpButton	*	sizePopUpButton;
@property (retain) IBOutlet	NSButton		*	resizableSwitch;
@property (retain) IBOutlet WILDUserPropertyEditorController*		userPropertyEditor;

-(id)		initWithStack: (Carlson::CStack*)inStack;

-(IBAction)	doEditScriptButton: (id)sender;

-(IBAction)	sizePopUpSelectionChanged: (id)sender;
-(IBAction)	doApplySizeButton: (id)sender;
-(IBAction)	doResizableSwitchChanged: (id)sender;

@end
