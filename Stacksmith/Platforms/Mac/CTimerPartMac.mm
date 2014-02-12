//
//  CTimerPartMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CTimerPartMac.h"
#include "CStack.h"


using namespace Carlson;


void	CTimerPartMac::CreateViewIn( NSView* inSuperView )
{
	// We don't short-circuit here, as the tool may have changed forcing us to need to be recreated.
	if( mView )
	{
		[mView removeFromSuperview];
		[mView release];
	}
	if( GetStack()->GetTool() == EPointerTool )
	{
		mView = [[NSImageView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
		[mView setImage: [NSImage imageNamed: @"TimerIcon"]];
		[inSuperView addSubview: mView];
	}
}


NSImage*	CTimerPartMac::GetDisplayIcon()
{
	static NSImage*	sTimerIcon = nil;
	if( !sTimerIcon )
	{
		sTimerIcon = [[NSImage imageNamed: @"TimerIcon"] copy];
		[sTimerIcon setSize: NSMakeSize(16,16)];
	}
	return sTimerIcon;
}



void	CTimerPartMac::DestroyView()
{
	if( mView )
	{
		[mView removeFromSuperview];
		[mView release];
		mView = nil;
	}
}
