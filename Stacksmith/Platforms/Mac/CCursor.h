//
//  CCursor.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-12.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CCursor__
#define __Stacksmith__CCursor__

#include "LEOValue.h"
#include <functional>

class CCursor
{
public:
	static void	GetGlobalPosition( LEONumber* outX, LEONumber *outY );
	static void	Grab( std::function<void()> trackingHandler );
};

#endif /* defined(__Stacksmith__CCursor__) */
