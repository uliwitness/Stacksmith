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


struct CNewPartMenuItemEntry
{
	std::string		mMenuItemName;
	std::string		mPartType;
};


CDocumentManager*					CDocumentManager::sSharedDocumentManager = NULL;
std::vector<CNewPartMenuItemEntry>	sNewPartMenuItems;


void	CDocument::LoadNewPartMenuItemsFromFilePath( const char* inPath )
{
	tinyxml2::XMLDocument	*	document = new tinyxml2::XMLDocument();

	if( tinyxml2::XML_SUCCESS == document->LoadFile( inPath ) )
	{
		tinyxml2::XMLElement	*	root = document->RootElement();
		tinyxml2::XMLElement	*	partElement = root->FirstChildElement("newpart");
		while( partElement )
		{
			CNewPartMenuItemEntry		entry;
			CTinyXMLUtils::GetStringNamed( partElement, "type", entry.mPartType );
			CTinyXMLUtils::GetStringNamed( partElement, "menuItem", entry.mMenuItemName );
			sNewPartMenuItems.push_back( entry );
			
			partElement = partElement->NextSiblingElement("newpart");
		}
	}
	
	delete document;
}


size_t	CDocument::GetNewPartMenuItemCount()
{
	return sNewPartMenuItems.size();
}


std::string	CDocument::GetNewPartMenuItemAtIndex( size_t inIndex )
{
	return sNewPartMenuItems[inIndex].mMenuItemName;
}


std::string	CDocument::GetNewPartTypeAtIndex( size_t inIndex )
{
	return sNewPartMenuItems[inIndex].mPartType;
}


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
	mName = mURL;
	
	CURLRequest		request( inURL );
	CURLConnection::SendRequestWithCompletionHandler( request, [inURL,this](CURLResponse inResponse, const char* inData, size_t inDataLength)
	{
		if( inURL.find("file://") != 0 )	// Not a local file?
			SetWriteProtected(true);		// Can't write changes to it to disk.
		
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
			
			LoadUserPropertiesFromElement( root );

			mScript.clear();
			CTinyXMLUtils::GetStringNamed( root, "script", mScript );
			
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
				const char*		theThumbnail = currStackElem->Attribute("thumbnail");
				
				CStack	*	theStack = NewStackWithURLIDNameForDocument( stackURL, stackID, (theName ? theName : ""), fileName, this );
				theStack->Autorelease();
				mStacks.push_back( theStack );
				
				if( theThumbnail )
					theStack->SetThumbnailName( theThumbnail );
				
				currStackElem = currStackElem->NextSiblingElement( "stack" );
			}

			// Load menus:
			tinyxml2::XMLElement	*	currMenuElem = root->FirstChildElement( "menu" );
			
			while( currMenuElem )
			{
				CMenuRef	theMenu( new CMenu );
				theMenu->LoadFromElement( currMenuElem );
				mMenus.push_back( theMenu );
				
				currMenuElem = currMenuElem->NextSiblingElement( "menu" );
			}
		}
		
		mChangeCount = 0;
		
		CallAllCompletionBlocks();
	} );
}


std::string	CDocument::PathFromFileURL( const std::string& inURL )
{
	std::string		destPath;
	if( inURL.find("file://") != 0 )
		return std::string();
	destPath = inURL.substr( 7 );
	
	std::string	outPath;
	size_t		lastPos = 0;
	size_t		currPos = 0;
	while( currPos != std::string::npos )
	{
		currPos = destPath.find( '%', lastPos );
		if( currPos == std::string::npos )
			break;
		char*	endPtr = NULL;
		char	hexChars[3] = {0};
		memmove( hexChars, destPath.c_str() +currPos +1, 2 );
		long	charCode = strtol( hexChars, &endPtr, 16 );
		if( endPtr != hexChars +2 )
			return std::string();
		outPath.append( destPath, lastPos, currPos -lastPos );
		outPath.append( 1, (char)charCode );
		lastPos = currPos +1 +2;
	}
	
	if( lastPos != destPath.length() )
		outPath.append( destPath, lastPos, destPath.length() -lastPos );
	
	return outPath;
}


