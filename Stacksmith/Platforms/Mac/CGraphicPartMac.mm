//
//  CGraphicPartMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CGraphicPartMac.h"
#include "CStack.h"
#import "UKHelperMacros.h"
#import <QuartzCore/QuartzCore.h>
#import "ULIWideningBezierPath.h"
#import "CAlert.h"


static void FillFirstFreeOne( const char ** a, const char ** b, const char ** c, const char ** d, const char* theAppendee )
{
	if( *a == nil )
		*a = theAppendee;
	else if( *b == nil )
		*b = theAppendee;
	else if( *c == nil )
		*c = theAppendee;
	else if( *d == nil )
		*d = theAppendee;
}



@interface CALayer (WILDPreciseHitTest)

-(BOOL) preciselyContainsPoint: (CGPoint)pos;

@end


@implementation CALayer (WILDPreciseHitTest)

-(BOOL) preciselyContainsPoint: (CGPoint)pos
{
	if( ![self containsPoint: pos] )
		return NO;
	
	BOOL wasHit = NO;
	NSImage * img = [[NSImage alloc] initWithSize: self.bounds.size];
	[img lockFocus];
		CGContextRef ctx = [NSGraphicsContext currentContext].CGContext;
		[self renderInContext: ctx];
	[img unlockFocus];
	wasHit = [img hitTestRect: (NSRect){pos,{1,1}} withImageDestinationRect:(NSRect)self.bounds context: nil hints: nil flipped: NO];
	
	return wasHit;
}

@end



using namespace Carlson;


@interface WILDGraphicView : NSView
{
	NSTrackingArea * mCursorTrackingArea;
}

@property CGraphicPartMac* owningPart;

@end


@implementation WILDGraphicView

@synthesize owningPart = owningPart;

-(void)	dealloc
{
	[self removeTrackingArea: mCursorTrackingArea];
	DESTROY_DEALLOC(mCursorTrackingArea);
	self->owningPart = NULL;
	
	[super dealloc];
}


