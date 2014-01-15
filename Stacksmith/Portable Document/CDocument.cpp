//
//  CDocument.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CDocument.h"
#include "CURLConnection.h"
#include "CStack.h"
#include "CTinyXMLUtils.h"
#include "CVisiblePart.h"


using namespace Carlson;


static std::string		sStandardResourcesPath;


/*static*/ void		CDocument::SetStandardResourcesPath( const std::string &inStdResPath )
{
	sStandardResourcesPath = inStdResPath;
}


CDocument::~CDocument()
{
	if( mContextGroup )
	{
		LEOContextGroupRelease( mContextGroup );
		mContextGroup = NULL;
	}
}


void	CDocument::LoadMediaTableFromElementAsBuiltIn( tinyxml2::XMLElement * root, bool isBuiltIn )
{
	tinyxml2::XMLElement	*	currMediaElem = root->FirstChildElement( "media" );
	while( currMediaElem )
	{
		ObjectID	iconID = CTinyXMLUtils::GetLongLongNamed( currMediaElem, "id", 0 );
		std::string	iconName;
		CTinyXMLUtils::GetStringNamed( currMediaElem, "name", iconName );
		std::string	fileName;
		CTinyXMLUtils::GetStringNamed( currMediaElem, "file", fileName );
		std::string	typeName;
		TMediaType	mediaType = EMediaTypeUnknown;
		CTinyXMLUtils::GetStringNamed( currMediaElem, "type", typeName );
		if( typeName.compare( "icon" ) == 0 )
			mediaType = EMediaTypeIcon;
		else if( typeName.compare( "picture" ) == 0 )
			mediaType = EMediaTypePicture;
		else if( typeName.compare( "cursor" ) == 0 )
			mediaType = EMediaTypeCursor;
		else if( typeName.compare( "sound" ) == 0 )
			mediaType = EMediaTypeSound;
		tinyxml2::XMLElement	*	hotspotElem = currMediaElem->FirstChildElement( "hotspot" );
		int		hotspotLeft = CTinyXMLUtils::GetIntNamed( hotspotElem, "left", 0 );
		int		hotspotTop = CTinyXMLUtils::GetIntNamed( hotspotElem, "top", 0 );
		
		if( isBuiltIn )
		{
			size_t	slashPos = sStandardResourcesPath.rfind('/');
			std::string	builtInResPath = sStandardResourcesPath.substr(0,slashPos);
			fileName = std::string("file://") + builtInResPath + "/" + fileName;
		}
		else
		{
			fileName = mURL + "/" + fileName;
		}
		
		mMediaList.push_back( CMediaEntry( iconID, iconName, fileName, mediaType, hotspotLeft, hotspotTop, isBuiltIn ) );
		
		currMediaElem = currMediaElem->NextSiblingElement( "media" );
	}

}


void	CDocument::LoadFromURL( const std::string inURL, std::function<void(CDocument*)> inCompletionBlock )
{
	if( mLoaded )
	{
		inCompletionBlock( this );
		return;
	}
	
	mLoadCompletionBlocks.push_back( inCompletionBlock );
	
	if( mLoading )	// We'll call you, too, once we have finished loading.
		return;
	
	mLoading = true;
	
	size_t			slashOffset = inURL.rfind( '/' );
	if( slashOffset == std::string::npos )
		slashOffset = 0;
	mURL = inURL.substr(0,slashOffset);
	
	CURLRequest		request( inURL );
	CURLConnection::SendRequestWithCompletionHandler( request, [inURL,this](CURLResponse inResponse, const char* inData, size_t inDataLength)
	{
		CAutoreleasePool			pool;
		tinyxml2::XMLDocument		document;
		
		if( tinyxml2::XML_SUCCESS == document.Parse( inData, inDataLength ) )
		{
			//document.Print();
			
			tinyxml2::XMLElement	*	root = document.RootElement();
			
			// Load read/written version numbers so we can conditionally react to them:
			mCreatedByVersion.clear();
			CTinyXMLUtils::GetStringNamed( root, "createdByVersion", mCreatedByVersion );
			mLastCompactedVersion.clear();
			CTinyXMLUtils::GetStringNamed( root, "lastCompactedVersion", mLastCompactedVersion );
			mFirstEditedVersion.clear();
			CTinyXMLUtils::GetStringNamed( root, "firstEditedVersion", mFirstEditedVersion );
			mLastEditedVersion.clear();
			CTinyXMLUtils::GetStringNamed( root, "lastEditedVersion", mLastEditedVersion );
			
			if( sStandardResourcesPath.length() > 0 )
			{
				tinyxml2::XMLDocument		standardResDocument;
				
				if( tinyxml2::XML_SUCCESS == standardResDocument.LoadFile( sStandardResourcesPath.c_str() ) )
				{
					tinyxml2::XMLElement	*	standardResRoot = standardResDocument.RootElement();
					LoadMediaTableFromElementAsBuiltIn( standardResRoot, true );	// Load media built into the app.
				}
			}
			
			// Load media table of this document so others can access it: (ICONs, PICTs, CURSs and SNDs)
			// Load style table so others can access it:
			LoadMediaTableFromElementAsBuiltIn( root, false );	// Load media from this stack.
			
			// Load stacks:
			tinyxml2::XMLElement	*	currStackElem = root->FirstChildElement( "stack" );
			
			while( currStackElem )
			{
				std::string		stackURL = mURL;
				stackURL.append( 1, '/' );
				stackURL.append( currStackElem->Attribute("file") );
				char*			endPtr = NULL;
				ObjectID	stackID = strtoll( currStackElem->Attribute("id"), &endPtr, 10 );
				const char*		theName = currStackElem->Attribute("name");
				
				CStack	*	theStack = NewStackWithURLIDNameForDocument( stackURL, stackID, (theName ? theName : ""), this );
				theStack->Autorelease();
				mStacks.push_back( theStack );
				
				currStackElem = currStackElem->NextSiblingElement( "stack" );
			}
		}
		
		CallAllCompletionBlocks();
	} );
}


