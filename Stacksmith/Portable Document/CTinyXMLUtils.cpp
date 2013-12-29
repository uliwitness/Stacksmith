//
//  CTinyXMLUtils.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 29.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CTinyXmlUtils.h"


long long		CTinyXMLUtils::GetLongLongNamed( tinyxml2::XMLDocument& doc, const char* inName, long long defaultValue )
{
	char	*	endPtr = NULL;
	const char*	str = doc.RootElement()->FirstChildElement( inName )->GetText();
	if( !str )
		return defaultValue;
	long long	num = strtoll( str, &endPtr, 10 );
	if( endPtr != (str+ strlen(str)) )
		return defaultValue;
	return num;
}


int		CTinyXMLUtils::GetIntNamed( tinyxml2::XMLDocument& doc, const char* inName, int defaultValue )
{
	char	*	endPtr = NULL;
	const char*	str = doc.RootElement()->FirstChildElement( inName )->GetText();
	if( !str )
		return defaultValue;
	int	num = strtod( str, &endPtr );
	if( endPtr != (str+ strlen(str)) )
		return defaultValue;
	return num;
}


long		CTinyXMLUtils::GetLongNamed( tinyxml2::XMLDocument& doc, const char* inName, long defaultValue )
{
	char	*	endPtr = NULL;
	const char*	str = doc.RootElement()->FirstChildElement( inName )->GetText();
	if( !str )
		return defaultValue;
	long	num = strtol( str, &endPtr, 10 );
	if( endPtr != (str+ strlen(str)) )
		return defaultValue;
	return num;
}


void		CTinyXMLUtils::GetStringNamed( tinyxml2::XMLDocument& doc, const char* inName, std::string &outName )
{
	const char*	str = doc.RootElement()->FirstChildElement( inName )->GetText();
	if( str )
		outName = str;
}


bool		CTinyXMLUtils::GetBoolNamed( tinyxml2::XMLDocument& doc, const char* inName, bool defaultValue )
{
	tinyxml2::XMLElement*	elem = doc.RootElement()->FirstChildElement( inName )->FirstChildElement();
	if( elem )
	{
		if( strcmp( elem->Name(), "true" ) == 0 )
			return true;
		if( strcmp( elem->Name(), "false" ) == 0 )
			return false;
	}
	return defaultValue;
}

