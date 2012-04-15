//
//  WILDAboutPanelController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 01.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDAboutPanelController.h"
#import "NSWindow+ULIZoomEffect.h"
#import "StacksmithVersion.h"
#import "UKHelperMacros.h"


@implementation WILDAboutPanelController

@synthesize licenseeField = mLicenseeField;
@synthesize companyField = mCompanyField;
@synthesize versionField = mVersionField;

+(void)	showAboutPanel
{
	static WILDAboutPanelController	*	sAboutPanel = nil;
	if( !sAboutPanel )
	{
		sAboutPanel = [[WILDAboutPanelController alloc] init];
		[[sAboutPanel window] makeKeyAndOrderFrontWithZoomEffectFromRect: NSZeroRect];
	}
	else
	{
		if( [[sAboutPanel window] isVisible] )
			[[sAboutPanel window] makeKeyAndOrderFrontWithPopEffect];
		else
			[[sAboutPanel window] makeKeyAndOrderFrontWithZoomEffectFromRect: NSZeroRect];
	}
}

- (id)init
{
    self = [super initWithWindowNibName: @"WILDAboutPanelController"];
    if( self )
	{
        [self setShouldCascadeWindows: NO];
    }
    
    return self;
}

- (void)dealloc
{
	DESTROY_DEALLOC(mLicenseeField);
	DESTROY_DEALLOC(mCompanyField);
	DESTROY_DEALLOC(mVersionField);
	
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    	
	NSString*	version = [NSString stringWithFormat: @"%@ (%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"], @SVN_VERSION ];
	[mVersionField setStringValue: version];
}


-(BOOL)	windowShouldClose: (id)sender
{
	[[self window] orderOutWithZoomEffectToRect: NSZeroRect];
	
	return YES;
}

@end
