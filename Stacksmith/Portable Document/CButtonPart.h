//
//  CButtonPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CButtonPart__
#define __Stacksmith__CButtonPart__

#include "CPart.h"

namespace Calhoun {

class CButtonPart : public CPart
{
public:
	explicit CButtonPart( CLayer *inOwner ) : CPart( inOwner ) {};
	
protected:
	virtual const char*		GetIdentityForDump()	{ return "Button"; };
	virtual void			DumpProperties( size_t inIndent );
};

}

#endif /* defined(__Stacksmith__CButtonPart__) */
