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
#include "CDocument.h"
#include <sstream>


using namespace Carlson;


CStack*							CStack::sFrontStack = NULL;
std::function<void(CStack*)>	CStack::sFrontStackChangedBlock = NULL;


static const char*		sToolNames[ETool_Last +1] =
{
	"browse",
	"pointer",
	"edit text",
	"oval",
	"rectangle",
	"roundrect",
	"line",
	"bezierpath",
	"*UNKNOWN*"
};


static const char*	sStackStyleStrings[EStackStyle_Last +1] =
{
	"standard",
	"rectangle",
	"popup",
	"palette",
	"*UNKNOWN*"
};


CStack::~CStack()
{
	//printf("deleting stack %s.\n", DebugNameForPointer(this) );
 	if( sFrontStack == this )
		sFrontStack = NULL;
	mCurrentCard = CCardRef(NULL);
	
	{
		auto saveBackgrounds = mBackgrounds;
		mBackgrounds.clear();
		for( auto itty = saveBackgrounds.begin(); itty != saveBackgrounds.end(); itty++ )
			(*itty)->SetStack( NULL );
		saveBackgrounds.clear();
	}
	{
		auto saveCards = mCards;
		mCards.clear();
		for( auto itty = saveCards.begin(); itty != saveCards.end(); itty++ )
		{
			(*itty)->SetStack( NULL );
		}
		saveCards.clear();
	}
	//printf("stack %s deleted.\n", DebugNameForPointer(this) );
}


void	CStack::Load( std::function<void(CStack*)> inCompletionBlock )
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
	
	Retain();
	
	CURLRequest		request( mURL );
	//printf("Loading %s\n",mURL.c_str());
	CURLConnection::SendRequestWithCompletionHandler( request, [this,inCompletionBlock] (CURLResponse inResponse, const char* inData, size_t inDataLength) -> void
	{
		tinyxml2::XMLDocument		document;
		bool						neededToConvertStackToLoad = false;
		
		if( tinyxml2::XML_SUCCESS == document.Parse( inData, inDataLength ) )
		{
			//document.Print();
			
			tinyxml2::XMLElement	*	root = document.RootElement();
			
			mStackID = CTinyXMLUtils::GetLongLongNamed( root, "id", mStackID );
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
			
			std::string	stackStyle("standard");
			CTinyXMLUtils::GetStringNamed( root, "style", stackStyle );
			mStyle = GetStackStyleFromString( stackStyle.c_str() );
			if( mStyle == EStackStyle_Last )
				mStyle = EStackStyleStandard;
			
			mScript.erase();
			CTinyXMLUtils::GetStringNamed( root, "script", mScript );
			
			LoadUserPropertiesFromElement( root );
			
			// Load backgrounds:
			tinyxml2::XMLElement	*	currBgElem = root->FirstChildElement( "background" );
			size_t			slashOffset = mURL.rfind( '/' );
			if( slashOffset == std::string::npos )
				slashOffset = 0;
			
			while( currBgElem )
			{
				std::string		backgroundURL = mURL.substr(0,slashOffset);
				backgroundURL.append( 1, '/' );
				backgroundURL.append( currBgElem->Attribute("file") );
				ObjectID		bgID = CTinyXMLUtils::GetLongLongAttributeNamed( currBgElem, "id" );
				const char*		theName = currBgElem->Attribute("name");
				
				CBackground	*	theBackground = new CBackground( backgroundURL, bgID, (theName ? theName : ""), currBgElem->Attribute("file"), this );
				theBackground->Autorelease();
				theBackground->SetStack( this );
				mBackgrounds.push_back( theBackground );
				
				currBgElem = currBgElem->NextSiblingElement( "background" );
			}

			// Load cards:
			tinyxml2::XMLElement	*	currCdElem = root->FirstChildElement( "card" );
			while( currCdElem )
			{
				std::string		cardURL = mURL.substr(0,slashOffset);
				cardURL.append( 1, '/' );
				cardURL.append( currCdElem->Attribute("file") );
				ObjectID		cdID = CTinyXMLUtils::GetLongLongAttributeNamed( currCdElem, "id" );
				const char*		theName = currCdElem->Attribute("name");
				const char*	markedAttrStr = currCdElem->Attribute("marked");
				bool			marked = markedAttrStr ? (strcmp("true", markedAttrStr) == 0) : false;
				ObjectID		bgID = CTinyXMLUtils::GetLongLongAttributeNamed( currCdElem, "owner" );
				CBackground	*	owningBackground = GetBackgroundByID( bgID );
				CCard	*	theCard = new CCard( cardURL, cdID, owningBackground, (theName ? theName : ""), currCdElem->Attribute("file"), this, marked );
				theCard->Autorelease();
				mCards.push_back( theCard );
				theCard->SetStack( this );
				if( marked )
					mMarkedCards.insert( theCard );
				if( !owningBackground )	// Don't have background ID in the stack's list?
				{
					theCard->Load([](CLayer *){ printf("Loaded card to get background ID\n"); });	// Load card so we can get the ID from its file.
					neededToConvertStackToLoad = true;
				}
				currCdElem = currCdElem->NextSiblingElement( "card" );
			}
		}
		
		if( !neededToConvertStackToLoad )
			mChangeCount = 0;
		CallAllCompletionBlocks();
		Release();
	} );
}


