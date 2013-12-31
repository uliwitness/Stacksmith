//
//  CPartContents.h
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CPartContents__
#define __Stacksmith__CPartContents__

#include "CRefCountedObject.h"
#include "tinyxml2.h"


class CPartContents : public CRefCountedObject
{
public:
	CPartContents( tinyxml2::XMLElement * inElement ) {};
};


typedef CRefCountedObjectRef<CPartContents>		CPartContentsRef;

#endif /* defined(__Stacksmith__CPartContents__) */
