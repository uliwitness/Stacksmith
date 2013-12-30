//
//  CTinyXMLUtils.h
//  Stacksmith
//
//  Created by Uli Kusterer on 29.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CTinyXmlUtils__
#define __Stacksmith__CTinyXmlUtils__

#include <string>
#include "tinyxml2.h"


class CTinyXMLUtils
{
public:
	static long long	GetLongLongNamed( tinyxml2::XMLElement* root, const char* inName, long long defaultValue = 0LL );
	static void			GetStringNamed( tinyxml2::XMLElement* root, const char* inName, std::string &outName );
	static bool			GetBoolNamed( tinyxml2::XMLElement* root, const char* inName, bool defaultValue = false );
	static int			GetIntNamed( tinyxml2::XMLElement* root, const char* inName, int defaultValue = 0 );
	static long			GetLongNamed( tinyxml2::XMLElement* root, const char* inName, long defaultValue = 0L );
	static std::string	EnsureNonNULLString( const char* inStr );
};

#endif /* defined(__Stacksmith__CTinyXmlUtils__) */