void	CStack::CallAllCompletionBlocks()
{
	mLoaded = true;
	mLoading = false;
	
	for( auto itty = mLoadCompletionBlocks.begin(); itty != mLoadCompletionBlocks.end(); itty++ )
		(*itty)( this );
	mLoadCompletionBlocks.clear();
}


bool	CStack::Save( const std::string& inPackagePath )
{
	if( !mLoaded )
		return true;
	
	SaveThumbnailIfFirstCardOpen();	// Make sure snapshot of first card is current.
		
	if( mChangeCount != 0 )	// We ourselves have changed? Write it out!
	{
		tinyxml2::XMLDocument		document;
		tinyxml2::XMLDeclaration*	declaration = document.NewDeclaration();
		declaration->SetValue("xml version=\"1.0\" encoding=\"utf-8\"");
		document.InsertEndChild( declaration );
		
		tinyxml2::XMLUnknown*	dtd = document.NewUnknown("DOCTYPE stack PUBLIC \"-//Apple, Inc.//DTD stack V 2.0//EN\" \"\"");
		document.InsertEndChild( dtd );
		
		tinyxml2::XMLElement*		root = document.NewElement("stack");
		document.InsertEndChild( root );
		
		CTinyXMLUtils::AddLongLongNamed( root, GetID(), "id" );
		
		tinyxml2::XMLElement*		nameElem = document.NewElement("name");
		nameElem->SetText(mName.c_str());
		root->InsertEndChild( nameElem );
		
		tinyxml2::XMLElement*		elem = NULL;
		if( mUserLevel != 5 )
		{
			elem = document.NewElement("userLevel");
			elem->SetText( mUserLevel );
			root->InsertEndChild( elem );
		}

		tinyxml2::XMLElement*		styleElem = document.NewElement("style");
		styleElem->SetText( sStackStyleStrings[mStyle] );
		root->InsertEndChild( styleElem );
		
		tinyxml2::XMLElement*		cardCountElem = document.NewElement("cardCount");
		cardCountElem->SetText((unsigned)mCards.size());
		root->InsertEndChild( cardCountElem );
		
		CTinyXMLUtils::AddBoolNamed( root, mCantModify, "cantModify" );
		CTinyXMLUtils::AddBoolNamed( root, mCantModify, "cantDelete" );
		CTinyXMLUtils::AddBoolNamed( root, mCantAbort, "cantAbort" );
		CTinyXMLUtils::AddBoolNamed( root, mPrivateAccess, "privateAccess" );
		CTinyXMLUtils::AddBoolNamed( root, mCantPeek, "cantPeek" );
		CTinyXMLUtils::AddBoolNamed( root, mResizable, "resizable" );

		tinyxml2::XMLElement*		cardSizeElem = document.NewElement("cardSize");
		tinyxml2::XMLElement*		cardSizeWidthElem = document.NewElement("width");
		cardSizeWidthElem->SetText( mCardWidth );
		cardSizeElem->InsertEndChild( cardSizeWidthElem );
		tinyxml2::XMLElement*		cardSizeHeightElem = document.NewElement("height");
		cardSizeHeightElem->SetText( mCardHeight );
		cardSizeElem->InsertEndChild( cardSizeHeightElem );
		root->InsertEndChild( cardSizeElem );

		tinyxml2::XMLElement*		scriptElem = document.NewElement("script");
		scriptElem->SetText( mScript.c_str() );
		root->InsertEndChild( scriptElem );
		
		SaveUserPropertiesToElementOfDocument( root, &document );
		
		for( auto currBackground : mBackgrounds )
		{
			tinyxml2::XMLElement*		bgElem = document.NewElement("background");
			CTinyXMLUtils::SetLongLongAttributeNamed( bgElem, currBackground->GetID(), "id");
			bgElem->SetAttribute( "file", currBackground->GetFileName().c_str() );
			bgElem->SetAttribute( "name", currBackground->GetName().c_str() );
			root->InsertEndChild( bgElem );
			
			if( currBackground->GetNeedsToBeSaved() )
			{
				if( !currBackground->Save( inPackagePath ) )
					return false;
			}
		}

		for( auto currCard : mCards )
		{
			tinyxml2::XMLElement*		cdElem = document.NewElement("card");
			CTinyXMLUtils::SetLongLongAttributeNamed( cdElem, currCard->GetID(), "id");
			cdElem->SetAttribute( "file", currCard->GetFileName().c_str() );
			cdElem->SetAttribute( "name", currCard->GetName().c_str() );
			CTinyXMLUtils::SetLongLongAttributeNamed( cdElem, currCard->GetBackground()->GetID(), "owner");
			root->InsertEndChild( cdElem );
			
			if( currCard->GetNeedsToBeSaved() )
			{
				if( !currCard->Save( inPackagePath ) )
					return false;
			}
		}

		std::string	stackFilePath(inPackagePath);
		if( stackFilePath[stackFilePath.length()-1] != '/' )
			stackFilePath.append( 1, '/' );
		stackFilePath.append(mFileName);
		FILE*	theFile = fopen( stackFilePath.c_str(), "w" );
		if( !theFile )
			return false;
		CStacksmithXMLPrinter	printer( theFile );
		document.Print( &printer );
		fclose(theFile);
		
		mChangeCount = 0;
	}
	else	// We return TRUE from GetNeedsToBeSaved() if a card or background has changed. So give it a chance to save even if we didn't change:
	{
		for( auto currBackground : mBackgrounds )
		{
			if( currBackground->GetNeedsToBeSaved() )
			{
				if( !currBackground->Save( inPackagePath ) )
					return false;
			}
		}

		for( auto currCard : mCards )
		{
			if( currCard->GetNeedsToBeSaved() )
			{
				if( !currCard->Save( inPackagePath ) )
					return false;
			}
		}
	}
	
	return true;
}


