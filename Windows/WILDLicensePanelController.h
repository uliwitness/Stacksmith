//
//  WILDLicensePanelController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 01.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDLicensePanelController : NSWindowController
{
@private
    NSTextField			*		mLicenseTextField;
	NSButton			*		mOKButton;
}

@property (retain,nonatomic) IBOutlet NSTextField	*	licenseTextField;
@property (retain,nonatomic) IBOutlet NSButton		*	OKButton;

-(NSInteger)	runModal;

-(IBAction)	doOK: (id)sender;
-(IBAction)	doCancel: (id)sender;

-(void)	updateLicenseKeyButtonEnableState;

@end
