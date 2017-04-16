//
//  CDrawingCanvas.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 02/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#include "CCanvas.h"
#include "CImageCanvas.h"
#import <Cocoa/Cocoa.h>

using namespace Carlson;


namespace Carlson
{
	TCompositingMode	ECompositingModeAlphaComposite = NSCompositingOperationSourceOver;
	TCompositingMode	ECompositingModeCopy = NSCompositingOperationCopy;
}



/*static*/ CRect	CRect::RectAroundPoints( const CPoint& inStart, const CPoint& inEnd )
{
	CRect lineBox;
	lineBox.SetH( std::min(inStart.GetH(),inEnd.GetH()) );
	lineBox.SetV( std::min(inStart.GetV(),inEnd.GetV()) );
	lineBox.ResizeByMovingMaxHEdgeTo( std::max(inStart.GetH(),inEnd.GetH()) );
	lineBox.ResizeByMovingMaxVEdgeTo( std::max(inStart.GetV(),inEnd.GetV()) );
	return lineBox;
}


CColor::CColor( TColorComponent red, TColorComponent green, TColorComponent blue, TColorComponent alpha )
{
	mColor = [[NSColor colorWithCalibratedRed: red / 65535.0 green: green / 65535.0 blue: blue / 65535.0 alpha: alpha / 65535.0] retain];
}


CColor::CColor( WILDNSColorPtr macColor )
{
	mColor = [macColor retain];
}


CColor::CColor( const CColor& inColor )
{
	mColor = [inColor.mColor retain];
}


CColor::~CColor()
{
	[mColor release];
}


TColorComponent	CColor::GetRed() const
{
	return [mColor redComponent] * 65535.0;
}


TColorComponent	CColor::GetGreen() const
{
	return [mColor greenComponent] * 65535.0;
}


TColorComponent	CColor::GetBlue() const
{
	return [mColor blueComponent] * 65535.0;
}


TColorComponent	CColor::GetAlpha() const
{
	return [mColor alphaComponent] * 65535.0;
}


CColor& CColor::operator =( const CColor& inColor )
{
	if( mColor != inColor.mColor )
	{
		[mColor release];
		mColor = [inColor.mColor retain];
	}
	
	return *this;
}


bool	CColor::operator ==( const CColor& inColor ) const
{
	CGFloat	ar, ag, ab, aa;
	CGFloat	br, bg, bb, ba;
	[mColor getRed: &ar green: &ag blue: &ab alpha: &aa];
	[inColor.mColor getRed: &br green: &bg blue: &bb alpha: &ba];
	return (fabs(ar - br) < 0.001) && (fabs(ag - bg) < 0.001) && (fabs(ab - bb) < 0.001) && (fabs(aa - ba) < 0.001);
}


CPath::CPath()
{
	mBezierPath = CGPathCreateMutable();
}


CPath::CPath( const CPath& inOriginal )
{
	mBezierPath = CGPathCreateMutableCopy(inOriginal.mBezierPath);
}

CPath::~CPath()
{
	CGPathRelease(mBezierPath);
}


void	CPath::MoveToPoint( CPoint inPoint )
{
	CGPathMoveToPoint( mBezierPath, NULL, inPoint.mPoint.x, inPoint.mPoint.y );
}
	

void	CPath::LineToPoint( CPoint inPoint )
{
	CGPathAddLineToPoint( mBezierPath, NULL, inPoint.mPoint.x, inPoint.mPoint.y );
}
	

void	CPath::ConnectEndToStart()
{
	CGPathCloseSubpath(mBezierPath);
}

	
void	CPath::MoveBy( CSize inDistance )
{
	CGPathRef			oldPath = mBezierPath;
	CGAffineTransform	transform = CGAffineTransformMakeTranslation( inDistance.mSize.width, inDistance.mSize.height );
	mBezierPath = CGPathCreateMutableCopyByTransformingPath( mBezierPath, &transform );
	CGPathRelease( oldPath );
}
	

void	CPath::ScaleBy( CSize inHScaleVScale )
{
	CGPathRef			oldPath = mBezierPath;
	CGAffineTransform	transform = CGAffineTransformMakeTranslation( inHScaleVScale.mSize.width, inHScaleVScale.mSize.height );
	mBezierPath = CGPathCreateMutableCopyByTransformingPath( mBezierPath, &transform );
	CGPathRelease( oldPath );
}


