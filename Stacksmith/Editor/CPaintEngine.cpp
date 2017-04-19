//
//  CPaintEngine.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CPaintEngine.h"
#include "UlisBresenham.h"


using namespace Carlson;


void	CPaintEngineTool::DrawCursorInCanvas( CCanvas& inCanvas, CPoint& outHotSpot )
{
	inCanvas.BeginDrawing();
	
		CGraphicsState	state;
		state.SetLineColor( GetPaintEngine()->GetLineColor() );
		CRect box = inCanvas.GetRect();
		inCanvas.StrokeLineFromPointToPoint( CPoint(box.GetH(),box.GetVCenter()), CPoint(box.GetMaxH(),box.GetVCenter()), state );
		inCanvas.StrokeLineFromPointToPoint( CPoint(box.GetHCenter(),box.GetV()), CPoint(box.GetHCenter(),box.GetMaxV()), state );
	
	inCanvas.EndDrawing();
	
	outHotSpot = CPoint( box.GetHCenter(), box.GetVCenter() );
}


void	CPaintEngine::MouseDownAtPoint( CPoint pos )
{
	if( mCurrentTool )
		mCurrentTool->MouseDownAtPoint( pos );
}


void	CPaintEngine::MouseDraggedToPoint( CPoint pos )
{
	if( mCurrentTool )
		mCurrentTool->MouseDraggedToPoint( pos );
}


void	CPaintEngine::MouseReleasedAtPoint( CPoint pos )
{
	if( mCurrentTool )
		mCurrentTool->MouseReleasedAtPoint( pos );
}


void	CPaintEngine::SetCurrentTool( CPaintEngineTool * inTool )
{
	mCurrentTool = inTool;
	mCurrentTool->SetPaintEngine( this );
}


