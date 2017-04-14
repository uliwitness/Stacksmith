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


/*static*/ void	CPaintEngine::DrawOneBresenhamPixel( float h, float v, void* inUserData )
{
	CPaintEngine	&	self = *(CPaintEngine*)inUserData;
	
	CRect			box( CPoint(h,v), CSize(0,0) );
	box.Inset( -8, -8 );
	self.mCanvas->FillOval( box, self.mGraphicsState );
}


void	CPaintEngine::MouseDownAtPoint( CPoint pos )
{
	mCanvas->BeginDrawing();
	
		DrawOneBresenhamPixel( pos.GetH(), pos.GetV(), this );
		mLastMousePos = pos;

	mCanvas->EndDrawing();
}


void	CPaintEngine::MouseDraggedToPoint( CPoint pos )
{
	mCanvas->BeginDrawing();
	
		DrawBresenhamLine( mLastMousePos.GetH(), mLastMousePos.GetV(),
							pos.GetH(), pos.GetV(),
							DrawOneBresenhamPixel, this );

		mLastMousePos = pos;

	mCanvas->EndDrawing();
}


void	CPaintEngine::MouseReleasedAtPoint( CPoint pos )
{
	
}