bool	CDocument::Save()
{
	std::string		destPath = PathFromFileURL( mURL );
	if( destPath.size() == 0 )
		return false;
	
	if( mWriteProtected )
		return false;
	
	if( mChangeCount != 0 || mLastEditedVersion.compare( "Stacksmith " MGVH_TOSTRING(STACKSMITH_VERSION) ) != 0 || mMediaCache.GetListNeedsToBeSaved() )	// Project itself (property or stack/media lists) changed, or this file was last written by another version of Stacksmith and we need to update 'last edited version'?
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
		
		if( mScript.length() > 0 )
		{
			tinyxml2::XMLElement*		scriptElement = document.NewElement("script");
			stackfile->InsertEndChild( scriptElement );
			scriptElement->SetText( mScript.c_str() );
		}
		
		if( !mMediaCache.SaveMediaElementsToElement( stackfile ) )
			return false;
		
		SaveUserPropertiesToElementOfDocument( stackfile, &document );
		
		for( auto currStack : mStacks )
		{
			tinyxml2::XMLElement*	stackElement = document.NewElement("stack");
			CTinyXMLUtils::SetLongLongAttributeNamed( stackElement, currStack->GetID(), "id" );
			stackElement->SetAttribute( "file", currStack->GetFileName().c_str() );
			stackElement->SetAttribute( "name", currStack->GetName().c_str() );
			std::string	thumbnailName = currStack->GetThumbnailName();
			if( thumbnailName.length() != 0 )
			{
				stackElement->SetAttribute( "thumbnail", thumbnailName.c_str() );
			}
			stackfile->InsertEndChild( stackElement );
			
			if( currStack->GetNeedsToBeSaved() )
			{
				if( !currStack->Save( destPath ) )
					return false;
			}
		}

		for( auto currMenu : mMenus )
		{
			tinyxml2::XMLElement*	menuElement = document.NewElement("menu");
			stackfile->InsertEndChild( menuElement );
			
			currMenu->SaveToElement( menuElement );
		}

		FILE*	theFile = fopen( (destPath + "/project.xml").c_str(), "w" );
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
		
		if( !mMediaCache.SaveMediaContents() )
			return false;
	}
	
	return true;
}


bool	CDocument::CreateAtURL( const std::string& inURL, const std::string inNameForUser )
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

	AddNewStack( inNameForUser );
	
	return Save();
}


void	CDocument::SaveThumbnailsForOpenStacks()
{
	for( CStack* currStack : mStacks )
	{
		currStack->SaveThumbnailIfFirstCardOpen();
	}
}


void	CDocument::CallAllCompletionBlocks()
{
	mLoaded = true;
	mLoading = false;
	
    Retain();   // In case one of the completion blocks wants to close us.
    
	for( auto itty = mLoadCompletionBlocks.begin(); itty != mLoadCompletionBlocks.end(); itty++ )
		(*itty)( this );
	mLoadCompletionBlocks.clear();
    
    Release();  // Now we can go away.
}


