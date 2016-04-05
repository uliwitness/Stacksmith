//
//  CTinyXMLUtils.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 29.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CTinyXmlUtils.h"


using namespace Carlson;


long long		CTinyXMLUtils::GetLongLongNamed( tinyxml2::XMLElement* root, const char* inName, long long defaultValue )
{
	if( !root )
		return defaultValue;
	
	char	*	endPtr = NULL;
	tinyxml2::XMLElement*	child = inName ? root->FirstChildElement( inName ) : root;
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
	tinyxml2::XMLElement*	child = inName ? root->FirstChildElement( inName ) : root;
	const char*	str = child ? child->GetText() : NULL;
	if( !str )
		return defaultValue;
	int	num = (int)strtol( str, &endPtr, 10 );
	if( endPtr != (str+ strlen(str)) )
		return defaultValue;
	return num;
}


double		CTinyXMLUtils::GetDoubleNamed( tinyxml2::XMLElement* root, const char* inName, double defaultValue )
{
	if( !root )
		return defaultValue;
	
	char	*	endPtr = NULL;
	tinyxml2::XMLElement*	child = inName ? root->FirstChildElement( inName ) : root;
	const char*	str = child ? child->GetText() : NULL;
	if( !str )
		return defaultValue;
	double	num = strtod( str, &endPtr );
	if( endPtr != (str+ strlen(str)) )
		return defaultValue;
	return num;
}


void		CTinyXMLUtils::GetStringNamed( tinyxml2::XMLElement* root, const char* inName, std::string &outName )
{
	if( !root )
		return;
	
	tinyxml2::XMLElement*	elem = inName ? root->FirstChildElement( inName ) : root;
	const char*	str = elem ? elem->GetText() : NULL;
	if( str )
		outName = str;
}


