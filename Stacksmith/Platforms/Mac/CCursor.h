//
//  CCursor.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-12.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

/*! @class CCursor
	Platform-agnostic wrappers around mouse cursor and mouse-related platform-specific API.
*/

#ifndef __Stacksmith__CCursor__
#define __Stacksmith__CCursor__

#include "LEOValue.h"
#include <functional>

namespace Carlson
{

class CCursor
{
public:
	/*! Return the current mouse position in coordinates relative to the upper left of the (main) screen. */
	static void	GetGlobalPosition( LEONumber* outX, LEONumber *outY );
	
	/*! Synchronously track the mouse after a click until the mouse button is released again. Call us back whenever the mouse moves or the pressure changes. Button numbers are 0-based indexes: mouseButtonNumber == 0 is left, mouseButtonNumber == 1 is right, higher numbers mean other buttons. Coordinates are relative to the upper left of the (main) screen. If trackingHandler returns NO, tracking will be aborted. */
	static void	Grab( int mouseButtonNumber, std::function<bool( LEONumber x, LEONumber y, LEONumber pressure )> trackingHandler );
};

}

#endif /* defined(__Stacksmith__CCursor__) */
