//
//  CCard.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CCard.h"
#include "CStack.h"
#include "CTinyXMLUtils.h"
#include "CAlert.h"
#include <sstream>
#include "CDocument.h"


using namespace Carlson;

CCard::CCard( std::string inURL, ObjectID inID, CBackground* inOwningBackground, const std::string& inName, const std::string& inFileName, CStack* inStack, bool inMarked )
	: CPlatformLayer(inURL,inID,inName,inFileName,inStack), mMarked(inMarked), mOwningBackground(inOwningBackground)
{
	//printf("card %s created.\n", DebugNameForPointer(this) );
	if( mOwningBackground )
        mOwningBackground->AddCard(this);
}

CCard::~CCard()
{
	//printf("deleting card %s.\n", DebugNameForPointer(this) );
 	if( mOwningBackground )
		mOwningBackground->RemoveCard( this );
 	//printf("card %s deleted.\n", DebugNameForPointer(this) );
}


void	CCard::LoadPropertiesFromElement( tinyxml2::XMLElement* root )
{
	CLayer::LoadPropertiesFromElement( root );
	
	if( mOwningBackground == NULL )	// We had no "owner" entry in stack TOC? Grab it from card file contents and make sure we re-save list of cards
	{
		ObjectID owningBackgroundID = CTinyXMLUtils::GetLongLongNamed( root, "owner", 0 );
		mOwningBackground = mStack->GetBackgroundByID( owningBackgroundID );
		mOwningBackground->AddCard( this );
		mStack->IncrementChangeCount();
	}
}


void	CCard::CallAllCompletionBlocks()
{
	if( !mOwningBackground->IsLoaded() )
	{
		mOwningBackground->Load( [this](CLayer *inBackground)
		{
			CLayer::CallAllCompletionBlocks();
		});
	}
	else
		CLayer::CallAllCompletionBlocks();
}


void	CCard::SavePropertiesToElement( tinyxml2::XMLElement* stackfile )
{
	CLayer::SavePropertiesToElement( stackfile );
	
	CTinyXMLUtils::AddLongLongNamed( stackfile, mOwningBackground->GetID(), "owner" );
}

void	CCard::WakeUp()
{
	CLayer::WakeUp();
	
	mOwningBackground->WakeUp();
}


void	CCard::GoToSleep()
{
	CLayer::GoToSleep();
	
	mOwningBackground->GoToSleep();
}


void	CCard::SetPeeking( bool inState )
{
	mOwningBackground->SetPeeking(inState);
	CLayer::SetPeeking(inState);
}


CScriptableObject*	CCard::GetParentObject( CScriptableObject* previousParent )
{
	return mOwningBackground;
}


