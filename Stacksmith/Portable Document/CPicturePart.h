//
//  CPicturePart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CPicturePart__
#define __Stacksmith__CPicturePart__

#include "CVisiblePart.h"

namespace Carlson {

class CPicturePart : public CVisiblePart
{
public:
	explicit CPicturePart( CLayer *inOwner ) : CVisiblePart( inOwner ), mTransparent(false) {};
	
	virtual void			SetMediaPath( const std::string& inNameOrPath )	{ mMediaPath = inNameOrPath; IncrementChangeCount(); };
	virtual void			SetTransparent( bool inTransparent )	{ mTransparent = inTransparent; IncrementChangeCount(); };
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	
	virtual const char*		GetIdentityForDump()	{ return "Picture"; };
	virtual void			DumpProperties( size_t inIndent );

protected:
	bool			mTransparent;
	std::string		mMediaPath;
};

}

#endif /* defined(__Stacksmith__CPicturePart__) */
