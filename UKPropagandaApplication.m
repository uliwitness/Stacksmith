//
//  UKPropagandaApplication.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaApplication.h"
#import "UKPropagandaNotifications.h"


@implementation UKPropagandaApplication

-(void)	sendEvent: (NSEvent*)theEvent
{
	if( [theEvent type] == NSFlagsChanged )
	{
		if( !mPeeking && ([theEvent modifierFlags] & NSAlternateKeyMask)
			&& ([theEvent modifierFlags] & NSCommandKeyMask) )
		{
			mPeeking = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPeekingStateChangedNotification
													object: nil userInfo:
														[NSDictionary dictionaryWithObjectsAndKeys:
															[NSNumber numberWithBool: mPeeking], UKPropagandaPeekingStateKey,
														nil]];
		}
		else if( mPeeking )
		{
			mPeeking = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPeekingStateChangedNotification
													object: nil userInfo:
														[NSDictionary dictionaryWithObjectsAndKeys:
															[NSNumber numberWithBool: mPeeking], UKPropagandaPeekingStateKey,
														nil]];
		}
	}
	
	[super sendEvent: theEvent];
}

@end