void	CDocument::IncrementChangeCount()
{
	mChangeCount++;
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
	
	if( mMediaCache.GetNeedsToBeSaved() || mMediaCache.GetListNeedsToBeSaved() )
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


CStack*	CDocument::AddNewStack( std::string inStackName )
{
	ObjectID			stackID = GetUniqueIDForStack();
	std::stringstream	fileName;
	fileName << "stack_" << stackID << ".xml";
	std::string			stackURL = mURL;
	if( stackURL[stackURL.length()-1] != '/' )
		stackURL.append( 1, '/' );
	stackURL.append( fileName.str() );
	
	if( inStackName.size() == 0 )
	{
		std::stringstream	nameForUser;
		nameForUser << "Stack " << mStacks.size() +1;
		inStackName = nameForUser.str();
	}
	
	CStack	*	theStack = NewStackWithURLIDNameForDocument( stackURL, stackID, inStackName, fileName.str(), this );
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
		mContextGroup = LEOContextGroupCreate( new CScriptContextGroupUserData, CScriptContextGroupUserData::CleanUp );
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


void	CDocument::CheckIfWeShouldCloseCauseLastStackClosed()
{
	for( auto currStack : mStacks )
	{
		if( currStack->IsVisible() )
			return;
	}
	
	CDocumentManager::GetSharedDocumentManager()->CloseDocument( this );
}


bool	CDocument::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp(inPropertyName, "name") == 0 )
	{
		LEOInitStringValue( outValue, mName.c_str(), mName.size(), kLEOInvalidateReferences, inContext );
		return true;
	}
	else if( strcasecmp(inPropertyName, "id") == 0 )
	{
		LEOInitIntegerValue( outValue, GetID(), kLEOUnitNone, kLEOInvalidateReferences, inContext );
		return true;
	}
	else if( strcasecmp(inPropertyName, "cantPeek") == 0 )
	{
		LEOInitBooleanValue( outValue, mCantPeek, kLEOInvalidateReferences, inContext );
		return true;
	}
	else if( strcasecmp(inPropertyName, "privateAccess") == 0 )
	{
		LEOInitBooleanValue( outValue, mPrivateAccess, kLEOInvalidateReferences, inContext );
		return true;
	}
	else if( strcasecmp(inPropertyName, "writeProtected") == 0 )
	{
		LEOInitBooleanValue( outValue, mWriteProtected, kLEOInvalidateReferences, inContext );
		return true;
	}
	else
		return CConcreteObject::GetPropertyNamed(inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
}


bool	CDocument::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp(inPropertyName, "name") == 0 )
	{
		char		styleBuf[100] = {0};
		const char*	styleStr = LEOGetValueAsString( inValue, styleBuf, sizeof(styleBuf), inContext );
		SetName( styleStr );
		return true;
	}
	else if( strcasecmp(inPropertyName, "id") == 0 )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "The ID of an object can't be changed." );
		return true;
	}
	else if( strcasecmp(inPropertyName, "cantPeek") == 0 )
	{
		bool			cantPeek = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) != 0 )
		{
			mCantPeek = cantPeek;
		}
		return true;
	}
	else if( strcasecmp(inPropertyName, "privateAccess") == 0 )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "You need to use the user interface to remove password protection from a project." );
		return true;
	}
	else if( strcasecmp(inPropertyName, "writeProtected") == 0 )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "The writeProtected property can't be changed." );
		return true;
	}
	else
		return CConcreteObject::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
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


CDocumentManager::CDocumentManager()
	: mFrontDocument(NULL)
{
	if( sSharedDocumentManager )
		throw std::logic_error( "Attempt to create more than one document manager." );
	sSharedDocumentManager = this;
}


void	CDocumentManager::SetPeeking( bool inState )
{
	for( auto currDoc : mOpenDocuments )
	{
		currDoc->SetPeeking( inState );
	}
}


void	CDocumentManager::CloseDocument( CDocumentRef inDocument )
{
	for( auto currDoc = mOpenDocuments.begin(); currDoc != mOpenDocuments.end(); currDoc++ )
	{
		if( (*currDoc) == inDocument )
		{
			if( (*currDoc)->GetNeedsToBeSaved() )
				(*currDoc)->Save();
			mOpenDocuments.erase(currDoc);
			break;
		}
	}
	
	if( mOpenDocuments.size() == 0 )
		Quit();
}


void	CDocumentManager::SaveAll()
{
	for( auto currDoc : mOpenDocuments )
	{
		if( currDoc->GetNeedsToBeSaved() )
			currDoc->Save();
	}
}


void	CDocumentManager::SetFrontDocument( CDocument* inDocument )
{
	mFrontDocument = inDocument;
}


/*static*/ CDocumentManager*	CDocumentManager::GetSharedDocumentManager()
{
	return sSharedDocumentManager;
}