-(void)	mouseDown: (NSEvent*)event
{	
	const char *        firstModifier = nil;
	const char *        secondModifier = nil;
	const char *        thirdModifier = nil;
	const char *        fourthModifier = nil;
	
	if( event.modifierFlags & NSEventModifierFlagShift )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "shift" );
	else if( event.modifierFlags & NSEventModifierFlagCapsLock )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "shiftlock" );
	if( event.modifierFlags & NSEventModifierFlagOption )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "alternate" );
	if( event.modifierFlags & NSEventModifierFlagControl )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "control" );
	if( event.modifierFlags & NSEventModifierFlagCommand )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "command" );
	
	if( !firstModifier ) firstModifier = "";
	if( !secondModifier ) secondModifier = "";
	if( !thirdModifier ) thirdModifier = "";
	if( !fourthModifier ) fourthModifier = "";
	
	BOOL					keepLooping = YES;
	BOOL					isInside = [self.layer preciselyContainsPoint: [self.layer convertPoint: [event locationInWindow] fromLayer: nil]];
	BOOL					newIsInside = isInside;
	
	if( !isInside || !owningPart->GetEnabled() )
		return;
	
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseDown %ld,%s,%s,%s,%s", [event buttonNumber] +1, firstModifier, secondModifier, thirdModifier, fourthModifier );
	}
	
	NSAutoreleasePool	*	pool = [[NSAutoreleasePool alloc] init];
	
	while( keepLooping )
	{
		NSEvent	*	evt = [NSApp nextEventMatchingMask: NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp | NSEventMaskOtherMouseUp | NSEventMaskLeftMouseDragged | NSEventMaskRightMouseDragged | NSEventMaskOtherMouseDragged untilDate: [NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( evt )
		{
			switch( [evt type] )
			{
				case NSEventTypeLeftMouseUp:
				case NSEventTypeRightMouseUp:
				case NSEventTypeOtherMouseUp:
					keepLooping = NO;
					break;
					
				case NSEventTypeLeftMouseDragged:
				case NSEventTypeRightMouseDragged:
				case NSEventTypeOtherMouseDragged:
				{
					newIsInside = [self.layer preciselyContainsPoint: [self.layer convertPoint: [evt locationInWindow] fromLayer: nil]];
					if( isInside != newIsInside )
					{
						isInside = newIsInside;
					}
					CAutoreleasePool	cppPool;
					self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseDrag %ld,%s,%s,%s,%s", [event buttonNumber] +1, firstModifier, secondModifier, thirdModifier, fourthModifier );
					break;
				}
					
				default:
					break;
			}
		}
		
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
	}
	
	if( isInside )
	{
		self->owningPart->PrepareMouseUp();
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseUp %ld,%s,%s,%s,%s", [event buttonNumber] +1, firstModifier, secondModifier, thirdModifier, fourthModifier );
	}
	else
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseUpOutside %ld,%s,%s,%s,%s", [event buttonNumber] +1, firstModifier, secondModifier, thirdModifier, fourthModifier );
	}
	
	[pool release];
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

@end



CGraphicPartMac::~CGraphicPartMac()
{
	[mFillShapeLayer release];
	[mStrokeShapeLayer release];
	[mFillColorLayer release];
}


void	CGraphicPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView && mView.superview == inSuperView )
	{
		[mView removeFromSuperview];
		if( mView )
		{
			[inSuperView.animator addSubview: mView];	// Make sure we show up in right layering order.
		}
		return;
	}
	[mView.animator removeFromSuperview];
	DESTROY(mView);
	NSRect	box = NSMakeRect(GetLeft(), GetTop(), GetRight() -GetLeft(), GetBottom() -GetTop());
	WILDGraphicView * grcView = [[WILDGraphicView alloc] initWithFrame: box];	// mView below will take ownership.
	mView = grcView;
	grcView.owningPart = this;
	if( mStyle == EGraphicStyleRectangle || mStyle == EGraphicStyleRoundrect )
	{
		mView.wantsLayer = YES;
		[mFillShapeLayer release];
		mFillShapeLayer = [(CAShapeLayer*)[CALayer layer] retain];
		mView.layer = mFillShapeLayer;
		mFillShapeLayer.borderColor = [NSColor colorWithCalibratedRed: GetLineColorRed() / 65535.0 green: GetLineColorGreen() / 65535.0 blue: GetLineColorBlue() / 65535.0 alpha: GetLineColorAlpha() / 65535.0].CGColor;
		mFillShapeLayer.borderWidth = GetLineWidth();
		mFillShapeLayer.backgroundColor = [NSColor colorWithCalibratedRed: GetFillColorRed() / 65535.0 green: GetFillColorGreen() / 65535.0 blue: GetFillColorBlue() / 65535.0 alpha: GetFillColorAlpha() / 65535.0].CGColor;
		if( mStyle == EGraphicStyleRoundrect )
			mFillShapeLayer.cornerRadius = 8.0;
	}
	else
	{
		[mFillShapeLayer release];
		mFillShapeLayer = [[CAShapeLayer layer] retain];
		mFillShapeLayer.fillColor = [NSColor colorWithCalibratedRed: GetFillColorRed() / 65535.0 green: GetFillColorGreen() / 65535.0 blue: GetFillColorBlue() / 65535.0 alpha: GetFillColorAlpha() / 65535.0].CGColor;
		mFillShapeLayer.strokeColor = [NSColor colorWithCalibratedRed: GetLineColorRed() / 65535.0 green: GetLineColorGreen() / 65535.0 blue: GetLineColorBlue() / 65535.0 alpha: GetLineColorAlpha() / 65535.0].CGColor;
		mFillShapeLayer.lineWidth = GetLineWidth();
		if( mFillColorLayer )
		{
			mFillColorLayer.mask = mFillShapeLayer;
			mView.layer = mFillColorLayer;
		}
		else
			mView.layer = mFillShapeLayer;
		RebuildViewLayerPath();
		mView.wantsLayer = YES;
	}
	[mView setAutoresizingMask: GetCocoaResizeFlags( mPartLayoutFlags )];
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, -mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	[mView setHidden: !mVisible];
	[inSuperView.animator addSubview: mView];
}


