//
//  CPaintEnginePolygonTool.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CPaintEnginePolygonTool.h"


using namespace Carlson;


void	CPaintEnginePolygonTool::MouseReleasedAtPoint( CPoint pos )
{
	bool	shouldCommitPath = false;
	if( mCurrentPath.IsEmpty() )
	{
		mCurrentPath.MoveToPoint( pos );
		mLastTrackingPathRect = CRect(pos,CSize(0,0));
		TCoordinate lineThickness = mPaintEngine->GetGraphicsState().GetLineThickness();
		mLastTrackingPathRect.Inset( -ceil(lineThickness / 2.0), -ceil(lineThickness / 2.0) );
		mFirstPointBox = CRect(pos,CSize(0,0));
		mFirstPointBox.Inset(-2,-2);
		mLastPointBox = CRect(pos,CSize(0,0));
		mLastPointBox.Inset(-2,-2);
	}
	else if( mLastPointBox.ContainsPoint(pos) )
	{
		shouldCommitPath = true;
		
	}
	else if( mFirstPointBox.ContainsPoint(pos) )
	{
		shouldCommitPath = true;
		mCurrentPath.LineToPoint( pos );
	}
	else
	{
		mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
		
			mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingPathRect );
			mCurrentPath.LineToPoint( pos );

			if( mPaintEngine->GetGraphicsState().GetFillColor().GetAlpha() > 0 )
			{
				mPaintEngine->GetTemporaryCanvas()->FillPath( mCurrentPath, mPaintEngine->GetGraphicsState() );
			}
			if( mPaintEngine->GetGraphicsState().GetLineThickness() > 0 )
			{
				mPaintEngine->GetTemporaryCanvas()->StrokePath( mCurrentPath, mPaintEngine->GetGraphicsState() );
			}
		
			mLastTrackingPathRect = mCurrentPath.GetSurroundingRect();
			mLastTrackingPathRect.Inset( -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1, -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.
			mLastPointBox = CRect(pos,CSize(0,0));
			mLastPointBox.Inset(-2,-2);

		mPaintEngine->GetTemporaryCanvas()->EndDrawing();
	}
	
	if( shouldCommitPath )
	{
		mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
			mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingPathRect );
		mPaintEngine->GetTemporaryCanvas()->EndDrawing();
		
		mPaintEngine->GetCanvas()->BeginDrawing();
		
			mCurrentPath.LineToPoint( pos );

			if( mPaintEngine->GetGraphicsState().GetFillColor().GetAlpha() > 0 )
			{
				mPaintEngine->GetCanvas()->FillPath( mCurrentPath, mPaintEngine->GetGraphicsState() );
			}
			if( mPaintEngine->GetGraphicsState().GetLineThickness() > 0 )
			{
				mPaintEngine->GetCanvas()->StrokePath( mCurrentPath, mPaintEngine->GetGraphicsState() );
			}
		
			mLastTrackingPathRect = CRect();
			mLastPointBox = CRect();
			mCurrentPath = CPath();

		mPaintEngine->GetCanvas()->EndDrawing();
	}
}


void	CPaintEnginePolygonTool::MouseMovedToPoint( CPoint pos )
{
	if( !mCurrentPath.IsEmpty() )
	{
		CPath	tempPath = mCurrentPath;
		
		mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
		
			mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingPathRect );
			tempPath.LineToPoint( pos );

			if( mPaintEngine->GetGraphicsState().GetFillColor().GetAlpha() > 0 )
			{
				mPaintEngine->GetTemporaryCanvas()->FillPath( tempPath, mPaintEngine->GetGraphicsState() );
			}
			if( mPaintEngine->GetGraphicsState().GetLineThickness() > 0 )
			{
				mPaintEngine->GetTemporaryCanvas()->StrokePath( tempPath, mPaintEngine->GetGraphicsState() );
			}
			mLastTrackingPathRect = tempPath.GetSurroundingRect();
			mLastTrackingPathRect.Inset( -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1, -ceilf(mPaintEngine->GetGraphicsState().GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.

		mPaintEngine->GetTemporaryCanvas()->EndDrawing();
	}
}
