//
//  CPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CPart.h"
#include "CTinyXMLUtils.h"
#include "CLayer.h"


using namespace Carlson;


static std::map<std::string,CPartCreatorBase*>	sPartCreators;


/*static*/ CPart*	CPart::NewPartWithElement( tinyxml2::XMLElement * inElement, CLayer *inOwner )
{
	std::string		partType;
	CTinyXMLUtils::GetStringNamed( inElement, "type", partType );
	CPart	*		thePart = NULL;

	auto	foundItem = sPartCreators.find( partType );
	if( foundItem != sPartCreators.end() )
		thePart = foundItem->second->NewPartInOwner( inOwner );
	else
	{
		thePart = new CPart( inOwner );
		fprintf( stderr, "error: Unknown part type %s, falling back on plain part.\n", partType.c_str() );
	}
	thePart->LoadFromElement( inElement );
	return thePart;
}


/*static*/ void		CPart::RegisterPartCreator( const std::string inTypeString, CPartCreatorBase* inCreator )
{
	sPartCreators[inTypeString] = inCreator;
}


CPart::CPart( CLayer *inOwner )
	: mFamily(0), mOwner(inOwner)
{
	mDocument = inOwner->GetDocument();
}


void	CPart::LoadFromElement( tinyxml2::XMLElement * inElement )
{
	LoadPropertiesFromElement( inElement );
	LoadUserPropertiesFromElement( inElement );
}


void	CPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
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
}


CScriptableObject*	CPart::GetParentObject()
{
	return mOwner;
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
	DumpUserProperties( inIndent +1 );
	printf( "%s\tscript = <<%s>>\n", indentStr, mScript.c_str() );
	printf( "%s}\n", indentStr );
}
