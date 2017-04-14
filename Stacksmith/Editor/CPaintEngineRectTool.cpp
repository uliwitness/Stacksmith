//
//  CPaintEngineRectTool.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CPaintEngineRectTool.h"


using namespace Carlson;


void	CPaintEngineRectTool::MouseDownAtPoint( CPoint pos )
{
	mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
	
		mStartPosition = pos;
		CRect	box( CRect::RectAroundPoints( mStartPosition, pos ) );
		if( mPaintEngine->GetGraphicsState().GetFillColor().GetAlpha() > 0 )
		{
			mPaintEngine->GetTemporaryCanvas()->FillRect( box, mPaintEngine->GetGraphicsState() );
		}
		if( mPaintEngine->GetGraphicsState().GetLineThickness() > 0 )
		{
			mPaintEngine->GetTemporaryCanvas()->StrokeRect( box, mPaintEngine->GetGraphicsState() );
		}
		mLastTrackingRectangle = box;
		mLastTrackingRectangle.Inset( -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1, -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.
	
	mPaintEngine->GetTemporaryCanvas()->EndDrawing();
}


void	CPaintEngineRectTool::MouseDraggedToPoint( CPoint pos )
{
	mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
	
		mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );
		
		CRect	box( CRect::RectAroundPoints( mStartPosition, pos ) );
		if( mPaintEngine->GetGraphicsState().GetFillColor().GetAlpha() > 0 )
		{
			mPaintEngine->GetTemporaryCanvas()->FillRect( box, mPaintEngine->GetGraphicsState() );
		}
		if( mPaintEngine->GetGraphicsState().GetLineThickness() > 0 )
		{
			mPaintEngine->GetTemporaryCanvas()->StrokeRect( box, mPaintEngine->GetGraphicsState() );
		}
		mLastTrackingRectangle = box;
		mLastTrackingRectangle.Inset( -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1, -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.

	mPaintEngine->GetTemporaryCanvas()->EndDrawing();
}


void	CPaintEngineRectTool::MouseReleasedAtPoint( CPoint pos )
{
	mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
	
		mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );

	mPaintEngine->GetTemporaryCanvas()->EndDrawing();

	mPaintEngine->GetCanvas()->BeginDrawing();
	
		CRect	box( CRect::RectAroundPoints( mStartPosition, pos ) );
	
		if( mPaintEngine->GetGraphicsState().GetFillColor().GetAlpha() > 0 )
		{
			mPaintEngine->GetCanvas()->FillRect( box, mPaintEngine->GetGraphicsState() );
		}
		if( mPaintEngine->GetGraphicsState().GetLineThickness() > 0 )
		{
			mPaintEngine->GetCanvas()->StrokeRect( box, mPaintEngine->GetGraphicsState() );
		}

	mPaintEngine->GetCanvas()->EndDrawing();
}
