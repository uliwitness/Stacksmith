//
//  WILDConcreteObjectInfoViewController.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDConcreteObjectInfoViewController.h"
#import "CStack.h"
#import "UKHelperMacros.h"
#import "NSWindow+ULIZoomEffect.h"
#import "WILDUserPropertyEditorController.h"


using namespace Carlson;


@implementation WILDConcreteObjectInfoViewController

@synthesize nameField = mNameField;
@synthesize IDField = mIDField;
@synthesize editScriptButton = mEditScriptButton;

-(id)	initWithConcreteObject: (CConcreteObject*)inObject
{
	if(( self = [super initWithNibName: NSStringFromClass([self class]) bundle: nil] ))
	{
		mInfoedObject = (CConcreteObject*)inObject->Retain();
	}
	
	return self;
}

-(void)	dealloc
{
	mInfoedObject->Release();
	
	DESTROY_DEALLOC( mEditScriptButton );
	DESTROY_DEALLOC( mNameField );
	DESTROY_DEALLOC( mIDField );
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	[self.userPropertyEditor setPropertyContainer: mInfoedObject];
		
	[mNameField setStringValue: [NSString stringWithUTF8String: mInfoedObject->GetName().c_str()]];
	
	[mIDField setIntegerValue: mInfoedObject->GetID()];
}


-(IBAction)	doEditScriptButton: (id)sender
{
	mInfoedObject->OpenScriptEditorAndShowLine( SIZE_T_MAX );
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == mNameField )
	{
		mInfoedObject->SetName( [mNameField stringValue].UTF8String );
	}
}

@end
