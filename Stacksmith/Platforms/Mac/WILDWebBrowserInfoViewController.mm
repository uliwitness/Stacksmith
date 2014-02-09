//
//  WILDWebBrowserInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDWebBrowserInfoViewController.h"
#import "UKHelperMacros.h"
#import "CWebBrowserPart.h"


using namespace Carlson;


@implementation WILDWebBrowserInfoViewController

@synthesize currentURLField = mCurrentURLField;

-(void)	loadView
{
	[super loadView];
	
	[mCurrentURLField setStringValue: [NSString stringWithUTF8String: ((CWebBrowserPart*)part)->GetCurrentURL().c_str()]];
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == mCurrentURLField )
	{
		((CWebBrowserPart*)part)->SetCurrentURL( [mCurrentURLField stringValue].UTF8String );
	}
}

@end
