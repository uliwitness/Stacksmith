//
//  CFieldPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CFieldPart__
#define __Stacksmith__CFieldPart__

#include "CPart.h"

namespace Calhoun {

class CFieldPart : public CPart
{
public:
	explicit CFieldPart( CLayer *inOwner ) : CPart( inOwner ) {};
	
protected:
	virtual const char*		GetIdentityForDump()	{ return "Field"; };
	virtual void			DumpProperties( size_t inIndent );
};

}

#endif /* defined(__Stacksmith__CFieldPart__) */
