//
//  CPaintEnginePencilTool.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CPaintEnginePencilTool.h"
#include "UlisBresenham.h"


using namespace Carlson;


/*static*/ void	CPaintEnginePencilTool::DrawOneBresenhamPixel( float h, float v, void* inUserData )
{
	CPaintEnginePencilTool	&	self = *(CPaintEnginePencilTool*)inUserData;
	
	CRect			box( CPoint(h,v), CSize(1,1) );
	self.GetPaintEngine()->GetCanvas()->FillRect( box, self.GetPaintEngine()->GetGraphicsState() );
}


void	CPaintEnginePencilTool::MouseDownAtPoint( CPoint pos )
{
	mPaintEngine->GetCanvas()->BeginDrawing();
	
		mLastColor = GetPaintEngine()->GetGraphicsState().GetFillColor();
		mLastCompositingMode = GetPaintEngine()->GetGraphicsState().GetCompositingMode();
	
		CColor	currentColor = mPaintEngine->GetCanvas()->ColorAtPosition( pos );
		if( currentColor == mLastColor )
		{
			GetPaintEngine()->SetFillColor( CColor(0,0,0,0) );
			GetPaintEngine()->SetCompositingMode( ECompositingModeCopy );
		}
		DrawOneBresenhamPixel( pos.GetH(), pos.GetV(), this );
		mLastMousePos = pos;

	mPaintEngine->GetCanvas()->EndDrawing();
}


void	CPaintEnginePencilTool::MouseDraggedToPoint( CPoint pos )
{
	mPaintEngine->GetCanvas()->BeginDrawing();
	
		DrawBresenhamLine( mLastMousePos.GetH(), mLastMousePos.GetV(),
							pos.GetH(), pos.GetV(),
							DrawOneBresenhamPixel, this );

		mLastMousePos = pos;

	mPaintEngine->GetCanvas()->EndDrawing();
	}


void	CPaintEnginePencilTool::MouseReleasedAtPoint( CPoint pos )
{
	mPaintEngine->GetCanvas()->BeginDrawing();
	
		DrawBresenhamLine( mLastMousePos.GetH(), mLastMousePos.GetV(),
							pos.GetH(), pos.GetV(),
							DrawOneBresenhamPixel, this );

		mLastMousePos = pos;

	mPaintEngine->GetCanvas()->EndDrawing();
	
	GetPaintEngine()->SetFillColor( mLastColor );
	GetPaintEngine()->SetCompositingMode( mLastCompositingMode );
}
