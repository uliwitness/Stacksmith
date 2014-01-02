//
//  CTimerPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CTimerPart__
#define __Stacksmith__CTimerPart__

#include "CPart.h"
#include <string>


namespace Calhoun {

class CTimerPart : public CPart
{
public:
	explicit CTimerPart( CLayer *inOwner ) : CPart( inOwner ) {};
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	
	virtual const char*		GetIdentityForDump()	{ return "Timer"; };
	virtual void			DumpProperties( size_t inIndent );
	
protected:
	std::string		mMessage;
	long long		mInterval;
	bool			mStarted;
	bool			mRepeat;
};

}

#endif /* defined(__Stacksmith__CTimerPart__) */
