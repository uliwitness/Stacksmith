//
//  CConcreteObject.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CConcreteObject__
#define __Stacksmith__CConcreteObject__

#include "CRefCountedObject.h"

class CConcreteObject : public CRefCountedObject
{
public:
	
};

typedef CRefCountedObjectRef<CConcreteObject>	CConcreteObjectRef;

#endif /* defined(__Stacksmith__CConcreteObject__) */