bool		CTinyXMLUtils::GetBoolNamed( tinyxml2::XMLElement* root, const char* inName, bool defaultValue )
{
	if( !root )
		return defaultValue;
	
	tinyxml2::XMLElement*	elem = inName ? root->FirstChildElement( inName ) : root;
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


void	CTinyXMLUtils::GetRectNamed( tinyxml2::XMLElement* root, const char* inName, int *outLeft, int *outTop, int *outRight, int *outBottom )
{
	if( !root )
		return;
	
	tinyxml2::XMLElement*	subElem = NULL;
	tinyxml2::XMLElement*	elem = inName ? root->FirstChildElement( inName ) : root;
	subElem = elem ? elem->FirstChildElement("left") : NULL;
	if( subElem )
		subElem->QueryIntText( outLeft );
	subElem = elem ? elem->FirstChildElement("top") : NULL;
	if( subElem )
		subElem->QueryIntText( outTop );
	subElem = elem ? elem->FirstChildElement("right") : NULL;
	if( subElem )
		subElem->QueryIntText( outRight );
	subElem = elem ? elem->FirstChildElement("bottom") : NULL;
	if( subElem )
		subElem->QueryIntText( outBottom );
}


void	CTinyXMLUtils::GetColorNamed( tinyxml2::XMLElement* root, const char* inName, int *outRed, int *outGreen, int *outBlue, int *outAlpha )
{
	if( !root )
		return;
	
	tinyxml2::XMLElement*	subElem = NULL;
	tinyxml2::XMLElement*	elem = inName ? root->FirstChildElement( inName ) : root;
	subElem = elem ? elem->FirstChildElement("red") : NULL;
	if( subElem )
		subElem->QueryIntText( outRed );
	subElem = elem ? elem->FirstChildElement("green") : NULL;
	if( subElem )
		subElem->QueryIntText( outGreen );
	subElem = elem ? elem->FirstChildElement("blue") : NULL;
	if( subElem )
		subElem->QueryIntText( outBlue );
	subElem = elem ? elem->FirstChildElement("alpha") : NULL;
	if( subElem )
		subElem->QueryIntText( outAlpha );
}


void	CTinyXMLUtils::GetPointNamed( tinyxml2::XMLElement* root, const char* inName, int *outLeft, int *outTop )
{
	if( !root )
		return;
	
	tinyxml2::XMLElement*	subElem = NULL;
	tinyxml2::XMLElement*	elem = inName ? root->FirstChildElement( inName ) : root;
	subElem = elem ? elem->FirstChildElement("left") : NULL;
	if( subElem )
		subElem->QueryIntText( outLeft );
	subElem = elem ? elem->FirstChildElement("top") : NULL;
	if( subElem )
		subElem->QueryIntText( outTop );
}


void	CTinyXMLUtils::GetSizeNamed( tinyxml2::XMLElement* root, const char* inName, int *outLeft, int *outTop )
{
	if( !root )
		return;
	
	tinyxml2::XMLElement*	subElem = NULL;
	tinyxml2::XMLElement*	elem = inName ? root->FirstChildElement( inName ) : root;
	subElem = elem ? elem->FirstChildElement("width") : NULL;
	if( subElem )
		subElem->QueryIntText( outLeft );
	subElem = elem ? elem->FirstChildElement("height") : NULL;
	if( subElem )
		subElem->QueryIntText( outTop );
}


void	CTinyXMLUtils::AddLongLongNamed( tinyxml2::XMLElement* root, long long inValue, const char* inName )
{
	tinyxml2::XMLElement	*	elem = inName ? root->GetDocument()->NewElement(inName) : root;
	char		str[200] = {0};
	snprintf( str, sizeof(str) -1, "%lld", inValue );
	elem->SetText(str);
	if( inName )
		root->InsertEndChild( elem );
}


void	CTinyXMLUtils::AddStringNamed( tinyxml2::XMLElement* root, const std::string& inValue, const char* inName )
{
	tinyxml2::XMLElement	*	elem = inName ? root->GetDocument()->NewElement(inName) : root;
	elem->SetText(inValue.c_str());
	if( inName )
		root->InsertEndChild( elem );
}


void	CTinyXMLUtils::AddBoolNamed( tinyxml2::XMLElement* root, bool inValue, const char* inName )
{
	tinyxml2::XMLElement	*	elem = inName ? root->GetDocument()->NewElement(inName) : root;
	tinyxml2::XMLElement	*	theBoolElem = elem->FirstChild() ? elem->FirstChild()->ToElement() : NULL;
	if( theBoolElem
		&& (strcasecmp(theBoolElem->Value(),"true") == 0 || strcasecmp(theBoolElem->Value(),"false") == 0) )
	{
		theBoolElem->SetValue( inValue ? "true" : "false" );
	}
	else if( !elem->FirstChild() )
	{
		theBoolElem = root->GetDocument()->NewElement( inValue ? "true" : "false" );
		elem->InsertFirstChild( theBoolElem );
	}
	if( inName )
		root->InsertEndChild( elem );
}


void	CTinyXMLUtils::AddIntNamed( tinyxml2::XMLElement* root, int inValue, const char* inName )
{
	tinyxml2::XMLElement	*	elem = inName ? root->GetDocument()->NewElement(inName) : root;
	elem->SetText(inValue);
	if( inName )
		root->InsertEndChild( elem );
}


void	CTinyXMLUtils::AddDoubleNamed( tinyxml2::XMLElement* root, double inValue, const char* inName )
{
	tinyxml2::XMLElement	*	elem = inName ? root->GetDocument()->NewElement(inName) : root;
	elem->SetText(inValue);
	if( inName )
		root->InsertEndChild( elem );
}


void	CTinyXMLUtils::AddRectNamed( tinyxml2::XMLElement* root, long long inLeft, long long inTop, long long inRight, long long inBottom, const char* inName )
{
	tinyxml2::XMLElement	*	elem = inName ? root->GetDocument()->NewElement(inName) : root;
	AddLongLongNamed( elem, inLeft, "left" );
	AddLongLongNamed( elem, inTop, "top" );
	AddLongLongNamed( elem, inRight, "right" );
	AddLongLongNamed( elem, inBottom, "bottom" );
	if( inName )
		root->InsertEndChild( elem );
}


void	CTinyXMLUtils::AddColorNamed( tinyxml2::XMLElement* root, int inLeft, int inTop, int inRight, int inBottom, const char* inName )
{
	tinyxml2::XMLElement	*	elem = inName ? root->GetDocument()->NewElement(inName) : root;
	tinyxml2::XMLElement	*	subElem = root->GetDocument()->NewElement("red");
	subElem->SetText(inLeft);
	elem->InsertEndChild( subElem );
	subElem = root->GetDocument()->NewElement("green");
	subElem->SetText(inTop);
	elem->InsertEndChild( subElem );
	subElem = root->GetDocument()->NewElement("blue");
	subElem->SetText(inRight);
	elem->InsertEndChild( subElem );
	subElem = root->GetDocument()->NewElement("alpha");
	subElem->SetText(inBottom);
	elem->InsertEndChild( subElem );
	if( inName )
		root->InsertEndChild( elem );
}


void	CTinyXMLUtils::AddPointNamed( tinyxml2::XMLElement* root, int inLeft, int inTop, const char* inName )
{
	tinyxml2::XMLElement	*	elem = inName ? root->GetDocument()->NewElement(inName) : root;
	tinyxml2::XMLElement	*	subElem = root->GetDocument()->NewElement("left");
	subElem->SetText(inLeft);
	elem->InsertEndChild( subElem );
	subElem = root->GetDocument()->NewElement("top");
	subElem->SetText(inTop);
	elem->InsertEndChild( subElem );
	if( inName )
		root->InsertEndChild( elem );
}


void	CTinyXMLUtils::AddSizeNamed( tinyxml2::XMLElement* root, int inLeft, int inTop, const char* inName )
{
	tinyxml2::XMLElement	*	elem = inName ? root->GetDocument()->NewElement(inName) : root;
	tinyxml2::XMLElement	*	subElem = root->GetDocument()->NewElement("width");
	subElem->SetText(inLeft);
	elem->InsertEndChild( subElem );
	subElem = root->GetDocument()->NewElement("height");
	subElem->SetText(inTop);
	elem->InsertEndChild( subElem );
	if( inName )
		root->InsertEndChild( elem );
}


void	CTinyXMLUtils::SetLongLongAttributeNamed( tinyxml2::XMLElement* root, long long inValue, const char* inName )
{
	char	numStr[200] = {0};
	snprintf( numStr, sizeof(numStr) -1, "%lld", inValue );
	root->SetAttribute( inName, numStr );
}


long long	CTinyXMLUtils::GetLongLongAttributeNamed( tinyxml2::XMLElement* root, const char* inName, long long defaultValue )
{
	const char* str = root->Attribute( inName );
	if( !str )
		return defaultValue;
	char*       endPtr = NULL;
	long long	theNum = strtoll( str, &endPtr, 10 );
	if( endPtr != str +strlen(str) )
		theNum = defaultValue;

	return theNum;
}


std::string	CTinyXMLUtils::EnsureNonNULLString( const char* inStr )
{
	if( !inStr )
		return std::string();
	return std::string( inStr );
}


bool	CStacksmithXMLPrinter::CompactMode( const tinyxml2::XMLElement& elem )
{
	if( strcmp(elem.Name(),"text") == 0 || strcmp(elem.Name(),"script") == 0 || strcmp(elem.Name(),"td") == 0
		|| strcmp(elem.Name(),"body") == 0 )	// For htmlText property.
		return true;
	const tinyxml2::XMLElement*	firstElem = elem.FirstChildElement();
	const tinyxml2::XMLNode*	firstChild = elem.FirstChild();
	if( firstChild && firstElem && firstChild == elem.LastChild() && firstElem == firstChild	// Exactly one child, and it's an element?
		&& firstElem->FirstChild() == NULL )	// And this element has no children? I.e. is self-closing?
	{
		return true;
	}
	
	return false;
}

