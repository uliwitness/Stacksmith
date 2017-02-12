//
//  WILDConcreteObjectInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


namespace Carlson
{
	class CConcreteObject;
}
@class WILDUserPropertyEditorController;


@interface WILDConcreteObjectInfoViewController : NSViewController
{
	Carlson::CConcreteObject	*	mInfoedObject;
	
	NSTextField					*	mNameField;
	NSTextField					*	mIDField;
	NSButton					*	mEditScriptButton;
}

@property (retain) IBOutlet	NSButton		*	editScriptButton;
@property (retain) IBOutlet	NSTextField		*	nameField;
@property (retain) IBOutlet	NSTextField		*	IDField;
@property (retain) IBOutlet WILDUserPropertyEditorController*		userPropertyEditor;

-(id)	initWithConcreteObject: (Carlson::CConcreteObject*)inObject;

-(IBAction)	doEditScriptButton: (id)sender;

@end
