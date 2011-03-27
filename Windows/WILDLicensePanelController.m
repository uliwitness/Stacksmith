//
//  WILDLicensePanelController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 01.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLicensePanelController.h"
#import "UKLicense.h"


static WILDLicensePanelController	*	sCurrentLicensePanel = nil;


NSString*	WILDLicensePanelTriggerOKAfterwards = @"WILDLicensePanelTriggerOKAfterwards";


@implementation WILDLicensePanelController

@synthesize licenseTextField = mLicenseTextField;
@synthesize OKButton = mOKButton;

+(WILDLicensePanelController*)	currentLicensePanelController
{
	return sCurrentLicensePanel;
}

-(id)	init
{
    self = [super initWithWindowNibName: @"WILDLicensePanelController"];
    if( self )
	{
        [self setShouldCascadeWindows: NO];
    }
    
	if( sCurrentLicensePanel )
	{
		[self autorelease];
		return nil;
	}
	
	sCurrentLicensePanel = self;
	
    return self;
}

-(void)	dealloc
{
	sCurrentLicensePanel = nil;
	
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
//	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object: [self window]];
	
	[self updateLicenseKeyButtonEnableState: nil];
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
	mUserChangedText = YES;
	[mOKButton setEnabled: NO];
	[self performSelector: @selector(updateLicenseKeyButtonEnableState:) withObject: nil afterDelay: 0.0 inModes: [NSArray arrayWithObject: NSModalPanelRunLoopMode]];
}


-(void)	updateLicenseKeyButtonEnableState: (NSDictionary*)options
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
	
	// If we were asked to, simulate a click on the OK button, if the license is valid:
	//	Used e.g. by our license file support.
	if( [[options objectForKey: WILDLicensePanelTriggerOKAfterwards] boolValue] )
	{
		if( (theInfo.ukli_licenseFlags & UKLicenseFlagValid) != 0 )
		{
			[[mOKButton target] performSelector: [mOKButton action] withObject: mOKButton afterDelay: 0.0
										inModes: [NSArray arrayWithObject: NSModalPanelRunLoopMode]];
		}
	}
}


-(void)	windowDidBecomeKey: (NSNotification*)notif
{
	if( [[mLicenseTextField stringValue] length] == 0 || !mUserChangedText )
	{
		NSPasteboard*	pb = [NSPasteboard generalPasteboard];
		NSString	*	theSerial = [pb stringForType: NSStringPboardType];
		
		if( theSerial && [theSerial length] > 0 )
			[mLicenseTextField setStringValue: theSerial];
		[self performSelector: @selector(updateLicenseKeyButtonEnableState:) withObject: nil afterDelay: 0.0 inModes: [NSArray arrayWithObject: NSModalPanelRunLoopMode]];
	}
}


-(void)	setLicenseKeyString: (NSString*)inLicenseKey
{
	if( inLicenseKey && [inLicenseKey length] > 0 )
	{
		mUserChangedText = YES;
		[mLicenseTextField setStringValue: inLicenseKey];
	}
	[self performSelector: @selector(updateLicenseKeyButtonEnableState:)
			   withObject: [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] forKey: WILDLicensePanelTriggerOKAfterwards]
			   afterDelay: 0.0 inModes: [NSArray arrayWithObject: NSModalPanelRunLoopMode]];
}

@end
