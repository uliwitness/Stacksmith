//
//  CCursor.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-12.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CCursor.h"
#import <AppKit/AppKit.h>
#include <iostream>


void	CCursor::GetGlobalPosition( LEONumber* outX, LEONumber *outY )
{
	NSPoint		pos = [NSEvent mouseLocation];
	CGFloat		screenHeight = [[NSScreen screens][0] frame].size.height;
	*outX = pos.x;
	*outY = screenHeight -pos.y;
}


void	CCursor::Grab( std::function<void()> trackingHandler )
{
	NSDate				*	theDate = [NSDate distantFuture];
	NSAutoreleasePool	*	pool = [NSAutoreleasePool new];
	while( true )
	{
		NSEvent	*	currEvt = [[NSApplication sharedApplication] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask untilDate: theDate inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( currEvt )
		{
			if( currEvt.type == NSLeftMouseDragged )
			{
				//std::cout << "tracking." << std::endl;
				trackingHandler();
			}
			else if( currEvt.type == NSLeftMouseUp )
			{
				//std::cout << "Stop tracking." << std::endl;
				break;
			}
//			else
//				std::cout << "Huh?." << std::endl;
		}
		else
			std::cout << "NIL event?" << std::endl;
		[pool release];
		pool = [NSAutoreleasePool new];
	}
	[pool release];
}
