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


using namespace Carlson;


void	CGraphicPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView && mView.superview == inSuperView )
	{
		[mView removeFromSuperview];
		if( mView )
			[inSuperView addSubview: mView];	// Make sure we show up in right layering order.
		return;
	}
	[mView removeFromSuperview];
	DESTROY(mView);
	NSRect	box = NSMakeRect(GetLeft(), GetTop(), GetRight() -GetLeft(), GetBottom() -GetTop());
	mView = [[NSView alloc] initWithFrame: box];
	if( mStyle == EGraphicStyleRectangle || mStyle == EGraphicStyleRoundrect )
	{
		mView.wantsLayer = YES;
		mView.layer.borderColor = [NSColor colorWithCalibratedRed: GetLineColorRed() / 65535.0 green: GetLineColorGreen() / 65535.0 blue: GetLineColorBlue() / 65535.0 alpha: GetLineColorAlpha() / 65535.0].CGColor;
		mView.layer.borderWidth = GetLineWidth();
		mView.layer.backgroundColor = [NSColor colorWithCalibratedRed: GetFillColorRed() / 65535.0 green: GetFillColorGreen() / 65535.0 blue: GetFillColorBlue() / 65535.0 alpha: GetFillColorAlpha() / 65535.0].CGColor;
		if( mStyle == EGraphicStyleRoundrect )
			mView.layer.cornerRadius = 8.0;
	}
	else
	{
		CAShapeLayer	*	theLayer = [CAShapeLayer layer];
		mView.layer = theLayer;
		theLayer.fillColor = [NSColor colorWithCalibratedRed: GetFillColorRed() / 65535.0 green: GetFillColorGreen() / 65535.0 blue: GetFillColorBlue() / 65535.0 alpha: GetFillColorAlpha() / 65535.0].CGColor;
		theLayer.strokeColor = [NSColor colorWithCalibratedRed: GetLineColorRed() / 65535.0 green: GetLineColorGreen() / 65535.0 blue: GetLineColorBlue() / 65535.0 alpha: GetLineColorAlpha() / 65535.0].CGColor;
		theLayer.lineWidth = GetLineWidth();
		RebuildViewLayerPath();
		mView.wantsLayer = YES;
	}
	[mView setAutoresizingMask: GetCocoaResizeFlags( mPartLayoutFlags )];
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, -mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	[inSuperView addSubview: mView];
}


void	CGraphicPartMac::RebuildViewLayerPath()
{
	NSRect	localBox = NSMakeRect(0, 0, GetRight() -GetLeft(), GetBottom() -GetTop());
	CAShapeLayer	*	theLayer = (CAShapeLayer*)mView.layer;
	if( mStyle == EGraphicStyleOval )
	{
		localBox = NSInsetRect( localBox, mLineWidth, mLineWidth );
		theLayer.path = (CGPathRef)[(id) CGPathCreateWithEllipseInRect( localBox, NULL) autorelease];
	}
	else if( mStyle == EGraphicStyleBezierPath )
	{
		CGMutablePathRef	thePath = CGPathCreateMutable();
		if( mPoints.size() > 0 )
		{
			CGPathMoveToPoint( thePath, NULL, mPoints[0].x, mPoints[0].y );
			for( const CPathSegment& currSegment : mPoints )
			{
				CGPathAddLineToPoint( thePath, NULL, currSegment.x, currSegment.y );
			}
		}
		theLayer.path = thePath;
		theLayer.contentsGravity = kCAGravityResize;
		CGPathRelease(thePath);
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
		[mView removeFromSuperview];
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
		[mView.layer setBackgroundColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
	else
	{
		[(CAShapeLayer*)mView.layer setFillColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CGraphicPartMac::SetLineColor( int r, int g, int b, int a )
{
	CGraphicPart::SetLineColor( r, g, b, a );

	if( mStyle == EGraphicStyleRectangle || mStyle == EGraphicStyleRoundrect )
	{
		[mView.layer setBorderColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
	else
	{
		[(CAShapeLayer*)mView.layer setStrokeColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CGraphicPartMac::SetShadowColor( int r, int g, int b, int a )
{
	CGraphicPart::SetShadowColor( r, g, b, a );
	
	[mView.layer setShadowOpacity: (a == 0) ? 0.0 : 1.0];
	if( a != 0 )
	{
		[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CGraphicPartMac::SetShadowOffset( double w, double h )
{
	CGraphicPart::SetShadowOffset( w, h );
	
	[mView.layer setShadowOffset: NSMakeSize(w,-h)];
}


void	CGraphicPartMac::SetShadowBlurRadius( double r )
{
	CGraphicPart::SetShadowBlurRadius( r );
	
	[mView.layer setShadowRadius: r];
}


void	CGraphicPartMac::SetLineWidth( int w )
{
	CGraphicPart::SetLineWidth( w );
	
	if( mStyle == EGraphicStyleRectangle || mStyle == EGraphicStyleRoundrect )
		[mView.layer setBorderWidth: w];
	else
		[(CAShapeLayer*)mView.layer setLineWidth: w];
}


