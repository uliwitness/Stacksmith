//
//  WILDStackInfoWindowController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WILDCardView;
@class WILDStack;


@interface WILDStackInfoWindowController : NSWindowController
{
    WILDCardView	*	mCardView;
	WILDStack		*	mStack;
	
	NSTextField		*	mNameField;
	NSTextField		*	mIDField;
	NSTextField		*	mBackgroundCountField;
	NSTextField		*	mCardCountField;
	NSButton		*	mEditScriptButton;
	NSTextField		*	mWidthField;
	NSTextField		*	mHeightField;
}

@property (retain) WILDCardView				*	cardView;
@property (retain) WILDStack				*	stack;

@property (retain) IBOutlet	NSButton		*	editScriptButton;
@property (retain) IBOutlet	NSTextField		*	nameField;
@property (retain) IBOutlet	NSTextField		*	IDField;
@property (retain) IBOutlet	NSTextField		*	cardCountField;
@property (retain) IBOutlet	NSTextField		*	backgroundCountField;
@property (retain) IBOutlet	NSTextField		*	widthField;
@property (retain) IBOutlet	NSTextField		*	heightField;

-(id)		initWithStack: (WILDStack*)inStack ofCardView: (WILDCardView*)owningView;

-(IBAction)	doOKButton: (id)sender;
-(IBAction)	doCancelButton: (id)sender;
-(IBAction)	doEditScriptButton: (id)sender;

@end
