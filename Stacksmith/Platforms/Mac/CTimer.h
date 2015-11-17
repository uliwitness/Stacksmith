//
//  CTimer.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CTimer__
#define __Stacksmith__CTimer__

/*
	A simple timer class that calls its handler at roughly the given
	frequency. Timers start out stopped, and stop themselves when destructed.
*/

#include <functional>

#if __OBJC__
#include <Foundation/Foundation.h>

@class CTimerMacBridge;

typedef NSTimer*				NSTimerPtr;
typedef CTimerMacBridge*		CTimerMacBridgePtr;
#else
typedef struct NSTimer*			NSTimerPtr;
typedef struct CTimerMacBridge*	CTimerMacBridgePtr;
#endif


namespace Carlson {

class CTimer
{
public:
	explicit CTimer( long long inTimeIntervalInTicks = 60, std::function<void(CTimer*)> inTimerHandler = nullptr );
	~CTimer();
	
	void		Start();
	void		Stop();
	bool		IsRunning()		{ return mMacTimer != NULL; };
	
	void		SetInterval( long long inTimeIntervalInTicks );
	void		SetHandler( std::function<void(CTimer*)> timerHandler )	{ mHandler = timerHandler; };
	
	void		Trigger()		{ if( mHandler ) mHandler( this ); };	// Called by Mac-specific code, do not use!
	
protected:
	NSTimerPtr						mMacTimer;
	CTimerMacBridgePtr				mMacTarget;
	std::function<void(CTimer*)>	mHandler;
	long long						mTimeIntervalInTicks;
};

}

#endif /* defined(__Stacksmith__CTimer__) */
