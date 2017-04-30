//
//  CPaintEngineSelectionRectTool.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CPaintEngineSelectionRectTool_hpp
#define CPaintEngineSelectionRectTool_hpp

#include "CPaintEngine.h"
#include "CImageCanvas.h"

namespace Carlson
{

class CPaintEngineSelectionRectTool : public CPaintEngineTool
{
public:
	CPaintEngineSelectionRectTool() : CPaintEngineTool() { mSelectedState.SetLineDash( { 3, 3 } ); }

	virtual void	MouseDownAtPoint( CPoint pos ) override;
	virtual void	MouseDraggedToPoint( CPoint pos ) override;
	virtual void	MouseReleasedAtPoint( CPoint pos ) override;

protected:
	CPoint			mStartPosition;
	CRect			mLastTrackingRectangle;
	CGraphicsState	mSelectedState;						// Dashed line pattern for drawing our selection rectangle.
	CPoint			mFloatingSelectionStartPosition;	//!< Where selection came from so we can move it relative to mStartPosition.
	CPoint			mFloatingSelectionPosition;			//!< Where floating selection currently is.
	CImageCanvas	mFloatingSelectionContents;			//!< The image at mFloatingSelectionStartPosition that we're moving around (or if we're opening a new selection, an image where IsInvalid() == false.
};

} // namespace Carlson

#endif /* CPaintEngineSelectionRectTool_hpp */
