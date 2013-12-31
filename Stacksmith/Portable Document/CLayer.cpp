//
//  CLayer.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CLayer.h"
#include "CURLConnection.h"
#include "CTinyXMLUtils.h"
#include "CPart.h"
#include "CPartContents.h"


CLayer::~CLayer()
{
	
}


void	CLayer::Load( std::function<void(CLayer*)> completionBlock )
{
	if( mLoaded )
	{
		completionBlock( this );
		return;
	}
	
	Retain();
	
	mLoadCompletionBlocks.push_back(completionBlock);
	
	if( !mLoading )	// If we're already loading, we've queued up our completion block which gets called when the async load has finished.
	{
		mLoading = true;
		CURLRequest		request( mURL );
		CURLConnection::SendRequestWithCompletionHandler( request, [this] (CURLResponse inResponse, const char* inData, size_t inDataLength) -> void
		{
			tinyxml2::XMLDocument		document;

			if( tinyxml2::XML_SUCCESS == document.Parse( inData, inDataLength ) )
			{
				document.Print();

				tinyxml2::XMLElement	*	root = document.RootElement();

				mID = CTinyXMLUtils::GetLongLongNamed( root, "id" );
				mName = "Untitled";
				CTinyXMLUtils::GetStringNamed( root, "name", mName );
				mShowPict = CTinyXMLUtils::GetBoolNamed( root, "showPict", true );
				mCantDelete = CTinyXMLUtils::GetBoolNamed( root, "cantDelete", false );
				mDontSearch = CTinyXMLUtils::GetBoolNamed( root, "dontSearch", false );
				mPictureName = "";
				CTinyXMLUtils::GetStringNamed( root, "bitmap", mPictureName );

				mScript.erase();
				CTinyXMLUtils::GetStringNamed( root, "script", mScript );

				LoadUserPropertiesFromElement( root );

				// Load parts:
				tinyxml2::XMLElement	*	currPartElem = root->FirstChildElement( "part" );
				while( currPartElem )
				{
					CPart	*	thePart = new CPart( currPartElem );
					thePart->Autorelease();
					mParts.push_back( thePart );
					thePart->Retain();	// Retain for the button families array.
					mButtonFamilies.insert( std::make_pair(thePart->GetFamily(), thePart) );

					currPartElem = currPartElem->NextSiblingElement( "part" );
				}

				// Load part contents:
				tinyxml2::XMLElement	*	currPartContentsElem = root->FirstChildElement( "content" );
				while( currPartContentsElem )
				{
					CPartContents	*	theContents = new CPartContents( currPartContentsElem );
					theContents->Autorelease();
					mContents.push_back( theContents );
					
					currPartContentsElem = currPartContentsElem->NextSiblingElement( "content" );
				}
			}
			
			mLoaded = true;
			mLoading = false;
			
			// Call all completion blocks:
			for( auto itty = mLoadCompletionBlocks.begin(); itty != mLoadCompletionBlocks.end(); itty++ )
				(*itty)(this);
			
			Release();
		} );
	}
}


void	CLayer::Dump( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%sLayer ID %lld \"%s\"\n%s{\n%s\tloaded = %s\n%s\t{\n", indentStr, mID, mName.c_str(), indentStr, indentStr, mLoaded ? "true" : "false", indentStr );
	for( auto itty = mParts.begin(); itty != mParts.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s\t{\n", indentStr, indentStr );
	for( auto itty = mContents.begin(); itty != mContents.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s}\n", indentStr, indentStr );
}

