//
//  CDrawingCanvas.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 02/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#include "CCanvas.h"
#include "CImageCanvas.h"


using namespace Carlson;


namespace Carlson
{
	TCompositingMode	ECompositingModeAlphaComposite = kCGBlendModeNormal;
	TCompositingMode	ECompositingModeCopy = kCGBlendModeCopy;
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
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName( kCGColorSpaceGenericRGB );
	CGFloat components[4] = { red, green, blue, alpha };
	mColor = CGColorCreate( colorSpace, components );
	CGColorSpaceRelease(colorSpace);
}


CColor::CColor( CGColorRef macColor )
{
	mColor = CGColorRetain(macColor);
}


CColor::CColor( const CColor& inColor )
{
	mColor = CGColorRetain(inColor.mColor);
}


CColor::~CColor()
{
	CGColorRelease(mColor);
}


TColorComponent	CColor::GetRed() const
{
	if( !mColor )
		return 0.0;
	return CGColorGetComponents(mColor)[0] * 65535.0;
}


TColorComponent	CColor::GetGreen() const
{
	if( !mColor )
		return 0.0;
	return CGColorGetComponents(mColor)[1] * 65535.0;
}


TColorComponent	CColor::GetBlue() const
{
	if( !mColor )
		return 0.0;
	return CGColorGetComponents(mColor)[2] * 65535.0;
}


TColorComponent	CColor::GetAlpha() const
{
	if( !mColor )
		return 0.0;
	return CGColorGetComponents(mColor)[3] * 65535.0;
}


CColor& CColor::operator =( const CColor& inColor )
{
	if( mColor != inColor.mColor )
	{
		CGColorRelease(mColor);
		mColor = CGColorRetain(inColor.mColor);
	}
	
	return *this;
}