void	CDocument::CallAllCompletionBlocks()
{
	mLoaded = true;
	mLoading = false;
	
	for( auto itty = mLoadCompletionBlocks.begin(); itty != mLoadCompletionBlocks.end(); itty++ )
		(*itty)( this );
	mLoadCompletionBlocks.clear();
}


CStack*	CDocument::GetStackByName( const char *inName )
{
	for( auto itty = mStacks.begin(); itty != mStacks.end(); itty++ )
	{
		if( strcasecmp( (*itty)->GetName().c_str(), inName ) == 0 )
			return *itty;
	}
	
	return NULL;
}


std::string	CDocument::GetMediaURLByNameOfType( const std::string& inName, TMediaType inType )
{
	const char*	str = inName.c_str();
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inType == currMedia->GetMediaType() && (strcasecmp( str, currMedia->GetName().c_str() ) == 0) )
		{
			std::string	fullURL = mURL;
			fullURL.append( 1, '/' );
			fullURL.append( currMedia->GetFileName() );
			return fullURL;
		}
	}
	
	return std::string();
}


std::string	CDocument::GetMediaURLByIDOfType( ObjectID inID, TMediaType inType )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
		{
			std::string	fullURL = mURL;
			fullURL.append( 1, '/' );
			fullURL.append( currMedia->GetFileName() );
			return fullURL;
		}
	}
	
	return std::string();
}


ObjectID	CDocument::GetUniqueIDForStack()
{
	bool	notUnique = true;
	
	while( notUnique )
	{
		notUnique = false;
		
		for( auto currStack = mStacks.begin(); currStack != mStacks.end(); currStack ++ )
		{
			if( (*currStack)->GetID() == mStackIDSeed )
			{
				notUnique = true;
				mStackIDSeed++;
				break;
			}
		}
	}
	
	return mStackIDSeed;
}



ObjectID	CDocument::GetUniqueIDForMedia()
{
	bool	notUnique = true;
	
	while( notUnique )
	{
		notUnique = false;
		
		for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia ++ )
		{
			if( (*currMedia).GetID() == mMediaIDSeed )
			{
				notUnique = true;
				mMediaIDSeed++;
				break;
			}
		}
	}
	
	return mMediaIDSeed;
}


LEOContextGroup*	CDocument::GetScriptContextGroupObject()
{
	if( !mContextGroup )
		mContextGroup = LEOContextGroupCreate();
	
	return mContextGroup;
}


CStack*		CDocument::NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, CDocument * inDocument )
{
	return new CStack( inURL, inID, inName, inDocument );
}


void	CDocument::SetPeeking( bool inState )
{
	mPeeking = inState;
	for( auto currStack : mStacks )
		currStack->SetPeeking( inState );
}


void	CDocument::Dump( size_t inNestingLevel )
{
	printf( "Document\n{\n\tloaded = %s\n\tloading= %s\n\tcreatedByVersion = %s\n\tlastCompactedVersion = %s\n\tfirstEditedVersion = %s\n\tlastEditedVersion = %s\n",
			(mLoaded ? "true" : "false"), (mLoading ? "true" : "false"), mCreatedByVersion.c_str(),
			mLastCompactedVersion.c_str(), mFirstEditedVersion.c_str(), mLastEditedVersion.c_str() );
	printf( "\tmedia\n\t{\n" );
	for( auto itty = mMediaList.begin(); itty != mMediaList.end(); itty++ )
		itty->Dump( 2 );

	printf( "\t}\n\tstacks\n\t{\n" );
	for( auto itty = mStacks.begin(); itty != mStacks.end(); itty++ )
		(*itty)->Dump(2);
	printf( "\t}\n}\n" );
}
