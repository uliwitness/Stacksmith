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

class CPaintEngine;

class CPaintEngineTool
{
public:
	virtual ~CPaintEngineTool()	{}
	
	void				SetPaintEngine( CPaintEngine * inEngine )	{ mPaintEngine = inEngine; }	// CPaintEngine calls this on a tool before it starts drawing.
	CPaintEngine	*	GetPaintEngine()							{ return mPaintEngine; }
	
	virtual void	MouseDownAtPoint( CPoint pos ) {}
	virtual void	MouseDraggedToPoint( CPoint pos ) {}
	virtual void	MouseReleasedAtPoint( CPoint pos ) {}

protected:
	CPaintEngine	*	mPaintEngine = nullptr;
};


class CPaintEngine
{
public:
	CPaintEngine() { mCanvas = nullptr; mTemporaryCanvas = nullptr; mCurrentTool = nullptr; }
	
	/*! This canvas contains the result of the user's drawings. */
	void		SetCanvas( CCanvas * inCanvas )			{ mCanvas = inCanvas; }
	CCanvas	*	GetCanvas()								{ return mCanvas; }
	/*! The temporary canvas is the one in which e.g. a rectangle is drawn and re-drawn until the mouse is released. It is erased between mouse events, and drawn on top of the actual canvas. */
	void		SetTemporaryCanvas( CCanvas * inCanvas ){ mTemporaryCanvas = inCanvas; }
	CCanvas	*	GetTemporaryCanvas()					{ return mTemporaryCanvas; }
	
	void	MouseDownAtPoint( CPoint pos );
	void	MouseDraggedToPoint( CPoint pos );
	void	MouseReleasedAtPoint( CPoint pos );
	
	void	SetLineColor( CColor inColor )	{ mGraphicsState.SetLineColor( inColor ); }
	CColor	GetLineColor()					{ return mGraphicsState.GetLineColor(); }
	
	void	SetFillColor( CColor inColor )	{ mGraphicsState.SetFillColor( inColor ); }
	CColor	GetFillColor()					{ return mGraphicsState.GetFillColor(); }
	
	void		SetLineThickness( TCoordinate inThickness )	{ mGraphicsState.SetLineThickness( inThickness ); }
	TCoordinate	GetLineThickness() const					{ return mGraphicsState.GetLineThickness(); }

	const CGraphicsState	&	GetGraphicsState()		{ return mGraphicsState; }
	
	void	SetCurrentTool( CPaintEngineTool * inTool );
	
	
protected:
	CCanvas			*		mCanvas = nullptr;			// Unowned pointer.
	CCanvas			*		mTemporaryCanvas = nullptr;	// Unowned pointer.
	CGraphicsState			mGraphicsState;
	CPoint					mLastMousePos;
	CPaintEngineTool	*	mCurrentTool = nullptr;		// Unowned pointer.
};

} /* namespace Carlson */

#endif /* CPaintEngine_hpp */
