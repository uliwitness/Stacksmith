//
//  CPaintEngine.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CPaintEngine_hpp
#define CPaintEngine_hpp

#include "CCanvas.h"


namespace Carlson {

class CPaintEngine
{
public:
	CPaintEngine( CCanvas * inCanvas = nullptr ) : mCanvas(inCanvas) {}
	
	void	SetCanvas( CCanvas * inCanvas )		{ mCanvas = inCanvas; }
	
	void	MouseDownAtPoint( CPoint pos );
	void	MouseDraggedToPoint( CPoint pos );
	void	MouseReleasedAtPoint( CPoint pos );
	
	void	SetLineColor( CColor inColor )	{ mGraphicsState.SetLineColor( inColor ); }
	CColor	GetLineColor()					{ return mGraphicsState.GetLineColor(); }
	
	void	SetFillColor( CColor inColor )	{ mGraphicsState.SetFillColor( inColor ); }
	CColor	GetFillColor()					{ return mGraphicsState.GetFillColor(); }
	
protected:
	static void	DrawOneBresenhamPixel( float h, float v, void* inUserData );

	CCanvas		*		mCanvas;
	CGraphicsState		mGraphicsState;
	CPoint				mLastMousePos;
};

} /* namespace Carlson */

#endif /* CPaintEngine_hpp */