void	CStack::AddCard( CCard* inCard )
{
	inCard->SetStack( this );
	mCards.push_back( inCard );
	
	if( inCard->IsMarked() )
		mMarkedCards.insert( inCard );
	
	IncrementChangeCount();
}


void	CStack::InsertCardAfterCard( CCard* inNewCard, CCard *precedingCard )
{
	inNewCard->SetStack( this );
	if( precedingCard == NULL )
		mCards.insert( mCards.begin(), inNewCard );
	else
	{
		for( auto currCard = mCards.begin(); currCard != mCards.end(); currCard++ )
		{
			if( (*currCard) == precedingCard )
			{
				mCards.insert( currCard +1, inNewCard );
				break;
			}
		}
	}
	
	if( inNewCard->IsMarked() )
		mMarkedCards.insert( inNewCard );
	
	IncrementChangeCount();
}


void	CStack::RemoveCard( CCard* inCard )
{
	CCardRef	theCard( inCard );
	
	if( inCard->IsMarked() )
		mMarkedCards.erase( inCard );
	
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
	{
		if( (*itty) == inCard )
		{
			mCards.erase( itty );
			break;
		}
	}
	theCard->SetStack( NULL );
	
	IncrementChangeCount();
}


void	CStack::RemoveBackground( CBackground* inBg )
{
	CBackgroundRef		theBg( inBg );
	for( auto itty = mBackgrounds.begin(); itty != mBackgrounds.end(); itty++ )
	{
		if( (*itty) == inBg )
		{
			mBackgrounds.erase( itty );
			break;
		}
	}
	theBg->SetStack( NULL );
	
	IncrementChangeCount();
}


CCard*	CStack::GetCardByID( ObjectID inID )
{
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
	{
		if( (*itty)->GetID() == inID )
			return *itty;
	}
	
	return NULL;
}


CCard*	CStack::AddNewCard()
{
	return AddNewCardWithBackground( GetCurrentCard()->GetBackground() );
}


