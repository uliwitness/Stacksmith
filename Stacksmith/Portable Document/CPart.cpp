//
//  CPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CPart.h"
#include "CTinyXMLUtils.h"


static std::map<std::string,CPartCreatorBase*>	sPartCreators;


/*static*/ CPart*	CPart::NewPartWithElement( tinyxml2::XMLElement * inElement, CLayer *inOwner )
{
	std::string		partType;
	CTinyXMLUtils::GetStringNamed( inElement, "type", partType );

	auto	foundItem = sPartCreators.find( partType );
	if( foundItem != sPartCreators.end() )
		return foundItem->second->NewPartWithElement( inElement, inOwner );
	else
		return new CPart( inElement, inOwner );
}


/*static*/ void		CPart::RegisterPartCreator( const std::string inTypeString, CPartCreatorBase* inCreator )
{
	sPartCreators[inTypeString] = inCreator;
}


CPart::CPart( tinyxml2::XMLElement * inElement, CLayer *inOwner )
	: mOwner(inOwner)
{
	mID = CTinyXMLUtils::GetLongLongNamed( inElement, "id" );
	mName.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "name", mName );
	mScript.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "script", mScript );
	tinyxml2::XMLElement * rectElement = inElement->FirstChildElement( "rect" );
	mLeft = CTinyXMLUtils::GetIntNamed( rectElement, "left", 10 );
	mTop = CTinyXMLUtils::GetIntNamed( rectElement, "top", 10 );
	mRight = CTinyXMLUtils::GetIntNamed( rectElement, "right", mLeft + 100 );
	mBottom = CTinyXMLUtils::GetIntNamed( rectElement, "bottom", mLeft + 100 );
	mVisible = CTinyXMLUtils::GetBoolNamed( inElement, "visible", true );
	mEnabled = CTinyXMLUtils::GetBoolNamed( inElement, "enabled", true );
}


void	CPart::DumpProperties( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%srect = %d,%d,%d,%d\n", indentStr, mLeft, mTop, mRight, mBottom );
}


void	CPart::Dump( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%s%s ID %lld \"%s\"\n%s{\n", indentStr, GetIdentityForDump(), mID, mName.c_str(), indentStr );
	DumpProperties( inIndent +1 );
	printf( "%s}\n", indentStr );
}
