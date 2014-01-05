//
//  CBackground.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CBackground__
#define __Stacksmith__CBackground__

#include "CLayer.h"

namespace Carlson {

class CBackground : public CLayer
{
public:
	CBackground( std::string inURL, WILDObjectID inID, const std::string inName, CStack* inStack ) : CLayer(inURL,inID,inName,inStack)	{};
	~CBackground()	{ printf("Released Background %p\n",this); };

protected:
	virtual const char*	GetIdentityForDump()		{ return "Background"; };
};

typedef CRefCountedObjectRef<CBackground>	CBackgroundRef;

}

#endif /* defined(__Stacksmith__CBackground__) */
