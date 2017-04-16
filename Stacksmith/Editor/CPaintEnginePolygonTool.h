//
//  CPaintEnginePolygonTool.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CPaintEnginePolygonTool_hpp
#define CPaintEnginePolygonTool_hpp

#include "CPaintEngine.h"

namespace Carlson
{

class CPaintEnginePolygonTool : public CPaintEngineTool
{
public:
	virtual void	MouseReleasedAtPoint( CPoint pos ) override;

	virtual bool	WantsMouseMoved() override		{ return true; }
	virtual void	MouseMovedToPoint( CPoint pos ) override;

protected:
	CPath	mCurrentPath;
	CRect	mLastTrackingPathRect;
	CRect	mFirstPointBox;	//!< Used to detect when user closed the path.
	CRect	mLastPointBox;	//!< Used to detect when user double-licked to close the path.
};

} // namespace Carlson

#endif /* CPaintEnginePolygonTool_hpp */
