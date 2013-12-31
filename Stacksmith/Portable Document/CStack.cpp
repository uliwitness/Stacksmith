//
//  CStack.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CStack.h"
#include "CCard.h"
#include "CBackground.h"
#include "CURLConnection.h"
#include "tinyxml2.h"
#include "CTinyXMLUtils.h"


CStack::~CStack()
{
	
}


void	CStack::LoadFromURL( const std::string inURL, std::function<void(CStack*)> inCompletionBlock )
{
	Retain();
	
	CURLRequest		request( inURL );
	CURLConnection::SendRequestWithCompletionHandler( request, [this,inURL,inCompletionBlock] (CURLResponse inResponse, const char* inData, size_t inDataLength) -> void
	{
		tinyxml2::XMLDocument		document;
		
		if( tinyxml2::XML_SUCCESS == document.Parse( inData, inDataLength ) )
		{
			//document.Print();
			
			tinyxml2::XMLElement	*	root = document.RootElement();
			
			mStackID = CTinyXMLUtils::GetLongLongNamed( root, "id" );
			mName = "Untitled";
			CTinyXMLUtils::GetStringNamed( root, "name", mName );
			mUserLevel = CTinyXMLUtils::GetIntNamed( root, "userLevel", 5 );
			mCantModify = CTinyXMLUtils::GetBoolNamed( root, "cantModify", false );
			mCantDelete = CTinyXMLUtils::GetBoolNamed( root, "cantDelete", false );
			mPrivateAccess = CTinyXMLUtils::GetBoolNamed( root, "privateAccess", false );
			mCantAbort = CTinyXMLUtils::GetBoolNamed( root, "cantAbort", false );
			mCantPeek = CTinyXMLUtils::GetBoolNamed( root, "cantPeek", false );
			mResizable = CTinyXMLUtils::GetBoolNamed( root, "resizable", false );
			tinyxml2::XMLElement	*	sizeElem = root->FirstChildElement( "cardSize" );
			mCardWidth = CTinyXMLUtils::GetIntNamed( sizeElem, "width", 512 );
			mCardHeight = CTinyXMLUtils::GetIntNamed( sizeElem, "height", 342 );
			
			mScript.erase();
			CTinyXMLUtils::GetStringNamed( root, "script", mScript );
			
			LoadUserPropertiesFromElement( root );
			
			// Load backgrounds:
			tinyxml2::XMLElement	*	currBgElem = root->FirstChildElement( "background" );
			while( currBgElem )
			{
				size_t			slashOffset = inURL.rfind( '/' );
				std::string		backgroundURL = inURL.substr(0,slashOffset);
				backgroundURL.append( currBgElem->Attribute("file") );
				
				CBackground	*	theBackground = new CBackground( backgroundURL );
				theBackground->Autorelease();
				mBackgrounds.push_back( theBackground );
				
				currBgElem = currBgElem->NextSiblingElement( "background" );
			}

			// Load cards:
			tinyxml2::XMLElement	*	currCdElem = root->FirstChildElement( "card" );
			while( currCdElem )
			{
				size_t			slashOffset = inURL.rfind( '/' );
				std::string		cardURL = inURL.substr(0,slashOffset);
				cardURL.append( currCdElem->Attribute("file") );
				const char*	markedAttrStr = currCdElem->Attribute("marked");
				bool	marked = markedAttrStr ? (strcmp("true", markedAttrStr) == 0) : false;
				
				CCard	*	theCard = new CCard( cardURL, marked );
				theCard->Autorelease();
				mCards.push_back( theCard );
				if( marked )
					mMarkedCards.insert( theCard );
				
				currCdElem = currCdElem->NextSiblingElement( "card" );
			}
		}
		
		inCompletionBlock( this );
		Release();
	} );
}

void	CStack::AddCard( CCard* inCard )
{
	inCard->Retain();
	mCards.push_back( inCard );
	
	if( inCard->IsMarked() )
		mMarkedCards.insert( inCard );
}

void	CStack::RemoveCard( CCard* inCard )
{
	if( inCard->IsMarked() )
		mMarkedCards.erase( inCard );
	
	mCards.push_back( inCard );
	inCard->Release();
}


void	CStack::Dump( size_t inIndent )
{
	const char * indentStr = IndentString( inIndent );
	printf( "%sStack ID %lld \"%s\"\n%s{\n", indentStr, mStackID, mName.c_str(), indentStr );
	printf( "%s\twidth = %d\n", indentStr, mCardWidth );
	printf( "%s\theight = %d\n", indentStr, mCardHeight );
	printf( "%s\t{\n", indentStr );
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s\t{\n", indentStr, indentStr );
	for( auto itty = mBackgrounds.begin(); itty != mBackgrounds.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s}\n", indentStr, indentStr );
}
