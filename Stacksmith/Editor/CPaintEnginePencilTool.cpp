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
	self.GetPaintEngine()->GetCanvas()->FillOval( box, self.GetPaintEngine()->GetGraphicsState() );
}


void	CPaintEnginePencilTool::MouseDownAtPoint( CPoint pos )
{
	mPaintEngine->GetCanvas()->BeginDrawing();
	
		mLastColor = GetPaintEngine()->GetGraphicsState().GetLineColor();
		CColor	currentColor = mPaintEngine->GetCanvas()->ColorAtPosition( pos );
		if( currentColor == mLastColor )
		{
			GetPaintEngine()->SetLineColor( CColor(0,0,0,0) );
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
	
	GetPaintEngine()->SetLineColor( mLastColor );
}
