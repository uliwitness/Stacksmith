//
//  WILDAboutPanelController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 01.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDAboutPanelController : NSWindowController
{
@private
	NSTextField		*		mLicenseeField;
	NSTextField		*		mCompanyField;
	NSTextField		*		mVersionField;    
}

@property (retain,nonatomic) IBOutlet NSTextField		*		licenseeField;
@property (retain,nonatomic) IBOutlet NSTextField		*		companyField;
@property (retain,nonatomic) IBOutlet NSTextField		*		versionField;    

+(void)	showAboutPanel;

@end