bool	CStack::DeleteCard( CCard* inCard )
{
	CBackgroundRef	theBg( inCard->GetBackground() );
	
	if( mCards.size() == 1 )	// Can't delete last card.
		return false;

	bool	lastCardInBg = theBg->GetNumCards() == 1;
	if( lastCardInBg && theBg->GetCantDelete() )
		return false;
	
	if( GetCurrentCard() == inCard )
	{
		GetPreviousCard()->GoThereInNewWindow( EOpenInSameWindow, this, NULL, [this,inCard,lastCardInBg,theBg]()
		{
			RemoveCard(inCard);
			
			if( lastCardInBg )
				RemoveBackground( theBg );
		} );
		
	}
	
	return true;
}


void	CStack::MarkedStateChangedOfCard( CCard* inCard )
{
	if( inCard->IsMarked() )
		mMarkedCards.insert( inCard );
	else
		mMarkedCards.erase( inCard );
	IncrementChangeCount();
}


CCard*	CStack::AddNewCardWithBackground( CBackground* inBg )
{
	size_t			slashOffset = mURL.rfind( '/' );
	if( slashOffset == std::string::npos )
		slashOffset = 0;
	
	if( inBg == NULL )
	{
		ObjectID				bgID = GetDocument()->GetUniqueIDForBackground();
		std::stringstream		bgName;
		std::string				bgURL( mURL.substr(0,slashOffset) );
		bgURL.append( 1, '/' );
		bgName << "background_" << bgID << ".xml";
		bgURL.append( bgName.str() );
		inBg = new CBackground( bgURL, bgID, "", bgName.str(), this );
		inBg->SetLoaded(true);
		inBg->IncrementChangeCount();
		AddBackground( inBg );
	}
	
	ObjectID				theID = GetDocument()->GetUniqueIDForCard();
	std::stringstream		cardName;
	std::string				cardURL( mURL.substr(0,slashOffset) );
	cardURL.append( 1, '/' );
	cardName << "card_" << theID << ".xml";
	cardURL.append( cardName.str() );
	CCard	*	theCard = new CCard( cardURL, theID, inBg, "", cardName.str(), this, false );
	theCard->SetLoaded(true);
	theCard->IncrementChangeCount();
	InsertCardAfterCard( theCard, GetCurrentCard() );
	theCard->Autorelease();
	
	return theCard;
}


void	CStack::SetCurrentCard( CCard* inCard )
{
	mCurrentCard = inCard;
}


size_t	CStack::GetNumCardsWithBackground( CBackground* inBg )
{
	size_t	count = 0;
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
	{
		if( (*itty)->GetBackground() == inBg )
		{
			count++;
		}
	}
	
	return count;
}


CCard*	CStack::GetCardAtIndexWithBackground( size_t cardIdx, CBackground* inBg )
{
	size_t	currIdx = 0;
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
	{
		if( (*itty)->GetBackground() == inBg )
		{
			if( cardIdx == currIdx )
				return *itty;
			currIdx++;
		}
	}
	
	return NULL;
}


CCard*	CStack::GetCardWithBackground( CBackground* inBg, CCard *startAtCard, bool searchForward )
{
	bool		hadStartCard = (startAtCard == NULL);
	if( searchForward )
	{
		for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
		{
			if( *itty == startAtCard )
			{
				hadStartCard = true;
				continue;
			}
			if( !hadStartCard )
				continue;
			if( (*itty)->GetBackground() == inBg )
				return *itty;
		}
		
		for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
		{
			if( (*itty)->GetBackground() == inBg )
				return *itty;
		}
	}
	else
	{
		for( auto itty = mCards.rbegin(); itty != mCards.rend(); itty++ )
		{
			if( *itty == startAtCard )
			{
				hadStartCard = true;
				continue;
			}
			if( !hadStartCard )
				continue;
			if( (*itty)->GetBackground() == inBg )
				return *itty;
		}
		
		for( auto itty = mCards.rbegin(); itty != mCards.rend(); itty++ )
		{
			if( (*itty)->GetBackground() == inBg )
				return *itty;
		}
	}
	
	return NULL;
}


void	CStack::AddBackground( CBackground* inBackground )
{
	inBackground->SetStack( this );
	mBackgrounds.push_back( inBackground );
	
	IncrementChangeCount();
}


CBackground*	CStack::GetBackgroundByID( ObjectID inID )
{
	for( auto itty = mBackgrounds.begin(); itty != mBackgrounds.end(); itty++ )
	{
		if( (*itty)->GetID() == inID )
			return *itty;
	}
	
	return NULL;
}


CCard*	CStack::GetCardByName( const char* inName )
{
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
	{
		if( strcasecmp( (*itty)->GetName().c_str(), inName ) == 0 )
			return *itty;
	}
	
	return NULL;
}


