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

@end
