//
//  CPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CPart__
#define __Stacksmith__CPart__

#include "CConcreteObject.h"
#include "tinyxml2.h"


class CPart : public CConcreteObject
{
public:
	CPart( tinyxml2::XMLElement * inElement ) {};
	
	int		GetFamily()		{ return mFamily; };
	
protected:
	int			mFamily;
};


typedef CRefCountedObjectRef<CPart>		CPartRef;

#endif /* defined(__Stacksmith__CPart__) */
