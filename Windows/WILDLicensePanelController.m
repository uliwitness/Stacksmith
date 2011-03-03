//
//  WILDLicensePanelController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 01.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLicensePanelController.h"
#import "UKLicense.h"


@implementation WILDLicensePanelController

@synthesize licenseTextField = mLicenseTextField;
@synthesize OKButton = mOKButton;

-(id)	init
{
    self = [super initWithWindowNibName: @"WILDLicensePanelController"];
    if( self )
	{
        [self setShouldCascadeWindows: NO];
    }
    
    return self;
}

-(void)	dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSControlTextDidChangeNotification object: mLicenseTextField];
	
	DESTROY( mLicenseTextField );
	DESTROY( mOKButton );
	
    [super dealloc];
}

-(void)	windowDidLoad
{
    [super windowDidLoad];
	
	NSString	*	theKey = [[NSUserDefaults standardUserDefaults] objectForKey: @"WILDLicenseKey"];
	if( theKey )
		[mLicenseTextField setStringValue: theKey]; 
	[mOKButton setEnabled: NO];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(textDidChange:) name:NSControlTextDidChangeNotification object: mLicenseTextField];
	
	[self updateLicenseKeyButtonEnableState];
}


-(NSInteger)	runModal
{
	[NSApp runModalForWindow: [self window]];
	
	[self close];
	
	return 0;
}


-(IBAction)	doOK: (id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject: [mLicenseTextField stringValue] forKey: @"WILDLicenseKey"];
	[[NSUserDefaults standardUserDefaults] synchronize];	
	[NSApp stopModalWithCode: NSOKButton];
}


-(IBAction)	doCancel: (id)sender
{
	[NSApp stopModalWithCode: NSCancelButton];
	
	exit(0);
}


-(void)	textDidChange: (NSNotification *)notification
{
	[mOKButton setEnabled: NO];
	[self performSelector: @selector(updateLicenseKeyButtonEnableState) withObject: nil afterDelay: 0.0 inModes: [NSArray arrayWithObject: NSModalPanelRunLoopMode]];
}


-(void)	updateLicenseKeyButtonEnableState
{
	// Check serial number:
	struct UKLicenseInfo	theInfo;
	NSString			*	textString = [mLicenseTextField stringValue];
	NSData				*	textData = [textString dataUsingEncoding: NSASCIIStringEncoding];
	int						numBinaryBytes = UKBinaryLengthForReadableBytesOfLength( [textData length] );
	NSMutableData		*	binaryBytes = [NSMutableData dataWithLength: numBinaryBytes];
	UKBinaryDataForReadableBytesOfLength( [textData bytes], [textData length], [binaryBytes mutableBytes] );
	UKGetLicenseData( [binaryBytes mutableBytes], [binaryBytes length], &theInfo );
	
	[mOKButton setEnabled: (theInfo.ukli_licenseFlags & UKLicenseFlagValid) != 0];
}

@end
