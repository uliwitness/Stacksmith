//
//  CWebBrowserPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CWebBrowserPart__
#define __Stacksmith__CWebBrowserPart__

#include "CPart.h"

namespace Calhoun {

class CWebBrowserPart : public CPart
{
public:
	explicit CWebBrowserPart( CLayer *inOwner ) : CPart( inOwner ) {};
	
protected:
	virtual const char*		GetIdentityForDump()	{ return "Web Browser"; };
	virtual void			DumpProperties( size_t inIndent );
};

}

#endif /* defined(__Stacksmith__CWebBrowserPart__) */
