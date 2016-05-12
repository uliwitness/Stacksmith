//
//  WILDScrollView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import "WILDScrollView.h"
#import "UKHelperMacros.h"
#include "CStack.h"
#include "CRefCountedObject.h"
#include "CAlert.h"


using namespace Carlson;


@implementation WILDScrollView

@synthesize lineColor;
@synthesize lineWidth;
@synthesize owningPart;


-(id)	initWithFrame: (NSRect)inBox
{
	self = [super initWithFrame: inBox];
	if( self )
	{
		lineColor = [[NSColor blackColor] retain];
		lineWidth = 1.0;
	}
	return self;
}


-(id)	initWithCoder: (NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	if( self )
	{
		lineColor = [[NSColor blackColor] retain];
		lineWidth = 1.0;
	}
	return self;
}


-(void)	dealloc
{
	DESTROY_DEALLOC(lineColor);
	DESTROY_DEALLOC(mCursorTrackingArea);
	
	[super dealloc];
}


-(void)	drawRect: (NSRect)dirtyRect
{
	if( [self borderType] == NSLineBorder )
	{
		[[self backgroundColor] set];
		NSRectFill( dirtyRect );
		
		if( lineWidth > 0 )
		{
			NSRect	lineBox = self.bounds;
			lineBox.origin.x += lineWidth / 2.0;
			lineBox.origin.y += lineWidth / 2.0;
			lineBox.size.width -= lineWidth / 2.0;
			lineBox.size.height -= lineWidth / 2.0;
			[lineColor set];
			[NSBezierPath setDefaultLineWidth: lineWidth];
			[NSBezierPath strokeRect: lineBox];
			[NSBezierPath setDefaultLineWidth: 1.0];
		}
	}
	else
		[super drawRect: dirtyRect];
}


-(void)	setLineColor: (NSColor*)theColor
{
	ASSIGN(self->lineColor,theColor);
	[self setNeedsDisplay: YES];
}


-(void)	setLineWidth: (CGFloat)inLineWidth
{
	self->lineWidth = inLineWidth;
	[self setNeedsDisplay: YES];
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
	
	if( self.owningPart )
	{
		if( self.owningPart->HasOrInheritsMessageHandler("mouseEnter") || self.owningPart->HasOrInheritsMessageHandler("mouseLeave") )
			trackingOptions |= NSTrackingMouseEnteredAndExited;
		if( self.owningPart->HasOrInheritsMessageHandler("mouseMove") )
			trackingOptions |= NSTrackingMouseMoved;
	}
	
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
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseEnter %ld", [theEvent buttonNumber] +1 );
	}
}


-(void)	mouseExited:(NSEvent *)theEvent
{
	if( self->owningPart->GetShouldSendMouseEventsRightNow() )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseLeave %ld", [theEvent buttonNumber] +1 );
	}
}


-(void)	mouseMoved:(NSEvent *)theEvent
{
	if( self->owningPart->GetShouldSendMouseEventsRightNow() )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseMove" );
	}
}


-(BOOL)	isOpaque
{
	if( self.borderType == NSLineBorder )
		return NO;
	else
	{
		return [super isOpaque];
	}
}

@end
