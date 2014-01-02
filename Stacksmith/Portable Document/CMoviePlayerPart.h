//
//  CMoviePlayerPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMoviePlayerPart__
#define __Stacksmith__CMoviePlayerPart__

#include "CVisiblePart.h"

namespace Calhoun {

class CMoviePlayerPart : public CVisiblePart
{
public:
	explicit CMoviePlayerPart( CLayer *inOwner ) : CVisiblePart( inOwner ) {};
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	
	virtual const char*		GetIdentityForDump()	{ return "Movie Player"; };
	virtual void			DumpProperties( size_t inIndent );

protected:
	std::string			mMediaPath;
	long long			mCurrentTime;
	bool				mControllerVisible;
};

}

#endif /* defined(__Stacksmith__CMoviePlayerPart__) */