void	CGraphicPartMac::RebuildViewLayerPath()
{
	NSRect	localBox = NSMakeRect(0, 0, GetRight() -GetLeft(), GetBottom() -GetTop());
	if( mStyle == EGraphicStyleOval )
	{
		localBox = NSInsetRect( localBox, mLineWidth, mLineWidth );
		mFillShapeLayer.path = (CGPathRef)[(id) CGPathCreateWithEllipseInRect( localBox, NULL) autorelease];
	}
	else if( mStyle == EGraphicStyleBezierPath || mStyle == EGraphicStyleLine )
	{
		ULIWideningBezierPath	*	fillPath = [[[ULIWideningBezierPath alloc] init] autorelease];
		CGFloat factor = GetLineWidth();
		if( mPoints.size() > 0 )
		{
			bool		first = true;
			for( const CPathSegment& currSegment : mPoints )
			{
				if( first )
				{
					[fillPath moveToPoint: NSMakePoint(currSegment.x, localBox.size.height -currSegment.y) lineWidth: currSegment.lineWidth * factor];
					first = false;
				}
				else
				{
					[fillPath lineToPoint: NSMakePoint(currSegment.x, localBox.size.height -currSegment.y) lineWidth: currSegment.lineWidth * factor];
				}
			}
		}
		
		if( mStyle == EGraphicStyleLine )
		{
			mFillShapeLayer.path = [fillPath CGPathForStroke];
			mFillShapeLayer.contentsGravity = kCAGravityResize;
			mFillShapeLayer.sublayers = @[];
		}
		else
		{
			mFillShapeLayer.path = [fillPath CGPathForFill];
			mFillShapeLayer.contentsGravity = kCAGravityResize;
			
			if( GetGradientColors().size() > 0 )
			{
				if( !mFillColorLayer )
				{
					mFillColorLayer = [[CAGradientLayer layer] retain];
					NSMutableArray*	colors = [NSMutableArray array];
					for( const CColor& currColor : GetGradientColors() )
						[colors addObject: (id)currColor.GetMacColor()];
					mFillColorLayer.colors = colors;
					mFillColorLayer.startPoint = CGPointMake(0, 0.5);
					mFillColorLayer.endPoint = CGPointMake(1, 0.5);
				}
				mFillColorLayer.mask = mFillShapeLayer;
				mView.layer = mFillColorLayer;
			}
			else
				mView.layer = mFillShapeLayer;
			
			if( !mStrokeShapeLayer )
			{
				mStrokeShapeLayer = [[CAShapeLayer layer] retain];
			}
			[mView.layer addSublayer: mStrokeShapeLayer];
			
			mStrokeShapeLayer.path = [fillPath CGPathForStroke];
			mStrokeShapeLayer.contentsGravity = kCAGravityResize;
		}
	}
}


NSImage*	CGraphicPartMac::GetDisplayIcon()
{
	static NSImage*	sGraphicIcon = nil;
	if( !sGraphicIcon )
	{
		sGraphicIcon = [[NSImage imageNamed: @"GraphicIcon"] copy];
		[sGraphicIcon setSize: NSMakeSize(16,16)];
	}
	return sGraphicIcon;
}


void	CGraphicPartMac::DestroyView()
{
	if( mView )
	{
		[mView.animator removeFromSuperview];
		DESTROY(mView);
	}
}


void	CGraphicPartMac::SetRect( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b )
{
	CGraphicPart::SetRect( l, t, r, b );
	[mView setFrame: NSMakeRect(l, t, r-l, b-t)];
	RebuildViewLayerPath();
	GetStack()->RectChangedOfPart( this );
}


