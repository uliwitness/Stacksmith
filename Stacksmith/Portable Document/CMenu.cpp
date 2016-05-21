//
//  CMenu.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 20/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#include "CMenu.h"
#include "CTinyXMLUtils.h"
#include "CDocument.h"


using namespace Carlson;


static const char*	sMenuItemStyleStrings[EMenuItemStyle_Last +1] =
{
	"standard",
	"separator",
	"*UNKNOWN*"
};


ObjectID	CMenu::GetUniqueIDForItem()
{
	bool	notUnique = true;
	
	while( notUnique )
	{
		notUnique = false;
		
		for( auto currItem = mItems.begin(); currItem != mItems.end(); currItem ++ )
		{
			if( (*currItem)->GetID() == mItemIDSeed )
			{
				notUnique = true;
				mItemIDSeed++;
				break;
			}
		}
	}
	
	return mItemIDSeed;
}


void	CMenu::LoadFromElement( tinyxml2::XMLElement* inElement )
{
	mID = CTinyXMLUtils::GetLongLongNamed( inElement, "id", -1 );
	if( mID == -1 )
		mID = mDocument->GetUniqueIDForMenu();
	mName.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "name", mName );
	mVisible = CTinyXMLUtils::GetBoolNamed( inElement, "visible", true );
	mScript.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "script", mScript );
	
	LoadUserPropertiesFromElement( inElement );
	
	mItems.erase( mItems.begin(), mItems.end() );
	tinyxml2::XMLElement	*	currItemElem = inElement->FirstChildElement( "item" );
	while( currItemElem )
	{
		CMenuItemRef		theItem( new CMenuItem( this ), true );
		theItem->LoadFromElement( currItemElem );
		mItems.push_back( theItem );

		currItemElem = currItemElem->NextSiblingElement( "item" );
	}
}


bool	CMenu::SaveToElement( tinyxml2::XMLElement* inElement )
{
	CTinyXMLUtils::AddLongLongNamed( inElement, mID, "id" );
	CTinyXMLUtils::AddStringNamed( inElement, mName, "name" );
	if( !mVisible )
		CTinyXMLUtils::AddBoolNamed( inElement, mVisible, "visible" );
	if( mScript.length() != 0 )
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


CScriptableObject*	CMenu::GetParentObject()
{
	CScriptableObject* parent = CStack::GetFrontStack()->GetCurrentCard();
	if( !parent )
		parent = mDocument;
	return parent;
}


CMenuItem::CMenuItem( CMenu * inParent )
	: mID(0), mParent(inParent), mStyle(EMenuItemStyleStandard), mVisible(true), mEnabled(true)
{
	mDocument = inParent->GetDocument();
}


void	CMenuItem::LoadFromElement( tinyxml2::XMLElement* inElement )
{
	mID = CTinyXMLUtils::GetLongLongNamed( inElement, "id" );
	mName.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "name", mName );
	tinyxml2::XMLElement* styleElem = inElement->FirstChildElement( "style" );
	if( styleElem )
		mStyle = GetMenuItemStyleFromString( styleElem->GetText() );
	if( mStyle == EMenuItemStyle_Last )
		mStyle = EMenuItemStyleStandard;
	mCommandChar.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "commandChar", mCommandChar );
	mMarkChar.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "markChar", mMarkChar );
	mVisible = CTinyXMLUtils::GetBoolNamed( inElement, "visible", true );
	mEnabled = CTinyXMLUtils::GetBoolNamed( inElement, "enabled", true );
	mScript.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "script", mScript );
	
	LoadUserPropertiesFromElement( inElement );
}


bool	CMenuItem::SaveToElement( tinyxml2::XMLElement* inElement )
{
	CTinyXMLUtils::AddLongLongNamed( inElement, mID, "id" );
	CTinyXMLUtils::AddStringNamed( inElement, mName, "name" );
	if( mStyle != EMenuItemStyleStandard )
		CTinyXMLUtils::AddStringNamed( inElement, sMenuItemStyleStrings[mStyle], "style" );
	if( mCommandChar.length() != 0 )
		CTinyXMLUtils::AddStringNamed( inElement, mCommandChar, "commandChar" );
	if( mMarkChar.length() != 0 )
		CTinyXMLUtils::AddStringNamed( inElement, mMarkChar, "markChar" );
	if( !mVisible )
		CTinyXMLUtils::AddBoolNamed( inElement, mVisible, "visible" );
	if( !mEnabled )
		CTinyXMLUtils::AddBoolNamed( inElement, mEnabled, "enabled" );
	if( mScript.length() != 0 )
		CTinyXMLUtils::AddStringNamed( inElement, mScript, "script" );

	SaveUserPropertiesToElementOfDocument( inElement, inElement->GetDocument() );

	return true;
}


CScriptableObject*	CMenuItem::GetParentObject()
{
	return mParent;
}


TMenuItemStyle	CMenuItem::GetMenuItemStyleFromString( const char* inStyleStr )
{
	for( size_t x = 0; x < EMenuItemStyle_Last; x++ )
	{
		if( strcasecmp(sMenuItemStyleStrings[x],inStyleStr) == 0 )
			return (TMenuItemStyle)x;
	}
	return EMenuItemStyle_Last;
}


