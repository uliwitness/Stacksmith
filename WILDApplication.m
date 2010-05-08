//
//  WILDApplication.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDApplication.h"
#import "WILDNotifications.h"


@implementation WILDApplication

-(void)	sendEvent: (NSEvent*)theEvent
{
	if( [theEvent type] == NSFlagsChanged )
	{
		if( !mPeeking && ([theEvent modifierFlags] & NSAlternateKeyMask)
			&& ([theEvent modifierFlags] & NSCommandKeyMask) )
		{
			mPeeking = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName: WILDPeekingStateChangedNotification
													object: nil userInfo:
														[NSDictionary dictionaryWithObjectsAndKeys:
															[NSNumber numberWithBool: mPeeking], WILDPeekingStateKey,
														nil]];
		}
		else if( mPeeking )
		{
			mPeeking = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName: WILDPeekingStateChangedNotification
													object: nil userInfo:
														[NSDictionary dictionaryWithObjectsAndKeys:
															[NSNumber numberWithBool: mPeeking], WILDPeekingStateKey,
														nil]];
		}
	}
	
	[super sendEvent: theEvent];
}

@end