bool	CColor::operator ==( const CColor& inColor ) const
{
	const CGFloat * aComps = CGColorGetComponents(mColor);
	const CGFloat * bComps = CGColorGetComponents(inColor.mColor);
	return (fabs(aComps[0] - bComps[0]) < 0.001) && (fabs(aComps[1] - bComps[1]) < 0.001) && (fabs(aComps[2] - aComps[2]) < 0.001) && (fabs(aComps[3] - bComps[3]) < 0.001);
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
	

void	CPath::AddArcWithCenterRadiusStartAngleEndAngle( CPoint inCenterPoint, TCoordinate radius, double startAngle, double endAngle )
{
	CGPathAddArc( mBezierPath, NULL, inCenterPoint.GetH(), inCenterPoint.GetV(),
				 radius, startAngle, endAngle, true );
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


bool	CPath::IsEmpty() const
{
	return CGPathIsEmpty( mBezierPath );
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
	
	CGContextStrokeRect( mContext, inRect.mRect );
	
	ImageChanged();
}


void	CCanvas::FillRect( const CRect& inRect, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CGContextFillRect( mContext, inRect.mRect );
	
	ImageChanged();
}


void	CCanvas::ClearRect( const CRect& inRect )
{
	CGContextClearRect( mContext, inRect.mRect );
	
	ImageChanged();
}


void	CCanvas::StrokeOval( const CRect& inRect, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CGContextStrokeEllipseInRect( mContext, inRect.mRect );
	
	ImageChanged();
}


void	CCanvas::FillOval( const CRect& inRect, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CGContextFillEllipseInRect( mContext, inRect.mRect );
	
	ImageChanged();
}


void	CCanvas::StrokeRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CPath	roundRectPath;
	// Make sure radius doesn't exceed a maximum size to avoid artifacts:
	if( inCornerRadius >= (inRect.GetHeight() /2) )
		inCornerRadius = truncf(inRect.GetHeight() /2) -1;
	if( inCornerRadius >= (inRect.GetWidth() /2) )
		inCornerRadius = truncf(inRect.GetWidth() /2) -1;
	
	// Make sure silly values simply lead to un-rounded corners:
	if( inCornerRadius <= 0 )
	{
		StrokeRect( inRect, inState );
	}
	else
	{
		// Now draw our rectangle:
		CRect	innerRect = inRect;
		innerRect.Inset( inCornerRadius, inCornerRadius );	// Make rect with corners being centers of the corner circles.
		
		roundRectPath.MoveToPoint( CPoint(inRect.GetH(), inRect.GetV() +inCornerRadius) );
		
		// Bottom left (origin):
		roundRectPath.AddArcWithCenterRadiusStartAngleEndAngle( CPoint(innerRect.GetH(), innerRect.GetV()), inCornerRadius, 180.0, 270.0 );
		roundRectPath.LineToPoint( CPoint(innerRect.GetMaxH(), inRect.GetV()) ); // Bottom edge.
		
		// Bottom right:
		roundRectPath.AddArcWithCenterRadiusStartAngleEndAngle( CPoint(innerRect.GetMaxH(), innerRect.GetV()), inCornerRadius, 270.0, 360.0 );
		roundRectPath.LineToPoint( CPoint(inRect.GetMaxH(), innerRect.GetMaxV()) ); // Right edge.
		
		// Top right:
		roundRectPath.AddArcWithCenterRadiusStartAngleEndAngle( CPoint(innerRect.GetMaxH(), innerRect.GetMaxV()), inCornerRadius, 0.0, 90.0 );
		roundRectPath.LineToPoint( CPoint(innerRect.GetH(), inRect.GetMaxV()) ); // Top edge.
		
		// Top left:
		roundRectPath.AddArcWithCenterRadiusStartAngleEndAngle( CPoint(innerRect.GetH(), innerRect.GetMaxV()), inCornerRadius, 90.0, 180.0 );
		roundRectPath.LineToPoint( CPoint(inRect.GetH(), innerRect.GetV()) ); // Left edge.
		
		StrokePath( roundRectPath, inState );
	}
}


void	CCanvas::FillRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CPath	roundRectPath;
	// Make sure radius doesn't exceed a maximum size to avoid artifacts:
	if( inCornerRadius >= (inRect.GetHeight() /2) )
		inCornerRadius = truncf(inRect.GetHeight() /2) -1;
	if( inCornerRadius >= (inRect.GetWidth() /2) )
		inCornerRadius = truncf(inRect.GetWidth() /2) -1;
	
	// Make sure silly values simply lead to un-rounded corners:
	if( inCornerRadius <= 0 )
	{
		FillRect( inRect, inState );
	}
	else
	{
		// Now draw our rectangle:
		CRect	innerRect = inRect;
		innerRect.Inset( inCornerRadius, inCornerRadius );	// Make rect with corners being centers of the corner circles.
		
		roundRectPath.MoveToPoint( CPoint(inRect.GetH(), inRect.GetV() +inCornerRadius) );
		
		// Bottom left (origin):
		roundRectPath.AddArcWithCenterRadiusStartAngleEndAngle( CPoint(innerRect.GetH(), innerRect.GetV()), inCornerRadius, 180.0, 270.0 );
		roundRectPath.LineToPoint( CPoint(innerRect.GetMaxH(), inRect.GetV()) ); // Bottom edge.
		
		// Bottom right:
		roundRectPath.AddArcWithCenterRadiusStartAngleEndAngle( CPoint(innerRect.GetMaxH(), innerRect.GetV()), inCornerRadius, 270.0, 360.0 );
		roundRectPath.LineToPoint( CPoint(inRect.GetMaxH(), innerRect.GetMaxV()) ); // Right edge.
		
		// Top right:
		roundRectPath.AddArcWithCenterRadiusStartAngleEndAngle( CPoint(innerRect.GetMaxH(), innerRect.GetMaxV()), inCornerRadius, 0.0, 90.0 );
		roundRectPath.LineToPoint( CPoint(innerRect.GetH(), inRect.GetMaxV()) ); // Top edge.
		
		// Top left:
		roundRectPath.AddArcWithCenterRadiusStartAngleEndAngle( CPoint(innerRect.GetH(), innerRect.GetMaxV()), inCornerRadius, 90.0, 180.0 );
		roundRectPath.LineToPoint( CPoint(inRect.GetH(), innerRect.GetV()) ); // Left edge.
		
		FillPath( roundRectPath, inState );
	}
}


