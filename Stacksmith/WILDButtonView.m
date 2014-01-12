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
#import "UKHelperMacros.h"
#import "WILDPart.h"
#import "WILDDocument.h"


@implementation WILDButtonView

-(void)	dealloc
{
	[self removeTrackingArea: mCursorTrackingArea];
	DESTROY_DEALLOC(mCursorTrackingArea);

	[super dealloc];
}


-(void)	mouseDown: (NSEvent*)event
{
	WILDPartView*			pv = (WILDPartView*)[self superview];
	BOOL					keepLooping = YES;
	BOOL					autoHighlight = [[pv part] autoHighlight];
	BOOL					isInside = [[self cell] hitTestForEvent: event inRect: [self bounds] ofView: self] != NSCellHitNone;
	BOOL					newIsInside = isInside;
	
	if( !isInside || !self.isEnabled )
		return;
	
	if( autoHighlight && isInside )
		[[self cell] setHighlighted: YES];
	
	WILDScriptContainerResultFromSendingMessage( [pv part], @"mouseDown %ld", [event buttonNumber] +1 );
	
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
					newIsInside = [[self cell] hitTestForEvent: evt inRect: [self bounds] ofView: self] != NSCellHitNone;
					if( isInside != newIsInside )
					{
						isInside = newIsInside;

						if( autoHighlight )
							[[self cell] setHighlighted: isInside];
					}
					WILDScriptContainerResultFromSendingMessage( [pv part], @"mouseDrag %ld", [evt buttonNumber] +1 );
					break;
			}
		}
		
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
	}
	
	if( isInside )
	{
		if( autoHighlight )
		{
			[[self cell] setHighlighted: NO];
			[self setNeedsDisplay: YES];
			[self.window display];
		}
		[[self target] performSelector: [self action] withObject: self];
		WILDScriptContainerResultFromSendingMessage( [pv part], @"mouseUp %ld", [event buttonNumber] +1 );
	}
	else
		WILDScriptContainerResultFromSendingMessage( [pv part], @"mouseUpOutside %ld", [event buttonNumber] +1 );
	
	[pool release];
}


#if USE_CURSOR_RECTS

-(void)	resetCursorRects
{
	NSCursor	*	currentCursor = [WILDTools cursorForTool: [[WILDTools sharedTools] currentTool]];
	if( !currentCursor )
	{
		WILDPartView*		pv = (WILDPartView*) [self superview];
		currentCursor = [[[[pv part] stack] document] cursorWithID: 128];
	}
	[self addCursorRect: [self bounds] cursor: currentCursor];
}

#else // !USE_CURSOR_RECTS

-(void)	mouseEntered:(NSEvent *)theEvent
{
	WILDTool			currTool = [[WILDTools sharedTools] currentTool];
	NSCursor*			currCursor = [WILDTools cursorForTool: currTool];
	if( !currCursor )
	{
		WILDPartView*		pv = [self superview];
		currCursor = [[[[pv part] stack] document] cursorWithID: 128];
	}
	[currCursor set];
}


-(void)	mouseExited:(NSEvent *)theEvent
{
	
}


- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if( mCursorTrackingArea )
	{
		[self removeTrackingArea: mCursorTrackingArea];
		DESTROY(mCursorTrackingArea);
	}
	
	mCursorTrackingArea = [[NSTrackingArea alloc] initWithRect: [self visibleRect] options: NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner: self userInfo: nil];
	[self addTrackingArea: mCursorTrackingArea];
}

#endif

-(NSRect)	frameForAlignmentRect:(NSRect)alignmentRect
{
	return alignmentRect;
}

-(NSRect)	alignmentRectForFrame:(NSRect)frame
{
	return frame;
}


-(void)	windowDidChangeKeyOrMain: (NSNotification*)inNotif
{
	[self setNeedsDisplay: YES];
}


-(void)	viewDidMoveToWindow
{
	[super viewDidMoveToWindow];
	
	if( self.window )
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidChangeKeyOrMain:) name: NSWindowDidBecomeKeyNotification object: self.window];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidChangeKeyOrMain:) name: NSWindowDidResignKeyNotification object: self.window];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidChangeKeyOrMain:) name: NSWindowDidBecomeMainNotification object: self.window];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidChangeKeyOrMain:) name: NSWindowDidResignMainNotification object: self.window];
	}
}


-(void)	viewWillMoveToWindow: (NSWindow *)newWindow
{
	if( self.window )
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidBecomeKeyNotification object: self.window];
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidResignKeyNotification object: self.window];
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidBecomeMainNotification object: self.window];
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidResignMainNotification object: self.window];
	}
	
	[super viewWillMoveToWindow: newWindow];
}

@end
