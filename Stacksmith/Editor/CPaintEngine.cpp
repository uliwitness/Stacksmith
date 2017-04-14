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