bool	CCard::GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler, const std::string& inEffectType, TVisualEffectSpeed inSpeed )
{
	Retain();
	Load([this,oldStack,inOpenInMode,completionHandler,inEffectType,inSpeed](CLayer *inThisCard)
	{
		//inThisCard->Dump();
		CCard		*	oldCard = oldStack ? oldStack->GetCurrentCard() : NULL;
		CBackground	*	oldBackground = oldCard ? oldCard->GetBackground() : NULL;
		CBackground	*	thisBackground = inThisCard ? dynamic_cast<CCard*>(inThisCard)->GetBackground() : NULL;
		bool			destStackWasntOpenYet = GetStack()->GetCurrentCard() == NULL;
		bool			thisIsANewBackground = false;
		
		if( oldStack && oldCard == oldStack->GetCard(0) )
			oldStack->SaveThumbnail();

		// We're moving away
		if( oldCard && oldStack && oldStack != GetStack() && inOpenInMode == EOpenInSameWindow )	// Leaving this stack? Close it.
		{
			oldCard->DeselectAllItems();
			oldCard->GetBackground()->DeselectAllItems();
			
			CAutoreleasePool		pool;
			oldCard->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "closeCard" );
			if( oldBackground != thisBackground )
			{
				oldCard->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "closeBackground" );
			}
			oldCard->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "closeStack" );
			oldCard->GoToSleep();
			oldStack->SetCurrentCard(NULL);
		}
		//printf("Moved away from card %p\n", oldCard);
		if( GetStack()->GetCurrentCard() != NULL && GetStack()->GetCurrentCard() != this )	// Dest stack was already open with another card? Close that card (too).
		{
			if( oldCard )
            {
                oldCard->DeselectAllItems();
                oldCard->GetBackground()->DeselectAllItems();
			}
            
			CAutoreleasePool		pool;
			GetStack()->GetCurrentCard()->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "closeCard" );
			thisIsANewBackground = GetStack()->GetCurrentCard()->GetBackground() != thisBackground;
			if( thisIsANewBackground )
			{
				GetStack()->GetCurrentCard()->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "closeBackground" );
			}
			GetStack()->GetCurrentCard()->GoToSleep();
		}
		//printf("Moved away from card in dest stack\n");
		
		if( GetStack()->GetCurrentCard() != this )	// Dest stack didn't already have this card open?
		{
			thisIsANewBackground = GetStack()->GetCurrentCard() == NULL || GetStack()->GetCurrentCard()->GetBackground() != thisBackground;
			
			//printf("Opening new card\n");
			GetStack()->SetCurrentCard( this, inEffectType, inSpeed );	// Go there!
			
			WakeUp();
			if( !CDocumentManager::GetSharedDocumentManager()->GetDidSendStartup() )
			{
				CDocumentManager::GetSharedDocumentManager()->SetDidSendStartup(true);
				CAutoreleasePool		pool;
				SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "startup" );
			}
			if( destStackWasntOpenYet )
			{
				CAutoreleasePool		pool;
				SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "openStack" );
			}
			if( thisIsANewBackground )
			{
				CAutoreleasePool		pool;
				SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "openBackground" );
			}
			CAutoreleasePool		pool;
			SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "openCard" );
			//printf("Opened new card\n");
		}
			
		GetStack()->Show( EOnlyIfNotVisible );
		//printf("Calling card completion handler.\n");
		completionHandler();
		Release();
	});
	
	return true;
}


bool	CCard::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp(inPropertyName, "number") == 0 )
	{
		LEOInitIntegerValue( outValue, GetStack()->GetIndexOfCard(this) +1, kLEOUnitNone, kLEOInvalidateReferences, inContext );
		return true;
	}
	else if( strcasecmp(inPropertyName, "marked") == 0 )
	{
		LEOInitBooleanValue( outValue, mMarked, kLEOInvalidateReferences, inContext );
		return true;
	}
	else
		return CLayer::GetPropertyNamed(inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
}


bool	CCard::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp(inPropertyName, "number") == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEOInteger	number = LEOGetValueAsInteger( inValue, &theUnit, inContext );
		if( number <= 0 || number > (LEOInteger)GetStack()->GetNumCards() )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Card number must be between 1 and %zu.", GetStack()->GetNumCards() );
		}
		else
		{
			GetStack()->SetIndexOfCardTo( this, number -1 );
		}
		return true;
	}
	else if( strcasecmp(inPropertyName, "marked") == 0 )
	{
		bool	newState = LEOGetValueAsBoolean( inValue, inContext );
		if( inContext->flags & kLEOContextKeepRunning )
			SetMarked( newState );
		return true;
	}
	else
		return CLayer::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
}


void	CCard::SetMarked( bool inMarked )
{
	mMarked = inMarked;
	GetStack()->MarkedStateChangedOfCard( this );
}


void	CCard::CorrectRectOfPart( CPart* inMovedPart, THitPart partsToCorrect, long long *ioLeft, long long *ioTop, long long *ioRight, long long *ioBottom, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock )
{
	std::vector<CPartRef>	parts( mParts );
	GetBackground()->AddPartsToList( parts );
	CPlatformLayer::CorrectRectOfPart( inMovedPart, parts, partsToCorrect, ioLeft, ioTop, ioRight, ioBottom, addGuidelineBlock );
}


std::string		CCard::GetDisplayName()
{
	std::stringstream		strs;
	if( mName.length() > 0 )
		strs << "Card \"" << mName << "\"";
	else
		strs << "Card ID " << GetID();
	return strs.str();
}



