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
#include "CMessageWatcher.h"
#include <sys/stat.h>
#include "StacksmithVersion.h"


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
		if( fileName.find( "../" ) != 0 && fileName.find( "/../" ) == std::string::npos )	// Don't let paths escape the file package.
		{
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
			else if( typeName.compare( "pattern" ) == 0 )
				mediaType = EMediaTypePattern;
			else if( typeName.compare( "movie" ) == 0 )
				mediaType = EMediaTypeMovie;
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
		}
		
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
			
			mUserLevel = CTinyXMLUtils::GetIntNamed( root, "userLevel", 5 );
			mPrivateAccess = CTinyXMLUtils::GetBoolNamed( root, "privateAccess", false );
			mCantPeek = CTinyXMLUtils::GetBoolNamed( root, "cantPeek", false );

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
				std::string		fileName( currStackElem->Attribute("file") );
				std::string		stackURL = mURL;
				if( stackURL[stackURL.length()-1] != '/' )
					stackURL.append( 1, '/' );
				stackURL.append( fileName );
				ObjectID		stackID = CTinyXMLUtils::GetLongLongAttributeNamed( currStackElem, "id" );
				const char*		theName = currStackElem->Attribute("name");
				
				CStack	*	theStack = NewStackWithURLIDNameForDocument( stackURL, stackID, (theName ? theName : ""), fileName, this );
				theStack->Autorelease();
				mStacks.push_back( theStack );
				
				currStackElem = currStackElem->NextSiblingElement( "stack" );
			}
		}
		
		CallAllCompletionBlocks();
	} );
}


void	CDocument::Save()
{
	std::string		destPath;
	if( mURL.find("file://") != 0 )
		return;
	destPath = mURL.substr( 7 );
	size_t	lpcStart = destPath.rfind('/');
	if( lpcStart == std::string::npos )
		return;
	destPath = destPath.substr(0,lpcStart);
	destPath.append(1,'/');
	mkdir( destPath.c_str(), 0777 );

	tinyxml2::XMLDocument		document;
	tinyxml2::XMLDeclaration*	declaration = document.NewDeclaration();
	declaration->SetValue("xml version=\"1.0\" encoding=\"utf-8\"");
	document.InsertEndChild( declaration );
	
	tinyxml2::XMLUnknown*	dtd = document.NewUnknown("DOCTYPE project PUBLIC \"-//Apple, Inc.//DTD project V 2.0//EN\" \"\"");
	document.InsertEndChild( dtd );
	
	tinyxml2::XMLElement*		stackfile = document.NewElement("project");
	document.InsertEndChild( stackfile );
	
	for( auto currStack : mStacks )
	{
		tinyxml2::XMLElement*	stackElement = document.NewElement("stack");
		CTinyXMLUtils::SetLongLongAttributeNamed( stackElement, currStack->GetID(), "id" );
		stackElement->SetAttribute( "file", currStack->GetFileName().c_str() );
		stackElement->SetAttribute( "name", currStack->GetName().c_str() );
		stackfile->InsertEndChild( stackElement );
		
		currStack->Save( destPath );
	}
	
	tinyxml2::XMLElement*		userLevelElement = document.NewElement("userLevel");
	userLevelElement->SetText(mUserLevel);
	stackfile->InsertEndChild( userLevelElement );

	tinyxml2::XMLElement*		privateAccessElement = document.NewElement("privateAccess");
	stackfile->InsertEndChild( privateAccessElement );
	privateAccessElement->SetBoolFirstChild(mPrivateAccess);

	tinyxml2::XMLElement*		cantPeekElement = document.NewElement("cantPeek");
	stackfile->InsertEndChild( cantPeekElement );
	cantPeekElement->SetBoolFirstChild(mCantPeek);
	
	tinyxml2::XMLElement*		createdByElement = document.NewElement("createdByVersion");
	stackfile->InsertEndChild( createdByElement );
	createdByElement->SetText(mCreatedByVersion.c_str());

	createdByElement = document.NewElement("lastCompactedVersion");
	stackfile->InsertEndChild( createdByElement );
	createdByElement->SetText(mLastCompactedVersion.c_str());

	createdByElement = document.NewElement("firstEditedVersion");
	stackfile->InsertEndChild( createdByElement );
	createdByElement->SetText(mFirstEditedVersion.c_str());

	createdByElement = document.NewElement("lastEditedVersion");
	stackfile->InsertEndChild( createdByElement );
	createdByElement->SetText("Stacksmith " MGVH_TOSTRING(STACKSMITH_VERSION));
	
	for( auto currEntry : mMediaList )
	{
		if( currEntry.IsBuiltIn() )
			continue;
		
		tinyxml2::XMLElement*	mediaElement = document.NewElement("media");
		const char*				mediaTypeStr = NULL;
		switch( currEntry.GetMediaType() )
		{
			case EMediaTypeCursor:
				mediaTypeStr = "cursor";
				break;
			case EMediaTypeIcon:
				mediaTypeStr = "icon";
				break;
			case EMediaTypeSound:
				mediaTypeStr = "sound";
				break;
			case EMediaTypePicture:
				mediaTypeStr = "picture";
				break;
			case EMediaTypePattern:
				mediaTypeStr = "pattern";
				break;
			case EMediaTypeMovie:
				mediaTypeStr = "movie";
				break;
			case EMediaTypeUnknown:
				break;
		}
		
		CTinyXMLUtils::SetLongLongAttributeNamed( mediaElement, currEntry.GetID(), "id" );
		
		tinyxml2::XMLElement*	nameElem = document.NewElement("name");
		nameElem->SetText(currEntry.GetName().c_str());
		mediaElement->InsertEndChild( nameElem );

		tinyxml2::XMLElement*	fileElem = document.NewElement("file");
		fileElem->SetText(currEntry.GetFileName().c_str());
		mediaElement->InsertEndChild( fileElem );

		tinyxml2::XMLElement*	typeElem = document.NewElement("type");
		typeElem->SetText(mediaTypeStr);
		mediaElement->InsertEndChild( typeElem );
		
		if( currEntry.GetMediaType() == EMediaTypeCursor )
		{
			CTinyXMLUtils::AddPointNamed( mediaElement, currEntry.GetHotspotLeft(), currEntry.GetHotspotTop(), "hotspot" );
		}
		
		stackfile->InsertEndChild( mediaElement );
	}

	document.SaveFile( (destPath + "project.xml").c_str() );
}


