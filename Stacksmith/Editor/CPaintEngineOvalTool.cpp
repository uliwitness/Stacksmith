//
//  CPaintEngineOvalTool.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CPaintEngineOvalTool.h"


using namespace Carlson;


void	CPaintEngineOvalTool::MouseDownAtPoint( CPoint pos )
{
	mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
	
		mStartPosition = pos;
		CRect	box( CRect::RectAroundPoints( mStartPosition, pos ) );
		mPaintEngine->GetTemporaryCanvas()->FillOval( box, mPaintEngine->GetGraphicsState() );
		mLastTrackingRectangle = box;
		mLastTrackingRectangle.Inset( -1, -1 );	// Oval might draw anti-aliasing a tad outside the rectangle.
	
	mPaintEngine->GetTemporaryCanvas()->EndDrawing();
}


void	CPaintEngineOvalTool::MouseDraggedToPoint( CPoint pos )
{
	mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
	
		mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );
		
		CRect	box( CRect::RectAroundPoints( mStartPosition, pos ) );
		mPaintEngine->GetTemporaryCanvas()->FillOval( box, mPaintEngine->GetGraphicsState() );
		mLastTrackingRectangle = box;
		mLastTrackingRectangle.Inset( -1, -1 );	// Oval might draw anti-aliasing a tad outside the rectangle.

	mPaintEngine->GetTemporaryCanvas()->EndDrawing();
}


void	CPaintEngineOvalTool::MouseReleasedAtPoint( CPoint pos )
{
	mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
	
		mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );

	mPaintEngine->GetTemporaryCanvas()->EndDrawing();

	mPaintEngine->GetCanvas()->BeginDrawing();
	
		CRect	box( CRect::RectAroundPoints( mStartPosition, pos ) );
		mPaintEngine->GetCanvas()->FillOval( box, mPaintEngine->GetGraphicsState() );

	mPaintEngine->GetCanvas()->EndDrawing();
}
