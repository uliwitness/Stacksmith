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


void	CLayer::SetStack( CStack* inStack )
{
	mStack = inStack;
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
				
				LoadPropertiesFromElement( root );
				
				LoadUserPropertiesFromElement( root );

				// Load parts:
				tinyxml2::XMLElement	*	currPartElem = root->FirstChildElement( "part" );
				while( currPartElem )
				{
					CPart	*	thePart = CPart::NewPartWithElement( currPartElem, this );
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
			
			CallAllCompletionBlocks();
		} );
	}
}


void	CLayer::CallAllCompletionBlocks()	// Can override this in cards to also load the background if needed and only *then* call completion blocks.
{
	mLoaded = true;
	mLoading = false;
	
	// Call all completion blocks:
	for( auto itty = mLoadCompletionBlocks.begin(); itty != mLoadCompletionBlocks.end(); itty++ )
		(*itty)(this);
			
	Release();
}


void	CLayer::LoadPropertiesFromElement( tinyxml2::XMLElement* root )
{
	// We get id and name from the TOC.xml via the constructor
	mShowPict = CTinyXMLUtils::GetBoolNamed( root, "showPict", true );
	mCantDelete = CTinyXMLUtils::GetBoolNamed( root, "cantDelete", false );
	mDontSearch = CTinyXMLUtils::GetBoolNamed( root, "dontSearch", false );
	mPictureName = "";
	CTinyXMLUtils::GetStringNamed( root, "bitmap", mPictureName );

	mScript.erase();
	CTinyXMLUtils::GetStringNamed( root, "script", mScript );
}


const char*	CLayer::GetIdentityForDump()
{
	return "Layer";
}


void	CLayer::DumpProperties( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%sloaded = %s\n", indentStr, mLoaded ? "true" : "false" );
}


void	CLayer::Dump( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%s%s ID %lld \"%s\"\n%s{\n", indentStr, GetIdentityForDump(), mID, mName.c_str(), indentStr );
	DumpProperties( inIndent +1 );
	DumpUserProperties( inIndent +1 );
	printf("%s\t{\n",indentStr);
	for( auto itty = mParts.begin(); itty != mParts.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s\t{\n", indentStr, indentStr );
	for( auto itty = mContents.begin(); itty != mContents.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s}\n", indentStr, indentStr );
}

