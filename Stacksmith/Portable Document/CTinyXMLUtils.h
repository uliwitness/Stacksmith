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
	static long long	GetLongLongNamed( tinyxml2::XMLDocument& doc, const char* inName, long long defaultValue = 0LL );
	static void			GetStringNamed( tinyxml2::XMLDocument& doc, const char* inName, std::string &outName );
	static bool			GetBoolNamed( tinyxml2::XMLDocument& doc, const char* inName, bool defaultValue = false );
	static int			GetIntNamed( tinyxml2::XMLDocument& doc, const char* inName, int defaultValue = 0 );
	static long			GetLongNamed( tinyxml2::XMLDocument& doc, const char* inName, long defaultValue = 0L );
};

#endif /* defined(__Stacksmith__CTinyXmlUtils__) */
