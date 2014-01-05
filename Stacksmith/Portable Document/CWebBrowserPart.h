//
//  CWebBrowserPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CWebBrowserPart__
#define __Stacksmith__CWebBrowserPart__

#include "CVisiblePart.h"

namespace Carlson {

class CWebBrowserPart : public CVisiblePart
{
public:
	explicit CWebBrowserPart( CLayer *inOwner ) : CVisiblePart( inOwner ) {};
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	
	virtual const char*		GetIdentityForDump()	{ return "Web Browser"; };
	virtual void			DumpProperties( size_t inIndent );

protected:
	std::string		mCurrentURL;
};

}

#endif /* defined(__Stacksmith__CWebBrowserPart__) */
