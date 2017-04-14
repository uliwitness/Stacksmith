//
//  CPaintEngineRoundRectTool.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CPaintEngineRoundRectTool_hpp
#define CPaintEngineRoundRectTool_hpp

#include "CPaintEngine.h"

namespace Carlson
{

class CPaintEngineRoundRectTool : public CPaintEngineTool
{
public:
	virtual void	MouseDownAtPoint( CPoint pos ) override;
	virtual void	MouseDraggedToPoint( CPoint pos ) override;
	virtual void	MouseReleasedAtPoint( CPoint pos ) override;
	
	void			SetCornerRadius( TCoordinate inCornerRadius ) { mCornerRadius = inCornerRadius; }
	TCoordinate		GetCornerRadius() { return mCornerRadius; }
	
protected:
	CPoint		mStartPosition;
	CRect		mLastTrackingRectangle;
	TCoordinate	mCornerRadius = 8;
};

} // namespace Carlson

#endif /* CPaintEngineRoundRectTool_hpp */
