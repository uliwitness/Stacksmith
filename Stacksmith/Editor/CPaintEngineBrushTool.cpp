//
//  CPaintEngineBrushTool.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CPaintEngineBrushTool.h"
#include "UlisBresenham.h"


using namespace Carlson;


/*static*/ void	CPaintEngineBrushTool::DrawOneBresenhamPixel( float h, float v, void* inUserData )
{
	CPaintEngineBrushTool	&	self = *(CPaintEngineBrushTool*)inUserData;
	
	CRect			box( CPoint(h,v), CSize(0,0) );
	box.Inset( -8, -8 );
	self.GetPaintEngine()->GetCanvas()->FillOval( box, self.GetPaintEngine()->GetGraphicsState() );
}


void	CPaintEngineBrushTool::MouseDownAtPoint( CPoint pos )
{
	mPaintEngine->GetCanvas()->BeginDrawing();
	
		DrawOneBresenhamPixel( pos.GetH(), pos.GetV(), this );
		mLastMousePos = pos;

	mPaintEngine->GetCanvas()->EndDrawing();
}


void	CPaintEngineBrushTool::MouseDraggedToPoint( CPoint pos )
{
	mPaintEngine->GetCanvas()->BeginDrawing();
	
		DrawBresenhamLine( mLastMousePos.GetH(), mLastMousePos.GetV(),
							pos.GetH(), pos.GetV(),
							DrawOneBresenhamPixel, this );

		mLastMousePos = pos;

	mPaintEngine->GetCanvas()->EndDrawing();
}