void	CGraphicPartMac::SetPartLayoutFlags( TPartLayoutFlags inFlags )
{
	CGraphicPart::SetPartLayoutFlags( inFlags );
	
	[mView setAutoresizingMask: GetCocoaResizeFlags( mPartLayoutFlags )];
}


void	CGraphicPartMac::SetFillColor( int r, int g, int b, int a )
{
	CGraphicPart::SetFillColor( r, g, b, a );

	if( mStyle == EGraphicStyleRectangle || mStyle == EGraphicStyleRoundrect )
	{
		[(CALayer*)mFillShapeLayer setBackgroundColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
	else
	{
		[mFillShapeLayer setFillColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CGraphicPartMac::SetLineColor( int r, int g, int b, int a )
{
	CGraphicPart::SetLineColor( r, g, b, a );

	if( mStyle == EGraphicStyleRectangle || mStyle == EGraphicStyleRoundrect )
	{
		[(CALayer*)mFillShapeLayer setBorderColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
	else if( mStyle == EGraphicStyleBezierPath )
	{
		[(mStrokeShapeLayer ?: mFillShapeLayer) setFillColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
	else
	{
		[mFillShapeLayer setStrokeColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CGraphicPartMac::SetShadowColor( int r, int g, int b, int a )
{
	CGraphicPart::SetShadowColor( r, g, b, a );
	
	CAShapeLayer*	theLayer = mFillShapeLayer;
	if( theLayer.sublayers.count > 0 && mFillColorAlpha == 0 )
	{
		[theLayer setShadowOpacity: 0.0];
		theLayer = mStrokeShapeLayer;
	}
	
	[theLayer setShadowOpacity: (a == 0) ? 0.0 : 1.0];
	if( a != 0 )
	{
		[theLayer setShadowColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CGraphicPartMac::SetShadowOffset( double w, double h )
{
	CGraphicPart::SetShadowOffset( w, h );
	
	CAShapeLayer*	theLayer = mFillShapeLayer;
	if( theLayer.sublayers.count > 0 && mFillColorAlpha == 0 )
	{
		[theLayer setShadowOpacity: 0.0];
		theLayer = mStrokeShapeLayer;
	}
	
	[theLayer setShadowOffset: NSMakeSize(w,-h)];
}


void	CGraphicPartMac::SetShadowBlurRadius( double r )
{
	CGraphicPart::SetShadowBlurRadius( r );
	
	CAShapeLayer*	theLayer = mFillShapeLayer;
	if( theLayer.sublayers.count > 0 && mFillColorAlpha == 0 )
	{
		[theLayer setShadowOpacity: 0.0];
		theLayer = mStrokeShapeLayer;
	}
	
	[theLayer setShadowRadius: r];
}


void	CGraphicPartMac::SetLineWidth( int w )
{
	CGraphicPart::SetLineWidth( w );
	
	if( mStyle == EGraphicStyleRectangle || mStyle == EGraphicStyleRoundrect )
		[mFillShapeLayer setBorderWidth: w];
	else if( mStyle == EGraphicStyleBezierPath )
	{
		RebuildViewLayerPath();
	}
	else
		[mFillShapeLayer setLineWidth: w];
}


void	CGraphicPartMac::AddPoint( LEONumber x, LEONumber y, LEONumber lineWidth )
{
	CGraphicPart::AddPoint( x, y, lineWidth );
	
	RebuildViewLayerPath();
}


void	CGraphicPartMac::UpdateLastPoint( LEONumber x, LEONumber y, LEONumber lineWidth )
{
	CGraphicPart::UpdateLastPoint( x, y, lineWidth );
	
	RebuildViewLayerPath();
}


void	CGraphicPartMac::SetPositionOfCustomHandleAtIndex( LEOInteger idx, LEONumber x, LEONumber y )
{
	CGraphicPart::SetPositionOfCustomHandleAtIndex( idx, x, y );
	
	RebuildViewLayerPath();
}


