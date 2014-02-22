//
//  CMap.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-10.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMap.h"
#include "UTF8UTF32Utilities.h"

using namespace Carlson;


bool CCaseInsensitiveStringComparator::operator()( const string & s1, const string & s2 ) const
{
	std::string		outStr;
	size_t			x = 0, y = 0,
					s1Len = s1.length(),
					s2Len = s2.length();
	const char*		s1UTF8Bytes = s1.c_str();
	const char*		s2UTF8Bytes = s2.c_str();
	
	while( x < s1Len && y < s2Len )
	{
		uint32_t	currs1UTF32Char = UTF8StringParseUTF32CharacterAtOffset( s1UTF8Bytes, s1Len, &x );
		uint32_t	currs2UTF32Char = UTF8StringParseUTF32CharacterAtOffset( s2UTF8Bytes, s2Len, &y );
		currs1UTF32Char = UTF32CharacterToLower( currs1UTF32Char );
		currs2UTF32Char = UTF32CharacterToLower( currs2UTF32Char );
		
		if( currs1UTF32Char < currs2UTF32Char )
			return true;
		if( currs1UTF32Char > currs2UTF32Char )
			return false;
	}
	
	return (s1Len < s2Len);
}

