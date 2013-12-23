//
//  WILDTimerInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDTimerInfoViewController.h"
#import "WILDNotifications.h"
#import "UKHelperMacros.h"
#import "WILDPart.h"


@implementation WILDTimerInfoViewController

@synthesize messageField = mMessageField;
@synthesize intervalField = mIntervalField;

-(void)	loadView
{
	[super loadView];
	
	[mMessageField setStringValue: [part timerMessage]];
	[mIntervalField setIntegerValue: [part timerInterval]];
	[self.startedSwitch setState: (part.started ? NSOnState : NSOffState)];
	[self.autoStopSwitch setState: (part.autoStop ? NSOnState : NSOffState)];
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == mMessageField )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(timerMessage), WILDAffectedPropertyKey,
										nil]];

		[part setTimerMessage: [mMessageField stringValue]];
			
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(timerMessage), WILDAffectedPropertyKey,
										nil]];
		[part updateChangeCount: NSChangeDone];
	}
	else if( [notif object] == mIntervalField )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(timerInterval), WILDAffectedPropertyKey,
										nil]];

		[part setTimerInterval: [mIntervalField integerValue]];
			
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(timerInterval), WILDAffectedPropertyKey,
										nil]];
		[part updateChangeCount: NSChangeDone];
	}
}


-(IBAction)	doStartedSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
									PROPERTY(started), WILDAffectedPropertyKey,
									nil]];

	[part setStarted: [sender state] == NSOnState];
			
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
									PROPERTY(started), WILDAffectedPropertyKey,
									nil]];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doAutoStopSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
									PROPERTY(autoStop), WILDAffectedPropertyKey,
									nil]];

	[part setAutoStop: [sender state] == NSOnState];
			
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
									PROPERTY(autoStop), WILDAffectedPropertyKey,
									nil]];
	[part updateChangeCount: NSChangeDone];
}

@end
