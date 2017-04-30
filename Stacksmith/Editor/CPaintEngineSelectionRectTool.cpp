//
//  CPaintEngineSelectionRectTool.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CPaintEngineSelectionRectTool.h"
#include "CImageCanvas.h"


using namespace Carlson;


void	CPaintEngineSelectionRectTool::MouseDownAtPoint( CPoint pos )
{
	mStartPosition = pos;
	
	if( !mFloatingSelectionContents.IsValid() || !mLastTrackingRectangle.ContainsPoint( pos ) )
	{
		if( mFloatingSelectionContents.IsValid() )
		{
			CRect	selectedBox( mFloatingSelectionContents.GetRect() );
			selectedBox.Offset( mFloatingSelectionPosition.GetH(), mFloatingSelectionPosition.GetV() );
		
			mPaintEngine->GetCanvas()->BeginDrawing();
				mPaintEngine->GetCanvas()->DrawImageInRect( mFloatingSelectionContents, selectedBox  );
			mPaintEngine->GetCanvas()->EndDrawing();

			mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
				mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );
			mPaintEngine->GetTemporaryCanvas()->EndDrawing();

			mFloatingSelectionContents = CImageCanvas();
		}
		
		mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
		
			CRect	box( CRect::RectAroundPoints( mStartPosition, pos ) );
			mPaintEngine->GetTemporaryCanvas()->StrokeRect( box, mSelectedState );
			mLastTrackingRectangle = box;
			mLastTrackingRectangle.Inset( -ceilf(mSelectedState.GetLineThickness() / 2.0) -1, -ceilf(mSelectedState.GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.
		
		mPaintEngine->GetTemporaryCanvas()->EndDrawing();
	}
}


void	CPaintEngineSelectionRectTool::MouseDraggedToPoint( CPoint pos )
{
	if( !mFloatingSelectionContents.IsValid() )
	{
		mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
		
			mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );
			
			CRect	box( CRect::RectAroundPoints( mStartPosition, pos ) );
			mPaintEngine->GetTemporaryCanvas()->StrokeRect( box, mSelectedState );
			mLastTrackingRectangle = box;
			mLastTrackingRectangle.Inset( -ceilf(mSelectedState.GetLineThickness() / 2.0) -1, -ceilf(mSelectedState.GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.

		mPaintEngine->GetTemporaryCanvas()->EndDrawing();
	}
	else
	{
		mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
		
			mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );
			
			CRect	selectedBox( mFloatingSelectionStartPosition, mFloatingSelectionContents.GetSize() );
			selectedBox.Offset( pos.GetH() -mStartPosition.GetH(), pos.GetV() -mStartPosition.GetV() );
		
			mPaintEngine->GetTemporaryCanvas()->DrawImageInRect( mFloatingSelectionContents, selectedBox  );
			mPaintEngine->GetTemporaryCanvas()->StrokeRect( selectedBox, mSelectedState );
			mFloatingSelectionPosition = selectedBox.GetOrigin();

			mLastTrackingRectangle = selectedBox;
			mLastTrackingRectangle.Inset( -ceilf(mSelectedState.GetLineThickness() / 2.0) -1, -ceilf(mSelectedState.GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.

		mPaintEngine->GetTemporaryCanvas()->EndDrawing();
	}
}


void	CPaintEngineSelectionRectTool::MouseReleasedAtPoint( CPoint pos )
{
	if( !mFloatingSelectionContents.IsValid() )
	{
		mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
		
			mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );

			CRect	box( CRect::RectAroundPoints( mStartPosition, pos ) );
			mFloatingSelectionStartPosition = box.GetOrigin();

			mFloatingSelectionContents = mPaintEngine->GetCanvas()->GetImageForRect( box );
			mPaintEngine->GetTemporaryCanvas()->DrawImageInRect( mFloatingSelectionContents, box  );
			mPaintEngine->GetTemporaryCanvas()->StrokeRect( box, mSelectedState );

		mPaintEngine->GetTemporaryCanvas()->EndDrawing();

		mPaintEngine->GetCanvas()->BeginDrawing();
		
			mPaintEngine->GetCanvas()->ClearRect( box );
		
		mPaintEngine->GetCanvas()->EndDrawing();
	}
	else
	{
		mPaintEngine->GetTemporaryCanvas()->BeginDrawing();
		
			mPaintEngine->GetTemporaryCanvas()->ClearRect( mLastTrackingRectangle );
			
			CRect	selectedBox( mFloatingSelectionStartPosition, mFloatingSelectionContents.GetSize() );
			selectedBox.Offset( pos.GetH() -mStartPosition.GetH(), pos.GetV() -mStartPosition.GetV() );
		
			mPaintEngine->GetTemporaryCanvas()->DrawImageInRect( mFloatingSelectionContents, selectedBox  );
			mPaintEngine->GetTemporaryCanvas()->StrokeRect( selectedBox, mSelectedState );
			mFloatingSelectionPosition = selectedBox.GetOrigin();

			mLastTrackingRectangle = selectedBox;
			mLastTrackingRectangle.Inset( -ceilf(mSelectedState.GetLineThickness() / 2.0) -1, -ceilf(mSelectedState.GetLineThickness() / 2.0) -1 );	// Line width, plus oval might draw anti-aliasing a tad outside the rectangle.

		mPaintEngine->GetTemporaryCanvas()->EndDrawing();
	}
}
