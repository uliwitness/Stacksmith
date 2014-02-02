//
//  WILDScriptEditorWindowController.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "CConcreteObject.h"


@class UKSyntaxColoredTextViewController;


@interface WILDScriptEditorWindowController : NSWindowController
{
	Carlson::CConcreteObject*					mContainer;			// Not retained, this is our owner!
	NSArray*									mSymbols;			// List of symbol name/type -> line mappings for handler popup.
	IBOutlet NSTextView*						mTextView;			// Script text.
	IBOutlet NSPopUpButton*						mPopUpButton;		// Handlers popup.
	IBOutlet UKSyntaxColoredTextViewController*	mSyntaxController;	// Provides some extra functionality like syntax coloring.
	NSRect										mGlobalStartRect;	// For opening animation.
	IBOutlet NSView	*							mTopNavAreaView;	// The top area above the text (becomes fullscreen accessory view).
}

-(id)		initWithScriptContainer: (Carlson::CConcreteObject*)inContainer;

-(IBAction)	handlerPopupSelectionChanged: (id)sender;

-(void)		setGlobalStartRect: (NSRect)theBox;

-(void)		goToLine: (NSUInteger)lineNum;
-(void)		goToCharacter: (NSUInteger)charNum;

@end
