//
//  CTinyXMLUtils.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 29.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CTinyXmlUtils.h"


using namespace Calhoun;


long long		CTinyXMLUtils::GetLongLongNamed( tinyxml2::XMLElement* root, const char* inName, long long defaultValue )
{
	if( !root )
		return defaultValue;
	
	char	*	endPtr = NULL;
	tinyxml2::XMLElement*	child = root->FirstChildElement( inName );
	const char*	str = child ? child->GetText() : NULL;
	if( !str )
		return defaultValue;
	long long	num = strtoll( str, &endPtr, 10 );
	if( endPtr != (str+ strlen(str)) )
		return defaultValue;
	return num;
}


int		CTinyXMLUtils::GetIntNamed( tinyxml2::XMLElement* root, const char* inName, int defaultValue )
{
	if( !root )
		return defaultValue;
	
	char	*	endPtr = NULL;
	tinyxml2::XMLElement*	child = root->FirstChildElement( inName );
	const char*	str = child ? child->GetText() : NULL;
	if( !str )
		return defaultValue;
	int	num = strtod( str, &endPtr );
	if( endPtr != (str+ strlen(str)) )
		return defaultValue;
	return num;
}


long		CTinyXMLUtils::GetLongNamed( tinyxml2::XMLElement* root, const char* inName, long defaultValue )
{
	if( !root )
		return defaultValue;
	
	char	*	endPtr = NULL;
	tinyxml2::XMLElement*	child = root->FirstChildElement( inName );
	const char*	str = child ? child->GetText() : NULL;
	if( !str )
		return defaultValue;
	long	num = strtol( str, &endPtr, 10 );
	if( endPtr != (str+ strlen(str)) )
		return defaultValue;
	return num;
}


void		CTinyXMLUtils::GetStringNamed( tinyxml2::XMLElement* root, const char* inName, std::string &outName )
{
	if( !root )
		return;
	
	const char*	str = root->FirstChildElement( inName )->GetText();
	if( str )
		outName = str;
}


bool		CTinyXMLUtils::GetBoolNamed( tinyxml2::XMLElement* root, const char* inName, bool defaultValue )
{
	if( !root )
		return defaultValue;
	
	tinyxml2::XMLElement*	elem = root->FirstChildElement( inName );
	if( elem )
		elem = elem->FirstChildElement();
	if( elem )
	{
		if( strcmp( elem->Name(), "true" ) == 0 )
			return true;
		if( strcmp( elem->Name(), "false" ) == 0 )
			return false;
	}
	return defaultValue;
}


std::string	CTinyXMLUtils::EnsureNonNULLString( const char* inStr )
{
	if( !inStr )
		return std::string();
	return std::string( inStr );
}
