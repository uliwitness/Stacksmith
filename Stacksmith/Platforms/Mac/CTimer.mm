//
//  CTimer.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CTimer.h"


using namespace Carlson;


@interface CTimerMacBridge : NSObject
{
	CTimer	*		owningTimer;
}

-(id)	initWithOwningCppTimer: (CTimer*)inOwner;

-(void)	timerAction: (NSTimer*)sender;

@end


@implementation CTimerMacBridge : NSObject

-(id)	initWithOwningCppTimer: (CTimer*)inOwner
{
	self = [super init];
	if( self )
		owningTimer = inOwner;
	return self;
}


-(void)	timerAction: (NSTimer*)sender
{
	owningTimer->Trigger();
}

@end



CTimer::CTimer( long long inTimeIntervalInTicks )
	: mMacTimer(nil), mMacTarget(nil), mHandler(NULL), mTimeIntervalInTicks(inTimeIntervalInTicks)
{

}
	

CTimer::~CTimer()
{
	if( mMacTimer )
		Stop();
}


void	CTimer::Start()
{
	if( !mMacTimer )
	{
		mMacTarget = [[CTimerMacBridge alloc] initWithOwningCppTimer: this];
		mMacTimer = [[NSTimer alloc] initWithFireDate: [NSDate date] interval: ((NSTimeInterval)mTimeIntervalInTicks) / 60.0 target: mMacTarget selector: @selector(timerAction:) userInfo: nil repeats: YES];
	}
}


void	CTimer::Stop()
{
	[mMacTimer invalidate];
	[mMacTimer release];
	mMacTimer = nil;
	[mMacTarget release];
	mMacTarget = nil;
}


void	CTimer::SetInterval( long long inTimeIntervalInTicks )
{
	mTimeIntervalInTicks = inTimeIntervalInTicks;
	
	if( mMacTimer )
	{
		Stop();
		Start();
	}
}

