//
//  WILDInvisiblePlayerView.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-03-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "WILDInvisiblePlayerView.h"
#import "UKHelperMacros.h"
#include "CStack.h"
#include "CRefCountedObject.h"
#include "CAlert.h"


using namespace Carlson;


@implementation WILDInvisiblePlayerView

@synthesize owningPart = owningPart;
@synthesize cursor = mCursor;

-(void)	dealloc
{
	DESTROY_DEALLOC(mCursorTrackingArea);
	DESTROY_DEALLOC(mCursor);

	[super dealloc];
}

-(void)	mouseDown: (NSEvent *)theEvent
{
	if( owningPart )
	{
		CAutoreleasePool		pool;
		owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLineOffset, size_t inOffset, CScriptableObject* inErrObj, bool wasHandled){ CAlert::RunScriptErrorAlert( inErrObj, errMsg, inLineOffset, inOffset ); }, EMayGoUnhandled, "mouseDown %ld", [theEvent buttonNumber] );
	}
}


-(void)	mouseDragged: (NSEvent *)theEvent
{
	if( owningPart )
	{
		CAutoreleasePool		pool;
		owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLineOffset, size_t inOffset, CScriptableObject* inErrObj, bool wasHandled){ CAlert::RunScriptErrorAlert( inErrObj, errMsg, inLineOffset, inOffset ); }, EMayGoUnhandled, "mouseDrag %ld", [theEvent buttonNumber] );
	}
}


-(void)	mouseUp: (NSEvent *)theEvent
{
	if( owningPart )
	{
		const char*	theMsg = "mouseUp %ld";
		if( !NSPointInRect( [self convertPoint: [theEvent locationInWindow] fromView: nil], self.bounds ) )
		{
			theMsg = "mouseUpOutside %ld";
		}
		
		CAutoreleasePool		pool;
		owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLineOffset, size_t inOffset, CScriptableObject* inErrObj, bool wasHandled){ CAlert::RunScriptErrorAlert( inErrObj, errMsg, inLineOffset, inOffset ); }, EMayGoUnhandled, theMsg, [theEvent buttonNumber] );
	}
}


-(void)	updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if( mCursorTrackingArea )
	{
		[self removeTrackingArea: mCursorTrackingArea];
		DESTROY(mCursorTrackingArea);
	}
	NSTrackingAreaOptions	trackingOptions = 0;
	
	if( self.owningPart->HasOrInheritsMessageHandler("mouseEnter", nullptr, nullptr) || self.owningPart->HasOrInheritsMessageHandler("mouseLeave", nullptr, nullptr) )
		trackingOptions |= NSTrackingMouseEnteredAndExited;
	if( self.owningPart->HasOrInheritsMessageHandler("mouseMove", nullptr, nullptr) )
		trackingOptions |= NSTrackingMouseMoved;
	
	if( trackingOptions != 0 )
	{
		trackingOptions |= NSTrackingActiveInActiveApp;
		mCursorTrackingArea = [[NSTrackingArea alloc] initWithRect: self.bounds options: trackingOptions owner: self userInfo: nil];
		[self addTrackingArea: mCursorTrackingArea];
	}
}


-(void)	mouseEntered:(NSEvent *)theEvent
{
	if( self->owningPart->GetShouldSendMouseEventsRightNow() )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseEnter %ld", [theEvent buttonNumber] +1 );
	}
}


-(void)	mouseExited:(NSEvent *)theEvent
{
	if( self->owningPart->GetShouldSendMouseEventsRightNow() )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseLeave %ld", [theEvent buttonNumber] +1 );
	}
}


-(void)	mouseMoved:(NSEvent *)theEvent
{
	if( self->owningPart->GetShouldSendMouseEventsRightNow() )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseMove" );
	}
}


-(void)	resetCursorRects
{
	[super resetCursorRects];
	
	if( mCursor && self.owningPart )
	{
		[self addCursorRect: [self bounds] cursor: (self.owningPart->GetStack()->GetTool() != EBrowseTool) ? [NSCursor arrowCursor] : mCursor];
	}
}


-(void)	setCursor: (NSCursor*)inCursor
{
	ASSIGN(mCursor,inCursor);
	
	[self.window invalidateCursorRectsForView: self];
}

@end
