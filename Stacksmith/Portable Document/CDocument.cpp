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


using namespace Calhoun;


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
		WILDObjectID	iconID = CTinyXMLUtils::GetLongLongNamed( currMediaElem, "id", 0 );
		std::string	iconName;
		CTinyXMLUtils::GetStringNamed( currMediaElem, "name", iconName );
		std::string	fileName;
		CTinyXMLUtils::GetStringNamed( currMediaElem, "file", fileName );
		std::string	typeName;
		CMediaType	mediaType = CMediaTypeUnknown;
		CTinyXMLUtils::GetStringNamed( currMediaElem, "type", typeName );
		if( typeName.compare( "icon" ) == 0 )
			mediaType = CMediaTypeIcon;
		else if( typeName.compare( "picture" ) == 0 )
			mediaType = CMediaTypePicture;
		else if( typeName.compare( "cursor" ) == 0 )
			mediaType = CMediaTypeCursor;
		else if( typeName.compare( "sound" ) == 0 )
			mediaType = CMediaTypeSound;
		tinyxml2::XMLElement	*	hotspotElem = currMediaElem->FirstChildElement( "hotspot" );
		int		hotspotLeft = CTinyXMLUtils::GetIntNamed( hotspotElem, "left", 0 );
		int		hotspotTop = CTinyXMLUtils::GetIntNamed( hotspotElem, "top", 0 );
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

			// Load font table so others can access it:
			tinyxml2::XMLElement	*	currFontElem = root->FirstChildElement( "font" );
			while( currFontElem )
			{
				int			fontID = CTinyXMLUtils::GetIntNamed( currFontElem, "id", 0 );
				std::string	fontName;
				CTinyXMLUtils::GetStringNamed( currFontElem, "name", fontName );
				mFontIDTable[fontID] = fontName;
				
				currFontElem = currFontElem->NextSiblingElement( "font" );
			}
			
			// Load style table so others can access it:
			tinyxml2::XMLElement	*	currStyleElem = root->FirstChildElement( "styleentry" );
			while( currStyleElem )
			{
				int			styleID = CTinyXMLUtils::GetIntNamed( currStyleElem, "id", 0 );
				std::string	fontName;
				CTinyXMLUtils::GetStringNamed( currStyleElem, "font", fontName );
				int			fontSize = CTinyXMLUtils::GetIntNamed( currStyleElem, "size", 0 );
				CPartTextStyle	styleMask = CPartTextStylePlain;
				for( tinyxml2::XMLElement * currTextStyleElem = currStyleElem->FirstChildElement("textStyle"); currTextStyleElem; currTextStyleElem = currStyleElem->NextSiblingElement("textStyle") )
				{
					if( strcmp( currTextStyleElem->GetText(), "bold" ) == 0 )
						styleMask |= CPartTextStyleBold;
					if( strcmp( currTextStyleElem->GetText(), "italic" ) == 0 )
						styleMask |= CPartTextStyleItalic;
					if( strcmp( currTextStyleElem->GetText(), "underline" ) == 0 )
						styleMask |= CPartTextStyleUnderline;
					if( strcmp( currTextStyleElem->GetText(), "outline" ) == 0 )
						styleMask |= CPartTextStyleOutline;
					if( strcmp( currTextStyleElem->GetText(), "shadow" ) == 0 )
						styleMask |= CPartTextStyleShadow;
					if( strcmp( currTextStyleElem->GetText(), "condensed" ) == 0 )
						styleMask |= CPartTextStyleCondensed;
					if( strcmp( currTextStyleElem->GetText(), "extended" ) == 0 )
						styleMask |= CPartTextStyleExtended;
				}
				mTextStyles[styleID] = CTextStyleEntry( fontName, fontSize, styleMask );
				
				currStyleElem = currStyleElem->NextSiblingElement( "styleentry" );
			}

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
			size_t			slashOffset = inURL.rfind( '/' );
			if( slashOffset == std::string::npos )
				slashOffset = 0;
			
			while( currStackElem )
			{
				std::string		stackURL = inURL.substr(0,slashOffset);
				stackURL.append( 1, '/' );
				stackURL.append( currStackElem->Attribute("file") );
				char*			endPtr = NULL;
				WILDObjectID	stackID = strtoll( currStackElem->Attribute("id"), &endPtr, 10 );
				const char*		theName = currStackElem->Attribute("name");
				
				CStack	*	theStack = new CStack( stackURL, stackID, (theName ? theName : ""), this );
				theStack->Autorelease();
				mStacks.push_back( theStack );
				
				currStackElem = currStackElem->NextSiblingElement( "stack" );
			}
		}
		
		mLoaded = true;
		mLoading = false;
		
		for( auto itty = mLoadCompletionBlocks.begin(); itty != mLoadCompletionBlocks.end(); itty++ )
			(*itty)( this );
		mLoadCompletionBlocks.clear();
	} );
}


WILDObjectID	CDocument::GetUniqueIDForStack()
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



WILDObjectID	CDocument::GetUniqueIDForMedia()
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


void	CDocument::Dump()
{
	printf( "Document\n{\n\tloaded = %s\n\tloading= %s\n\tcreatedByVersion = %s\n\tlastCompactedVersion = %s\n\tfirstEditedVersion = %s\n\tlastEditedVersion = %s\n",
			(mLoaded ? "true" : "false"), (mLoading ? "true" : "false"), mCreatedByVersion.c_str(),
			mLastCompactedVersion.c_str(), mFirstEditedVersion.c_str(), mLastEditedVersion.c_str() );
	printf( "\tfonts\n\t{\n" );
	for( auto itty = mFontIDTable.begin(); itty != mFontIDTable.end(); itty++ )
		printf( "\t\t%s -> %d\n", itty->second.c_str(), itty->first );
	printf( "\t}\n\tstyles\n\t{\n" );
	for( auto itty = mTextStyles.begin(); itty != mTextStyles.end(); itty++ )
	{
		printf( "\t\t%d: ", itty->first );
		itty->second.Dump();
	}
	
	printf( "\t}\n\tmedia\n\t{\n" );
	for( auto itty = mMediaList.begin(); itty != mMediaList.end(); itty++ )
		itty->Dump( 2 );

	printf( "\t}\n\tstacks\n\t{\n" );
	for( auto itty = mStacks.begin(); itty != mStacks.end(); itty++ )
		(*itty)->Dump(2);
	printf( "\t}\n}\n" );
}
