//
//  CMoviePlayerPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMoviePlayerPart__
#define __Stacksmith__CMoviePlayerPart__

#include "CPart.h"

namespace Calhoun {

class CMoviePlayerPart : public CPart
{
public:
	explicit CMoviePlayerPart( CLayer *inOwner ) : CPart( inOwner ) {};
	
protected:
	virtual const char*		GetIdentityForDump()	{ return "Movie Player"; };
	virtual void			DumpProperties( size_t inIndent );
};

}

#endif /* defined(__Stacksmith__CMoviePlayerPart__) */
