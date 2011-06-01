//
//  WILDButtonView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import "WILDButtonView.h"
#import "WILDPartView.h"
#import "WILDScriptContainer.h"


@implementation WILDButtonView

-(void)	mouseDown: (NSEvent*)event
{
	WILDPartView*			pv = [self superview];
	BOOL					keepLooping = YES;
	BOOL					autoHighlight = [[pv part] autoHighlight];
	BOOL					isInside = [[self cell] hitTestForEvent: event inRect: [self bounds] ofView: self] != NSCellHitNone;
	BOOL					newIsInside = isInside;
	
	if( !isInside )
		return;
	
	if( autoHighlight && isInside )
		[[self cell] setHighlighted: YES];
	
	WILDScriptContainerResultFromSendingMessage( [pv part], @"mouseDown" );
	
	NSAutoreleasePool	*	pool = [[NSAutoreleasePool alloc] init];
	
	while( keepLooping )
	{
		NSEvent	*	evt = [NSApp nextEventMatchingMask: NSLeftMouseUpMask | NSRightMouseUpMask | NSOtherMouseUpMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask untilDate: [NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( evt )
		{
			switch( [evt type] )
			{
				 case NSLeftMouseUp:
				 case NSRightMouseUp:
				 case NSOtherMouseUp:
					keepLooping = NO;
					break;
				
				case NSLeftMouseDragged:
				case NSRightMouseDragged:
				case NSOtherMouseDragged:
					WILDScriptContainerResultFromSendingMessage( [pv part], @"mouseStillDown" );
					newIsInside = [[self cell] hitTestForEvent: evt inRect: [self bounds] ofView: self] != NSCellHitNone;
					if( isInside != newIsInside )
					{
						isInside = newIsInside;

						if( autoHighlight )
							[[self cell] setHighlighted: isInside];
					}
					break;
			}
		}
		
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
	}
	
	if( isInside )
	{
		if( autoHighlight )
			[[self cell] setHighlighted: NO];
		WILDScriptContainerResultFromSendingMessage( [pv part], @"mouseUp" );
		[[self target] performSelector: [self action]];
	}
	else
		WILDScriptContainerResultFromSendingMessage( [pv part], @"mouseUpOutside" );
	
	[pool release];
}


-(void)	resetCursorRects
{
	NSCursor	*	currentCursor = [WILDTools cursorForTool: [[WILDTools sharedTools] currentTool]];
	[self addCursorRect: [self bounds] cursor: currentCursor];
}

@end