CBackground*	CStack::GetBackgroundByName( const char* inName )
{
	for( auto itty = mBackgrounds.begin(); itty != mBackgrounds.end(); itty++ )
	{
		if( strcasecmp( (*itty)->GetName().c_str(), inName ) == 0 )
			return *itty;
	}
	
	return NULL;
}


size_t	CStack::GetIndexOfCard( CCard* inCard )
{
	size_t		currIdx = 0;
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
	{
		if( (*itty) == inCard )
			return currIdx;
		currIdx++;
	}
	return SIZE_T_MAX;
}


void	CStack::SetIndexOfCardTo( CCard* inCd, size_t newIndex )
{
	CCardRef	holdOnToBgWhileWeMoveIt(inCd);
	for( auto itty = mCards.begin(); itty != mCards.end(); itty++ )
	{
		if( (*itty) == inCd )
		{
			mCards.erase(itty);
			break;
		}
	}
	
	auto itty = mCards.begin() +newIndex;
	mCards.insert(itty, inCd);
	
	IncrementChangeCount();
}


CCard*	CStack::GetNextCard()
{
	size_t			cardIdx = GetIndexOfCard(mCurrentCard);
	cardIdx++;
	if( cardIdx >= mCards.size() )
		cardIdx = 0;
	return mCards[cardIdx];
}


CCard*	CStack::GetPreviousCard()
{
	size_t			cardIdx = GetIndexOfCard(mCurrentCard);
	if( cardIdx == 0 )
		cardIdx = mCards.size() -1;
	else
		cardIdx--;
	return mCards[cardIdx];
}


size_t	CStack::GetIndexOfBackground( CBackground* inBackground )
{
	size_t		currIdx = 0;
	for( auto currBg : mBackgrounds )
	{
		if( currBg == inBackground )
			return currIdx;
		currIdx++;
	}
	return SIZE_T_MAX;
}


void	CStack::SetIndexOfBackgroundTo( CBackground* inBg, size_t newIndex )
{
	CBackgroundRef	holdOnToBgWhileWeMoveIt(inBg);
	for( auto itty = mBackgrounds.begin(); itty != mBackgrounds.end(); itty++ )
	{
		if( (*itty) == inBg )
		{
			mBackgrounds.erase(itty);
			break;
		}
	}
	
	auto itty = mBackgrounds.begin() +newIndex;
	mBackgrounds.insert(itty, inBg);
	
	IncrementChangeCount();
}


void	CStack::SetPeeking( bool inState )
{
	mPeeking = inState;
	CCard	*	theCard = GetCurrentCard();
	if( theCard )
		theCard->SetPeeking( inState );
}


void	CStack::DeselectAllObjectsOnCard()
{
	CCard	*	theCard = GetCurrentCard();
	size_t	numParts = theCard->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
		theCard->GetPart(x)->SetSelected(false);
}


void	CStack::SelectAllObjectsOnCard()
{
	CCard	*	theCard = GetCurrentCard();
	size_t	numParts = theCard->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
		theCard->GetPart(x)->SetSelected(true);
}


void	CStack::DeselectAllObjectsOnBackground()
{
	CCard	*	theCard = GetCurrentCard();
	size_t numParts = theCard->GetBackground()->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
		theCard->GetBackground()->GetPart(x)->SetSelected(false);
}


void	CStack::SelectAllObjectsOnBackground()
{
	CCard	*	theCard = GetCurrentCard();
	size_t numParts = theCard->GetBackground()->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
		theCard->GetBackground()->GetPart(x)->SetSelected(true);
}


void	CStack::SetTool( TTool inTool )
{
	if( inTool != mCurrentTool )
	{
		TTool		oldTool = mCurrentTool;
		mCurrentTool = inTool;
		
		if( GetCurrentCard() )
		{
			GetCurrentCard()->ToolChangedFrom( oldTool );
			GetCurrentCard()->GetBackground()->ToolChangedFrom( oldTool );
		}
	}
}


void	CStack::SetName( const std::string &inName )
{
	if( mName.compare(inName) != 0 )
	{
		CConcreteObject::SetName( inName );
		
		mDocument->IncrementChangeCount();	// Stack list contains our name so we needn't be loaded just to find another card by name, make sure that's updated.
	}
}


void	CStack::IncrementChangeCount()
{
	mChangeCount++;
}