void	CDocument::CallAllCompletionBlocks()
{
	mLoaded = true;
	mLoading = false;
	
	for( auto itty = mLoadCompletionBlocks.begin(); itty != mLoadCompletionBlocks.end(); itty++ )
		(*itty)( this );
	mLoadCompletionBlocks.clear();
}


CStack*	CDocument::GetStackWithID( ObjectID inID )
{
	for( auto itty = mStacks.begin(); itty != mStacks.end(); itty++ )
	{
		if( (*itty)->GetID() == inID )
			return *itty;
	}
	
	return NULL;
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


std::string	CDocument::GetMediaURLByNameOfType( const std::string& inName, TMediaType inType, int *outHotspotLeft, int *outHotspotTop )
{
	const char*	str = inName.c_str();
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inType == currMedia->GetMediaType() && (strcasecmp( str, currMedia->GetName().c_str() ) == 0) )
		{
			if (outHotspotLeft) *outHotspotLeft = currMedia->GetHotspotLeft();
			if (outHotspotTop) *outHotspotTop = currMedia->GetHotspotTop();
			return currMedia->GetFileName();
		}
	}
	
	return std::string();
}


std::string	CDocument::GetMediaURLByIDOfType( ObjectID inID, TMediaType inType, int *outHotspotLeft, int *outHotspotTop )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
		{
			if (outHotspotLeft) *outHotspotLeft = currMedia->GetHotspotLeft();
			if (outHotspotTop) *outHotspotTop = currMedia->GetHotspotTop();
			return currMedia->GetFileName();
		}
	}
	
	return std::string();
}


size_t		CDocument::GetNumMediaOfType( TMediaType inType )
{
	if( inType == EMediaTypeUnknown )
		return mMediaList.size();
	
	size_t	numMedia = 0;
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( currMedia->GetMediaType() == inType )
			numMedia++;
	}
	
	return numMedia;
}


ObjectID	CDocument::GetIDOfMediaOfTypeAtIndex( TMediaType inType, size_t inIndex )
{
	if( inType == EMediaTypeUnknown )
		return mMediaList[inIndex].GetID();
	
	size_t	x = 0;
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( currMedia->GetMediaType() == inType )
		{
			if( x == inIndex )
				return currMedia->GetID();
			else
				x++;
		}
	}
	
	return 0;
}


std::string		CDocument::GetMediaNameByIDOfType( ObjectID inID, TMediaType inType )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
			return currMedia->GetName();
	}
	
	return std::string();
}


bool	CDocument::GetMediaIsBuiltInByIDOfType( ObjectID inID, TMediaType inType )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
			return currMedia->IsBuiltIn();
	}
	
	return false;
}


std::string		CDocument::AddMediaWithIDTypeNameSuffixHotSpotIsBuiltInReturningURL( ObjectID inID, TMediaType inType, const std::string& inName, const char* inSuffix, int xHotSpot, int yHotSpot, bool isBuiltIn )
{
	std::string		fileName( mURL );
	switch( inType )
	{
		case EMediaTypeIcon:
			fileName.append( "/icon_" );
			break;
		case EMediaTypePicture:
			fileName.append( "/picture_" );
			break;
		case EMediaTypeCursor:
			fileName.append( "/cursor_" );
			break;
		case EMediaTypeSound:
			fileName.append( "/sound_" );
			break;
		case EMediaTypePattern:
			fileName.append( "/pattern_" );
			break;
		case EMediaTypeMovie:
			fileName.append( "/movie_" );
			break;
		case EMediaTypeUnknown:
			fileName.append( "/unknown_" );
			break;
	}
	char	numStr[100] = {0};
	snprintf(numStr, sizeof(numStr)-1, "%lld", inID );
	fileName.append(numStr);
	fileName.append(1, '.');
	fileName.append(inSuffix);
	mMediaList.push_back( CMediaEntry( inID, inName, fileName, inType, xHotSpot, yHotSpot, isBuiltIn ) );
	return fileName;
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


static void		CDocumentMessageSent( LEOHandlerID inHandlerID, LEOContextGroup* inContext )
{
	CMessageWatcher::GetSharedInstance()->AddMessage( LEOContextGroupHandlerNameForHandlerID( inContext, inHandlerID ) );
}


LEOContextGroup*	CDocument::GetScriptContextGroupObject()
{
	if( !mContextGroup )
	{
		mContextGroup = LEOContextGroupCreate();
		if( mURL.find_first_of( "file://" ) != 0 )
			mContextGroup->flags |= kLEOContextGroupFlagFromNetwork;
		mContextGroup->messageSent = CDocumentMessageSent;
	}
	
	return mContextGroup;
}


CStack*		CDocument::NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument )
{
	return new CStack( inURL, inID, inName, inFileName, inDocument );
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
