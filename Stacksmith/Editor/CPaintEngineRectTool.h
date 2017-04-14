//
//  CPaintEngineRectTool.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CPaintEngineRectTool_hpp
#define CPaintEngineRectTool_hpp

#include "CPaintEngine.h"

namespace Carlson
{

class CPaintEngineRectTool : public CPaintEngineTool
{
public:
	virtual void	MouseDownAtPoint( CPoint pos ) override;
	virtual void	MouseDraggedToPoint( CPoint pos ) override;
	virtual void	MouseReleasedAtPoint( CPoint pos ) override;

protected:
	CPoint	mStartPosition;
	CRect	mLastTrackingRectangle;
};

} // namespace Carlson

#endif /* CPaintEngineRectTool_hpp */