bool	CStack::GetNeedsToBeSaved()
{
	if( mChangeCount != 0 )
		return true;
	
	for( auto currBackground : mBackgrounds )
	{
		if( currBackground->GetNeedsToBeSaved() )
			return true;
	}

	for( auto currCard : mCards )
	{
		if( currCard->GetNeedsToBeSaved() )
			return true;
	}

	return false;
}


void	CStack::SetVisible( bool n )
{
	mVisible = n;
	
	if( !mVisible )
	{
		GetDocument()->CheckIfWeShouldCloseCauseLastStackClosed();
	}
}


void	CStack::SaveThumbnail()
{
}


void	CStack::Dump( size_t inIndent )
{
	const char * indentStr = IndentString( inIndent );
	printf( "%sStack ID %lld \"%s\" <%p>\n%s{\n", indentStr, mStackID, mName.c_str(), this, indentStr );
	printf( "%s\tstyle = %s\n", indentStr, sStackStyleStrings[mStyle] );
	printf( "%s\tloaded = %s\n", indentStr, (mLoaded? "true" : "false") );
	printf( "%s\tuserLevel = %d\n", indentStr, mUserLevel );
	printf( "%s\twidth = %d\n", indentStr, mCardWidth );
	printf( "%s\theight = %d\n", indentStr, mCardHeight );
	printf( "%s\tcantPeek = %s\n", indentStr, (mCantPeek? "true" : "false") );
	printf( "%s\tcantAbort = %s\n", indentStr, (mCantAbort? "true" : "false") );
	printf( "%s\tprivateAccess = %s\n", indentStr, (mPrivateAccess? "true" : "false") );
	printf( "%s\tcantDelete = %s\n", indentStr, (mCantDelete? "true" : "false") );
	printf( "%s\tcantModify = %s\n", indentStr, (mCantModify? "true" : "false") );
	printf( "%s\tresizable = %s\n", indentStr, (mResizable? "true" : "false") );
	printf( "%s\tneedsToBeSaved = %s\n", indentStr, ((mChangeCount != 0)? "true" : "false") );
	printf( "%s\tscript = <<%s>>\n", indentStr, mScript.c_str() );
	DumpUserProperties( inIndent +1 );
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


bool	CStack::GetEffectiveCantModify()
{
	return mCantModify || mDocument->IsWriteProtected();
}


bool	CStack::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
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
	else if( strcasecmp(inPropertyName, "style") == 0 )
	{
		LEOInitStringConstantValue( outValue, sStackStyleStrings[mStyle], kLEOInvalidateReferences, inContext );
		return true;
	}
	else if( strcasecmp(inPropertyName, "resizable") == 0 )
	{
		LEOInitBooleanValue( outValue, mResizable, kLEOInvalidateReferences, inContext );
		return true;
	}
	else
		return CConcreteObject::GetPropertyNamed(inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
}


bool	CStack::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
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
	else if( strcasecmp(inPropertyName, "style") == 0 )
	{
		char		styleBuf[100] = {0};
		const char*	styleStr = LEOGetValueAsString( inValue, styleBuf, sizeof(styleBuf), inContext );
		TStackStyle		style = GetStackStyleFromString(styleStr);
		if( style != EStackStyle_Last )
			SetStyle( style );
		return true;
	}
	else if( strcasecmp(inPropertyName, "resizable") == 0 )
	{
		bool			canResize = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) != 0 )
		{
			SetResizable( canResize );
		}
		return true;
	}
	else
		return CConcreteObject::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
}


/*static*/ const char*	CStack::GetToolName( TTool inTool )
{
	return sToolNames[inTool];
}


/*static*/ TTool	CStack::GetToolFromName( const char* inName )
{
	for( int x = 0; x < ETool_Last; x++ )
	{
		if( strcasecmp(inName, sToolNames[x]) == 0 )
			return x;
	}
	return ETool_Last;
}


/*static*/ TStackStyle	CStack::GetStackStyleFromString( const char* inStyleStr )
{
	for( size_t x = 0; x < EStackStyle_Last; x++ )
	{
		if( strcasecmp(sStackStyleStrings[x],inStyleStr) == 0 )
			return (TStackStyle)x;
	}
	return EStackStyle_Last;
}



/*static*/ void		CStack::SetFrontStack( CStack* inStack )
{
	sFrontStack = inStack;
	CDocumentManager::GetSharedDocumentManager()->SetFrontDocument( inStack ? inStack->GetDocument() : NULL );
	if( sFrontStackChangedBlock )
		sFrontStackChangedBlock( inStack );
}



