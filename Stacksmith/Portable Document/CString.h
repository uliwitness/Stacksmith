//
//  CString.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

/*
	Wrapper object so we can add a string to the current CAutoreleasePool
	and thus return a pointer to it without it going away because it's on
	our stack.
*/

#ifndef __Stacksmith__CString__
#define __Stacksmith__CString__

#include <string>
#include "CRefCountedObject.h"

namespace Carlson {

class CString : public CRefCountedObject
{
public:
	CString( const std::string& inString = std::string() )	{};
	
	std::string&		GetString()									{ return mString; };
	void				SetString( const std::string& inString )	{ mString = inString; };

public:
	std::string		mString;
};


}

#endif /* defined(__Stacksmith__CString__) */