void	CCanvas::StrokeLineFromPointToPoint( const CPoint& inStart, const CPoint& inEnd, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CPath	linePath;
	linePath.MoveToPoint( inStart );
	linePath.LineToPoint( inEnd );
	StrokePath( linePath, inState );
}


CPath	CCanvas::RegularPolygon( const CPoint& centerPos, const CPoint& desiredCorner, TCoordinate numberOfCorners )
{
	CPath	thePath;
	CPoint	startPos;
	
	TCoordinate	delta_x = desiredCorner.GetH() - centerPos.GetH();
	TCoordinate	delta_y = desiredCorner.GetV() - centerPos.GetV();
	TCoordinate	startAngle = atan2(delta_y, delta_x);
	TCoordinate r = sqrt( pow(delta_x, 2) + pow(delta_y, 2) );
	TCoordinate angleAdvance = (M_PI * 2) / numberOfCorners;
	
	for( int x = 0; x < numberOfCorners; x++ )
	{
		TCoordinate	a = startAngle + angleAdvance * TCoordinate(x);
		CPoint	cornerPos( centerPos.GetH() + r * cos(a), centerPos.GetV() + r * sin(a) );
		if( x == 0 )
		{
			startPos = cornerPos;
			thePath.MoveToPoint( cornerPos );
		}
		else
		{
			thePath.LineToPoint( cornerPos );
		}
	}
	thePath.LineToPoint( startPos );
	
	return thePath;
}


void	CCanvas::StrokePath( const CPath& inPath, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CGContextAddPath( mContext, inPath.mBezierPath );
	CGContextStrokePath( mContext );
	
	ImageChanged();
}


void	CCanvas::FillPath( const CPath& inPath, const CGraphicsState& inState )
{
	ApplyGraphicsStateIfNeeded( inState );
	
	CGContextAddPath( mContext, inPath.mBezierPath );
	CGContextFillPath( mContext );
	
	ImageChanged();
}


void	CCanvas::DrawImageInRect( const CImageCanvas& inImage, const CRect& inBox )
{
	CGContextDrawImage( mContext, inBox.GetMacRect(), inImage.GetMacImage() );
	
	ImageChanged();
}


void	CCanvas::DrawImageAtPoint( const CImageCanvas& inImage, const CPoint& inPos )
{
	CGRect	theBox = { inPos.GetMacPoint(), inImage.GetSize().GetMacSize() };
	CGContextDrawImage( mContext, theBox, inImage.GetMacImage() );
	
	ImageChanged();
}


void	CCanvas::ApplyGraphicsStateIfNeeded( const CGraphicsState& inState )
{
	if( inState.mGraphicsStateSeed != mLastGraphicsStateSeed )
	{
		CGContextSetStrokeColorWithColor( mContext, inState.mLineColor.mColor );
		CGContextSetFillColorWithColor( mContext, inState.mFillColor.mColor );
		CGContextSetLineWidth( mContext, inState.mLineThickness );
		CGContextSetBlendMode( mContext, (CGBlendMode) inState.mCompositingMode );
		CGContextSetLineDash( mContext, 0.0, (inState.mLineDash.size() > 0) ? inState.mLineDash.data() : NULL, inState.mLineDash.size());
		
		mLastGraphicsStateSeed = inState.mGraphicsStateSeed;
	}
}


CMacCanvas::CMacCanvas( CGContextRef inContext, CGRect inBounds )
 : mBounds(inBounds)
{
	mContext = CGContextRetain(inContext);
}


CMacCanvas::~CMacCanvas()
{
	CGContextRelease(mContext);
}
	
void	CMacCanvas::BeginDrawing()
{
}


void	CMacCanvas::EndDrawing()
{
}


