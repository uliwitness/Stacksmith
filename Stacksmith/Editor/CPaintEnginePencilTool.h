//
//  CPaintEnginePencilTool.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CPaintEnginePencilTool_hpp
#define CPaintEnginePencilTool_hpp

#include "CPaintEngine.h"

namespace Carlson
{

class CPaintEnginePencilTool : public CPaintEngineTool
{
public:
	virtual void	MouseDownAtPoint( CPoint pos ) override;
	virtual void	MouseDraggedToPoint( CPoint pos ) override;
	virtual void	MouseReleasedAtPoint( CPoint pos ) override;
	
protected:
	static void		DrawOneBresenhamPixel( float h, float v, void* inUserData );
	
	CPoint				mLastMousePos;
	CColor				mLastColor;
	TCompositingMode	mLastCompositingMode;
};

} // namespace Carlson

#endif /* CPaintEnginePencilTool_hpp */
