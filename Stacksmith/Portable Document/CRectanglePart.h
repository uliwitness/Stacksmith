//
//  CRectanglePart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CRectanglePart__
#define __Stacksmith__CRectanglePart__

#include "CVisiblePart.h"

namespace Calhoun {

class CRectanglePart : public CVisiblePart
{
public:
	explicit CRectanglePart( CLayer *inOwner ) : CVisiblePart( inOwner ) {};
	
protected:
	virtual const char*		GetIdentityForDump()	{ return "Rectangle"; };
};

}

#endif /* defined(__Stacksmith__CRectanglePart__) */
