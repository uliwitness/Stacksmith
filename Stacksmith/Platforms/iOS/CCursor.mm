//
//  CCursor.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-12.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CCursor.h"
#import <UIKit/UIKit.h>
#include <iostream>


using namespace Carlson;


void	CCursor::GetGlobalPosition( LEONumber* outX, LEONumber *outY )
{
	// TODO: Implement something UITouch-related for this
	
	*outX = 0;
	*outY = 0;
}


bool	CCursor::Grab( int mouseButtonNumber, std::function<bool( LEONumber x, LEONumber y, LEONumber pressure )> trackingHandler )
{
	// TODO: Implement something UITouch-related for this
	
	return false;
}
