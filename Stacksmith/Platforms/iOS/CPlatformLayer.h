//
//  CPlatformLayer.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-16.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef Stacksmith_CPlatformLayer_h
#define Stacksmith_CPlatformLayer_h

#include "CLayer.h"


namespace Carlson
{

/*!
	@class CPlatformLayer
	iOS-specific subclass of CLayer that contains code that we want both
	kinds of layer, cards and backgrounds, to have.
*/

class CPlatformLayer : public CLayer
{
public:
	CPlatformLayer( std::string inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CStack* inStack ) : CLayer( inURL, inID, inName, inFileName, inStack ) {}
};

}

#endif
