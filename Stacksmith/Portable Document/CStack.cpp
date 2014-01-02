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
	for( auto itty = mBackgrounds.begin(); itty != mBackgrounds.end(); itty++ )
		(*itty)->SetStack( NULL );
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
		(*itty)->SetStack( NULL );
}


void	CStack::LoadFromURL( const std::string inURL, std::function<void(CStack*)> inCompletionBlock )
{
	Retain();
	
	CURLRequest		request( inURL );
	printf("Loading %s\n",inURL.c_str());
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
				backgroundURL.append( 1, '/' );
				backgroundURL.append( currBgElem->Attribute("file") );
				char*			endPtr = NULL;
				WILDObjectID	bgID = strtoll( currBgElem->Attribute("id"), &endPtr, 10 );
				const char*		theName = currBgElem->Attribute("name");
				
				CBackground	*	theBackground = new CBackground( backgroundURL, bgID, (theName ? theName : ""), this );
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
				cardURL.append( 1, '/' );
				cardURL.append( currCdElem->Attribute("file") );
				char*			endPtr = NULL;
				WILDObjectID	cdID = strtoll( currCdElem->Attribute("id"), &endPtr, 10 );
				const char*		theName = currCdElem->Attribute("name");
				const char*	markedAttrStr = currCdElem->Attribute("marked");
				bool	marked = markedAttrStr ? (strcmp("true", markedAttrStr) == 0) : false;
				
				CCard	*	theCard = new CCard( cardURL, cdID, (theName ? theName : ""), this, marked );
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


CCard*	CStack::GetCardByID( WILDObjectID inID )
{
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
	{
		if( (*itty)->GetID() == inID )
			return *itty;
	}
	
	return NULL;
}


CBackground*	CStack::GetBackgroundByID( WILDObjectID inID )
{
	for( auto itty = mBackgrounds.begin(); itty != mBackgrounds.end(); itty++ )
	{
		if( (*itty)->GetID() == inID )
			return *itty;
	}
	
	return NULL;
}


void	CStack::Dump( size_t inIndent )
{
	const char * indentStr = IndentString( inIndent );
	printf( "%sStack ID %lld \"%s\"\n%s{\n", indentStr, mStackID, mName.c_str(), indentStr );
	printf( "%s\tuserLevel = %d\n", indentStr, mUserLevel );
	printf( "%s\twidth = %d\n", indentStr, mCardWidth );
	printf( "%s\theight = %d\n", indentStr, mCardHeight );
	printf( "%s\tcantPeek = %s\n", indentStr, (mCantPeek? "true" : "false") );
	printf( "%s\tcantAbort = %s\n", indentStr, (mCantAbort? "true" : "false") );
	printf( "%s\tprivateAccess = %s\n", indentStr, (mPrivateAccess? "true" : "false") );
	printf( "%s\tcantDelete = %s\n", indentStr, (mCantDelete? "true" : "false") );
	printf( "%s\tcantModify = %s\n", indentStr, (mCantModify? "true" : "false") );
	printf( "%s\tresizable = %s\n", indentStr, (mResizable? "true" : "false") );
	printf( "%s\tcards\n%s\t{\n", indentStr, indentStr );
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s\tbackgrounds\n%s\t{\n", indentStr, indentStr, indentStr );
	for( auto itty = mBackgrounds.begin(); itty != mBackgrounds.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s\tmarkedCards\n%s\t{\n", indentStr, indentStr, indentStr );
	for( auto itty = mMarkedCards.begin(); itty != mMarkedCards.end(); itty++ )
	{
		CCardRef	theCard = (*itty);
		theCard->Dump( inIndent +2 );
	}
	printf( "%s\t}\n%s}\n", indentStr, indentStr );
}
