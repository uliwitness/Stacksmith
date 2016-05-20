//
//  CMenu.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 20/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#include "CMenu.h"
#include "CTinyXMLUtils.h"


using namespace Carlson;


void	CMenu::LoadFromElement( tinyxml2::XMLElement* inElement )
{
	mID = CTinyXMLUtils::GetLongLongNamed( inElement, "id" );
	mName.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "name", mName );
	mScript.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "script", mScript );
	
	LoadUserPropertiesFromElement( inElement );
	
	mItems.erase( mItems.begin(), mItems.end() );
	tinyxml2::XMLElement	*	currItemElem = inElement->FirstChildElement( "item" );
	while( currItemElem )
	{
		CMenuItemRef		theItem( new CMenuItem, true );
		theItem->LoadFromElement( currItemElem );
		mItems.push_back( theItem );

		currItemElem = currItemElem->NextSiblingElement( "item" );
	}
}


bool	CMenu::SaveToElement( tinyxml2::XMLElement* inElement )
{
	CTinyXMLUtils::AddLongLongNamed( inElement, mID, "id" );
	CTinyXMLUtils::AddStringNamed( inElement, mName, "name" );
	CTinyXMLUtils::AddStringNamed( inElement, mScript, "script" );

	SaveUserPropertiesToElementOfDocument( inElement, inElement->GetDocument() );

	tinyxml2::XMLDocument* document = inElement->GetDocument();
	tinyxml2::XMLElement*	elem = nullptr;
	for( auto currItem : mItems )
	{
		elem = document->NewElement("item");
		inElement->InsertEndChild(elem);
		currItem->SaveToElement( elem );
	}
	
	return true;
}


void	CMenuItem::LoadFromElement( tinyxml2::XMLElement* inElement )
{
	mName.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "name", mName );
	mScript.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "script", mScript );
	mID = CTinyXMLUtils::GetLongLongNamed( inElement, "id" );
	
	LoadUserPropertiesFromElement( inElement );
}


bool	CMenuItem::SaveToElement( tinyxml2::XMLElement* inElement )
{
	CTinyXMLUtils::AddStringNamed( inElement, mName, "name" );
	CTinyXMLUtils::AddStringNamed( inElement, mScript, "script" );
	CTinyXMLUtils::AddLongLongNamed( inElement, mID, "id" );

	SaveUserPropertiesToElementOfDocument( inElement, inElement->GetDocument() );

	return true;
}
