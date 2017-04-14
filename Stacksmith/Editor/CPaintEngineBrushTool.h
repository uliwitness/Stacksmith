//
//  CPaintEngineBrushTool.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CPaintEngineBrushTool_hpp
#define CPaintEngineBrushTool_hpp

#include "CPaintEngine.h"

namespace Carlson
{

class CPaintEngineBrushTool : public CPaintEngineTool
{
public:
	virtual void	MouseDownAtPoint( CPoint pos ) override;
	virtual void	MouseDraggedToPoint( CPoint pos ) override;
	
protected:
	static void		DrawOneBresenhamPixel( float h, float v, void* inUserData );
	
	CPoint			mLastMousePos;
};

} // namespace Carlson

#endif /* CPaintEngineBrushTool_hpp */
