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


using namespace Carlson;


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
	mView = [[NSView alloc] initWithFrame: box];
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


