//
//  TTool.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-02-28.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__TTool__
#define __Stacksmith__TTool__

#include <stdint.h>


namespace Carlson {


enum
{
	EBrowseTool = 0,
	EPointerTool,
	EEditTextTool,
	EOvalTool,
	ERectangleTool,
	ERoundrectTool,
	ETool_Last
};
typedef uint16_t	TTool;


}

#endif /* defined(__Stacksmith__TTool__) */
