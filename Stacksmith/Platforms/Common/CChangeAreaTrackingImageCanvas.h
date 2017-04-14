//
//  CChangeAreaTrackingImageCanvas.h
//  Stacksmith
//
//  Created by Uli Kusterer on 02/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

/*
	A CImageCanvas in which cross-platform code can render
	and then the platform-specific code can find out which
	areas have changed and only mark those as needing to
	be redrawn.
*/

#ifndef ChangeAreaTrackingImage_h
#define ChangeAreaTrackingImage_h


#include "CImageCanvas.h"
#include <vector>


namespace Carlson {


class CChangeAreaTrackingImageCanvas : public CImageCanvas
{
public:
	virtual void	StrokeRect( const CRect& inRect, const CGraphicsState& inState )
	{
		CRect	dirtyBox( inRect );
		dirtyBox.Inset( -ceilf(inState.GetLineThickness() / 2.0), -ceilf(inState.GetLineThickness() / 2.0) );
		mDirtyRects.push_back( dirtyBox );
		CImageCanvas::StrokeRect( inRect, inState );
	}
	
	virtual void	FillRect( const CRect& inRect, const CGraphicsState& inState )
	{
		mDirtyRects.push_back( inRect );
		CImageCanvas::FillRect( inRect, inState );
	}
	
	virtual void	ClearRect( const CRect& inRect )
	{
		mDirtyRects.push_back( inRect );
		CImageCanvas::ClearRect( inRect );
	}
	
	virtual void	StrokeOval( const CRect& inRect, const CGraphicsState& inState )
	{
		CRect	dirtyBox( inRect );
		dirtyBox.Inset( -ceilf(inState.GetLineThickness() / 2.0), -ceilf(inState.GetLineThickness() / 2.0) );
		mDirtyRects.push_back( dirtyBox );
		CImageCanvas::StrokeOval( inRect, inState );
	}
	
	virtual void	FillOval( const CRect& inRect, const CGraphicsState& inState )
	{
		mDirtyRects.push_back( inRect );
		CImageCanvas::FillOval( inRect, inState );
	}
	
	virtual void	StrokeRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState )
	{
		CRect	dirtyBox( inRect );
		dirtyBox.Inset( -ceilf(inState.GetLineThickness() / 2.0), -ceilf(inState.GetLineThickness() / 2.0) );
		mDirtyRects.push_back( dirtyBox );
		CImageCanvas::StrokeRoundRect( inRect, inCornerRadius, inState );
	}

	virtual void	FillRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState )
	{
		mDirtyRects.push_back( inRect );
		CImageCanvas::FillRoundRect( inRect, inCornerRadius, inState );
	}

	virtual void	StrokeLineFromPointToPoint( const CPoint& inStart, const CPoint& inEnd, const CGraphicsState& inState )
	{
		CRect lineBox( CRect::RectAroundPoints( inStart, inEnd ) );
		lineBox.Inset( -ceilf(inState.GetLineThickness() / 2.0), -ceilf(inState.GetLineThickness() / 2.0) );
		mDirtyRects.push_back( lineBox );
		CImageCanvas::StrokeLineFromPointToPoint( inStart, inEnd, inState );
	}

	virtual void	StrokePath( const CPath& inPath, const CGraphicsState& inState )
	{
		CRect	dirtyBox( inPath.GetSurroundingRect() );
		dirtyBox.Inset( -ceilf(inState.GetLineThickness() / 2.0), -ceilf(inState.GetLineThickness() / 2.0) );
		mDirtyRects.push_back( dirtyBox );
		CImageCanvas::StrokePath( inPath, inState );
	}

	virtual void	FillPath( const CPath& inPath, const CGraphicsState& inState )
	{
		mDirtyRects.push_back( inPath.GetSurroundingRect() );
		CImageCanvas::FillPath( inPath, inState );
	}

	virtual void	DrawImageInRect( const CImageCanvas& inImage, const CRect& inBox )
	{
		mDirtyRects.push_back( inBox );
		CImageCanvas::DrawImageInRect( inImage, inBox );
	}

	virtual void	DrawImageAtPoint( const CImageCanvas& inImage, const CPoint& inPos )
	{
		CRect	imageBox;
		imageBox.SetOrigin(inPos);
		imageBox.SetSize( inImage.GetSize() );
		mDirtyRects.push_back( imageBox );
		CImageCanvas::DrawImageAtPoint( inImage, inPos );
	}
	
	virtual const std::vector<CRect>&	GetDirtyRects()		{ return mDirtyRects; }
	virtual void						ClearDirtyRects()	{ mDirtyRects.clear(); }
	
protected:
	std::vector<CRect>	mDirtyRects;
};

} /* namespace Carlson */

#endif /* CChangeAreaTrackingImageCanvas_h */
