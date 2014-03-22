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
#include <sstream>


using namespace Carlson;


CDocument::~CDocument()
{
	if( mContextGroup )
	{
		LEOContextGroupRelease( mContextGroup );
		mContextGroup = NULL;
	}
}


void	CDocument::LoadFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock )
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
	mMediaCache.SetURL( mURL );
	
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

			mMediaCache.LoadStandardResources();
			
			// Load media table of this document so others can access it: (ICONs, PICTs, CURSs and SNDs)
			// Load style table so others can access it:
			mMediaCache.LoadMediaTableFromElementAsBuiltIn( root, false );	// Load media from this stack.
			
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
		
		mChangeCount = 0;
		
		CallAllCompletionBlocks();
	} );
}


bool	CDocument::Save()
{
	std::string		destPath;
	if( mURL.find("file://") != 0 )
		return false;
	destPath = mURL.substr( 7 );
	size_t	lpcStart = destPath.rfind('/');
	if( lpcStart == std::string::npos )
		return false;
	destPath = destPath.substr(0,lpcStart);
	destPath.append(1,'/');
	
	if( mChangeCount != 0 || mLastEditedVersion.compare( "Stacksmith " MGVH_TOSTRING(STACKSMITH_VERSION) ) != 0 )	// Project itself (property or stack/media lists) changed, or this file was last written by another version of Stacksmith and we need to update 'last edited version'?
	{
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
			
			if( currStack->GetNeedsToBeSaved() )
			{
				if( !currStack->Save( destPath ) )
					return false;
			}
		}
		
		tinyxml2::XMLElement*		userLevelElement = document.NewElement("userLevel");
		userLevelElement->SetText(mUserLevel);
		stackfile->InsertEndChild( userLevelElement );

		CTinyXMLUtils::AddBoolNamed( stackfile, mPrivateAccess, "privateAccess" );
		CTinyXMLUtils::AddBoolNamed( stackfile, mCantPeek, "cantPeek" );
		
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
		
		mMediaCache.SaveMediaElementsToElement( stackfile );

		FILE*	theFile = fopen( (destPath + "project.xml").c_str(), "w" );
		if( !theFile )
			return false;
		CStacksmithXMLPrinter	printer( theFile );
		document.Print( &printer );
		fclose(theFile);
		
		mChangeCount = 0;
	}
	else
	{
		for( auto currStack : mStacks )
		{
			if( currStack->GetNeedsToBeSaved() )
			{
				if( !currStack->Save( destPath ) )
					return false;
			}
		}
		
		mMediaCache.SaveMediaContents();
	}
	
	return true;
}


bool	CDocument::CreateAtURL( const std::string& inURL )
{
	size_t			slashOffset = inURL.rfind( '/' );
	if( slashOffset == std::string::npos )
		slashOffset = 0;
	mURL = inURL.substr(0,slashOffset) + '/';
	
	mMediaCache.SetURL( mURL );
	mMediaCache.LoadStandardResources();
		
	mCreatedByVersion = "Stacksmith " MGVH_TOSTRING(STACKSMITH_VERSION);
	mLastCompactedVersion = "Stacksmith " MGVH_TOSTRING(STACKSMITH_VERSION);
	mFirstEditedVersion = "Stacksmith " MGVH_TOSTRING(STACKSMITH_VERSION);
	mLastEditedVersion = "Stacksmith " MGVH_TOSTRING(STACKSMITH_VERSION);
	
	mLoaded = true;

	AddNewStack();
	
	return Save();
}


void	CDocument::CallAllCompletionBlocks()
{
	mLoaded = true;
	mLoading = false;
	
	for( auto itty = mLoadCompletionBlocks.begin(); itty != mLoadCompletionBlocks.end(); itty++ )
		(*itty)( this );
	mLoadCompletionBlocks.clear();
}


bool	CDocument::GetNeedsToBeSaved()
{
	if( mChangeCount != 0 )
		return true;
	
	for( auto currStack : mStacks )
	{
		if( currStack->GetNeedsToBeSaved() )
			return true;
	}
	
	if( mMediaCache.GetNeedsToBeSaved() )
		return true;
	
	return false;
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


CStack*	CDocument::AddNewStack()
{
	ObjectID			stackID = GetUniqueIDForStack();
	std::stringstream	fileName;
	fileName << "stack_" << stackID << ".xml";
	std::string			stackURL = mURL;
	if( stackURL[stackURL.length()-1] != '/' )
		stackURL.append( 1, '/' );
	stackURL.append( fileName.str() );
	
	std::stringstream	nameForUser;
	nameForUser << "Stack " << mStacks.size() +1;
	
	CStack	*	theStack = NewStackWithURLIDNameForDocument( stackURL, stackID, nameForUser.str(), fileName.str(), this );
	theStack->AddNewCardWithBackground();
	theStack->SetLoaded(true);
	mStacks.push_back( theStack );
	theStack->Release();
	
	IncrementChangeCount();
	
	return theStack;
}


bool	CDocument::DeleteStack( CStack* inStack )
{
	if( mStacks.size() == 1 )
		return false;
	
	if( inStack->GetCantDelete() )
		return false;
	
	for( auto currStack = mStacks.begin(); currStack != mStacks.end(); currStack++ )
	{
		if( (*currStack) == inStack )
		{
			mStacks.erase( currStack );
			break;
		}
	}
	
	IncrementChangeCount();
	
	return true;
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


ObjectID	CDocument::GetUniqueIDForCard()
{
	bool	notUnique = true;
	
	while( notUnique )
	{
		notUnique = false;
		
		for( auto currStack = mStacks.begin(); currStack != mStacks.end(); currStack ++ )
		{
			size_t	numCards = (*currStack)->GetNumCards();
			for( size_t x = 0; x < numCards; x++ )
			{
				CCard	*	currCard = (*currStack)->GetCard(x);
				if( currCard->GetID() == mCardIDSeed )
				{
					notUnique = true;
					mCardIDSeed++;
					break;
				}
			}
		}
	}
	
	return mCardIDSeed;
}


ObjectID	CDocument::GetUniqueIDForBackground()
{
	bool	notUnique = true;
	
	while( notUnique )
	{
		notUnique = false;
		
		for( auto currStack = mStacks.begin(); currStack != mStacks.end(); currStack ++ )
		{
			size_t	numBackgrounds = (*currStack)->GetNumBackgrounds();
			for( size_t x = 0; x < numBackgrounds; x++ )
			{
				CBackground	*	currBackground = (*currStack)->GetBackground(x);
				if( currBackground->GetID() == mBackgroundIDSeed )
				{
					notUnique = true;
					mBackgroundIDSeed++;
					break;
				}
			}
		}
	}
	
	return mBackgroundIDSeed;
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
	mMediaCache.Dump( 2 );

	printf( "\t}\n\tstacks\n\t{\n" );
	for( auto itty = mStacks.begin(); itty != mStacks.end(); itty++ )
		(*itty)->Dump(2);
	printf( "\t}\n}\n" );
}
