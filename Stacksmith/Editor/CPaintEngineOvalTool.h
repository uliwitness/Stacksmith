//
//  CPaintEngineOvalTool.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CPaintEngineOvalTool_hpp
#define CPaintEngineOvalTool_hpp

#include "CPaintEngine.h"

namespace Carlson
{

class CPaintEngineOvalTool : public CPaintEngineTool
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

#endif /* CPaintEngineOvalTool_hpp */
