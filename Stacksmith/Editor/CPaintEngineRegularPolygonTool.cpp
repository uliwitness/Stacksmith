//
//  CPaintEngineRegularPolygonTool.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CPaintEngineRegularPolygonTool.h"


using namespace Carlson;


void	CPaintEngineRegularPolygonTool::MouseDownAtPoint( CPoint pos )
{
	mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
	
		mStartPosition = pos;
		CPath	polyPath = mPaintEngine->GetTemporaryCanvas()->RegularPolygon( mStartPosition, pos, 5 );
		if( mPaintEngine->GetGraphicsState().GetFillColor().GetAlpha() > 0 )
		{
			mPaintEngine->GetTemporaryCanvas()->FillPath( polyPath, mPaintEngine->GetGraphicsState() );
		}
		if( mPaintEngine->GetGraphicsState().GetLineThickness() > 0 )
		{
			mPaintEngine->GetTemporaryCanvas()->StrokePath( polyPath, mPaintEngine->GetGraphicsState() );
		}
		mLastTrackingRectangle = polyPath.GetSurroundingRect();
		mLastTrackingRectangle.Inset( -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1, -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.
	
	mPaintEngine->GetTemporaryCanvas()->EndDrawing();
}


void	CPaintEngineRegularPolygonTool::MouseDraggedToPoint( CPoint pos )
{
	mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
	
		mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );
		
		CPath	polyPath = mPaintEngine->GetTemporaryCanvas()->RegularPolygon( mStartPosition, pos, 5 );
		if( mPaintEngine->GetGraphicsState().GetFillColor().GetAlpha() > 0 )
		{
			mPaintEngine->GetTemporaryCanvas()->FillPath( polyPath, mPaintEngine->GetGraphicsState() );
		}
		if( mPaintEngine->GetGraphicsState().GetLineThickness() > 0 )
		{
			mPaintEngine->GetTemporaryCanvas()->StrokePath( polyPath, mPaintEngine->GetGraphicsState() );
		}
		mLastTrackingRectangle = polyPath.GetSurroundingRect();
		mLastTrackingRectangle.Inset( -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1, -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.

	mPaintEngine->GetTemporaryCanvas()->EndDrawing();
}


void	CPaintEngineRegularPolygonTool::MouseReleasedAtPoint( CPoint pos )
{
	mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
	
		mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );

	mPaintEngine->GetTemporaryCanvas()->EndDrawing();

	mPaintEngine->GetCanvas()->BeginDrawing();
	
		CPath	polyPath = mPaintEngine->GetCanvas()->RegularPolygon( mStartPosition, pos, 5 );
		if( mPaintEngine->GetGraphicsState().GetFillColor().GetAlpha() > 0 )
		{
			mPaintEngine->GetCanvas()->FillPath( polyPath, mPaintEngine->GetGraphicsState() );
		}
		if( mPaintEngine->GetGraphicsState().GetLineThickness() > 0 )
		{
			mPaintEngine->GetCanvas()->StrokePath( polyPath, mPaintEngine->GetGraphicsState() );
		}

	mPaintEngine->GetCanvas()->EndDrawing();
}
