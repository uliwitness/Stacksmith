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
	for( auto itty = mParts.begin(); itty != mParts.end(); itty++ )
	{
		(**itty).Release();
	}
	for( auto itty = mAddColorParts.begin(); itty != mAddColorParts.end(); itty++ )
	{
		(**itty).Release();
	}
	for( auto itty = mContents.begin(); itty != mContents.end(); itty++ )
	{
		(**itty).Release();
	}
	for( auto itty = mButtonFamilies.begin(); itty != mButtonFamilies.end(); itty++ )
	{
		(*itty).second->Release();
	}
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
