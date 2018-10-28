//
//  WILDTimerInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDTimerInfoViewController.h"
#import "UKHelperMacros.h"
#import "CTimerPart.h"


using namespace Carlson;


@implementation WILDTimerInfoViewController

@synthesize messageField = mMessageField;
@synthesize intervalField = mIntervalField;

-(void)	loadView
{
	[super loadView];
	
	[mMessageField setStringValue: [NSString stringWithUTF8String: ((CTimerPart*)part)->GetMessage().c_str()]];
	[mIntervalField setIntegerValue: ((CTimerPart*)part)->GetInterval()];
	[self.startedSwitch setState: (((CTimerPart*)part)->GetStarted() ? NSControlStateValueOn : NSControlStateValueOff)];
	[self.repeatSwitch setState: (((CTimerPart*)part)->GetRepeat() ? NSControlStateValueOn : NSControlStateValueOff)];
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == mMessageField )
	{
		((CTimerPart*)part)->SetMessage( [mMessageField stringValue].UTF8String );
	}
	else if( [notif object] == mIntervalField )
	{
		((CTimerPart*)part)->SetInterval( [mIntervalField integerValue] );
	}
}


-(IBAction)	doStartedSwitchToggled: (id)sender
{
	((CTimerPart*)part)->SetStarted( [sender state] == NSControlStateValueOn );
}


-(IBAction)	doRepeatSwitchToggled: (id)sender
{
	((CTimerPart*)part)->SetRepeat( [sender state] == NSControlStateValueOn );
}

@end
