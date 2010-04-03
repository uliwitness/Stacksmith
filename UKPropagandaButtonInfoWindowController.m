//
//  UKPropagandaButtonInfoWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 03.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaButtonInfoWindowController.h"
#import "UKPropagandaPart.h"


@implementation UKPropagandaButtonInfoWindowController

-(id)		initWithPart: (UKPropagandaPart*)inPart
{
	if(( self = [super initWithWindowNibName: NSStringFromClass([self class])] ))
	{
		mPart = inPart;
	}
	
	return self;
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	[mNameField setStringValue: [mPart name]];
	
	NSString*	layerName = [[mPart partLayer] capitalizedString];
	[mButtonNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Button Number:", layerName]];
	[mPartNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Part Number:", layerName]];
	[mIDLabel setStringValue: [NSString stringWithFormat: @"%@ Button ID:", layerName]];
	[mIDField setIntegerValue: [mPart partID]];
	
	[mShowNameSwitch setState: [mPart showName]];
	[mAutoHighlightSwitch setState: [mPart autoHighlight]];
	[mEnabledSwitch setState: [mPart isEnabled]];
	
	//[mStylePopUp selectItemAtIndex: [mPart style]];
	[mFamilyPopUp selectItemAtIndex: [mPart family]];
	
	//[mContentsTextField setString: ];
}

-(IBAction)	doOKButton: (id)sender
{
	[self close];
}


-(IBAction)	doCancelButton: (id)sender
{
	[self close];
}

@end
