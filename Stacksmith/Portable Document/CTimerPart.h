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

class CTimerPart : public CPart
{
public:
	explicit CTimerPart( CLayer *inOwner ) : CPart( inOwner ) {};
	
protected:
	virtual const char*		GetIdentityForDump()	{ return "Timer"; };
	virtual void			DumpProperties( size_t inIndent );
};

#endif /* defined(__Stacksmith__CTimerPart__) */
