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


using namespace Carlson;


void	CCursor::GetGlobalPosition( LEONumber* outX, LEONumber *outY )
{
	NSPoint		pos = [NSEvent mouseLocation];
	CGFloat		screenHeight = [[NSScreen screens][0] frame].size.height;
	*outX = pos.x;
	*outY = screenHeight -pos.y;
}


bool	CCursor::Grab( int mouseButtonNumber, std::function<bool( LEONumber x, LEONumber y, LEONumber pressure )> trackingHandler )
{
	CGFloat					screenHeight = [[NSScreen screens].firstObject frame].size.height;
	NSDate				*	theDate = [NSDate distantFuture];
	NSAutoreleasePool	*	pool = [NSAutoreleasePool new];
	bool					didEverMove = false;
	
	NSUInteger				eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;
	if( mouseButtonNumber == 1 )
		eventMask = NSRightMouseUpMask | NSRightMouseDraggedMask;
	else if( mouseButtonNumber > 1 )
		eventMask = NSOtherMouseUpMask | NSOtherMouseDraggedMask;
	
	while( true )
	{
		NSEvent	*	currEvt = [[NSApplication sharedApplication] nextEventMatchingMask: eventMask untilDate: theDate inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( currEvt )
		{
			if( currEvt.type == NSLeftMouseDragged || currEvt.type == NSRightMouseDragged || currEvt.type == NSOtherMouseDragged )
			{
				didEverMove = true;
				
				NSPoint		pos = [[currEvt window] frame].origin;
				pos.x += [currEvt locationInWindow].x;
				pos.y += [currEvt locationInWindow].y;
				pos.y = screenHeight -pos.y;	// Flip coordinates to TOP-left relative like xTalk expects.

				//std::cout << "tracking." << std::endl;
				LEONumber	pressure = [currEvt pressure];
				if( pressure == 0 )	// Can't happen while dragging, so assume device doesn't give pressure info and use 1.0.
					pressure = 1.0;
				if( !trackingHandler( pos.x, pos.y, pressure ) )
					break;
			}
			else if( currEvt.type == NSLeftMouseUp || currEvt.type == NSRightMouseUp || currEvt.type == NSOtherMouseUp )
			{
				if( currEvt.type != NSOtherMouseUp || currEvt.buttonNumber == mouseButtonNumber )	// For "other" mouse events, make sure button number matches.
					break;	// Exit tracking loop, mouse was released.
			}
//			else
//				std::cout << "Huh?." << std::endl;
		}
//		else
//			std::cout << "NIL event?" << std::endl;
		[pool release];
		pool = [NSAutoreleasePool new];
		
		if( ([NSEvent pressedMouseButtons] & (1 << mouseButtonNumber)) == 0 )	// In case we called a script that swallowed the mouseUp. +++ Could cause issues with UI scripting or other incomplete or fake mouse tracking. Need to verify.
			break;
	}
	[pool release];
	
	return didEverMove;
}