CRect	CPath::GetSurroundingRect() const
{
	return CRect( CGPathGetBoundingBox( mBezierPath ) );
}

	
CPath&	CPath::operator =( const CPath& inPath )
{
	if( inPath.mBezierPath != mBezierPath )
	{
		CGPathRelease(mBezierPath);
		mBezierPath = CGPathCreateMutableCopy(inPath.mBezierPath);
	}
	
	return *this;
}


size_t	CGraphicsState::sGraphicsStateSeed = 0;


void	CCanvas::StrokeRect( const CRect& inRect, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	[NSBezierPath strokeRect: inRect.mRect];
}


void	CCanvas::FillRect( const CRect& inRect, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	[NSBezierPath fillRect: inRect.mRect];
}


void	CCanvas::ClearRect( const CRect& inRect )
{
	NSRectFillUsingOperation( inRect.mRect, NSCompositingOperationClear );
}


void	CCanvas::StrokeOval( const CRect& inRect, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	[[NSBezierPath bezierPathWithOvalInRect: inRect.mRect] stroke];
}


void	CCanvas::FillOval( const CRect& inRect, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	[[NSBezierPath bezierPathWithOvalInRect: inRect.mRect] fill];
}


void	CCanvas::StrokeRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	[[NSBezierPath bezierPathWithRoundedRect: inRect.mRect xRadius: inCornerRadius yRadius: inCornerRadius] stroke];
}


void	CCanvas::FillRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	[[NSBezierPath bezierPathWithRoundedRect: inRect.mRect xRadius: inCornerRadius yRadius: inCornerRadius] fill];
}


void	CCanvas::StrokeLineFromPointToPoint( const CPoint& inStart, const CPoint& inEnd, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	[NSBezierPath strokeLineFromPoint: inStart.mPoint toPoint: inEnd.mPoint];
}


void	CCanvas::StrokePath( const CPath& inPath, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CGContextRef	context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGContextAddPath( context, inPath.mBezierPath );
	CGContextStrokePath( context );
}


void	CCanvas::FillPath( const CPath& inPath, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CGContextRef	context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGContextAddPath( context, inPath.mBezierPath );
	CGContextFillPath( context );
}


void	CCanvas::DrawImageInRect( const CImageCanvas& inImage, const CRect& inBox )
{
	[inImage.mImage drawInRect: inBox.mRect];
}


void	CCanvas::DrawImageAtPoint( const CImageCanvas& inImage, const CPoint& inPos )
{
	[inImage.mImage drawAtPoint: inPos.mPoint fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
}


CColor	CCanvas::ColorAtPosition( const CPoint& pos )
{
	return CColor( [NSReadPixel( pos.mPoint ) colorUsingColorSpaceName: NSCalibratedRGBColorSpace] );
}


void	CCanvas::ApplyGraphicsStateIfNeeded( const CGraphicsState& inState )
{
	if( inState.mGraphicsStateSeed != mLastGraphicsStateSeed )
	{
		[inState.mLineColor.mColor setStroke];
		[inState.mFillColor.mColor setFill];
		[NSBezierPath setDefaultLineWidth: inState.mLineThickness];
		mLastGraphicsStateSeed = inState.mGraphicsStateSeed;
		[NSGraphicsContext.currentContext setCompositingOperation: (NSCompositingOperation)inState.mCompositingMode];
	}
}


CMacCanvas::CMacCanvas( WILDNSGraphicsContextPtr inContext, CGRect inBounds )
 : mBounds(inBounds), mPreviousContext(nil)
{
	mContext = [inContext retain];
}


CMacCanvas::~CMacCanvas()
{
	[mContext release];
}
	
void	CMacCanvas::BeginDrawing()
{
	assert(mPreviousContext == nil);
	mPreviousContext = [[NSGraphicsContext currentContext] retain];
	[NSGraphicsContext setCurrentContext: mContext];
}


void	CMacCanvas::EndDrawing()
{
	[NSGraphicsContext setCurrentContext: mPreviousContext];
	[mPreviousContext release];
	mPreviousContext = nil;
}



