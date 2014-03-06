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


using namespace Carlson;


CCard::~CCard()
{
	if( mOwningBackground )
		mOwningBackground->RemoveCard( this );
}


void	CCard::LoadPropertiesFromElement( tinyxml2::XMLElement* root )
{
	CLayer::LoadPropertiesFromElement( root );
	
	ObjectID owningBackgroundID = CTinyXMLUtils::GetLongLongNamed( root, "owner", 0 );
	mOwningBackground = mStack->GetBackgroundByID( owningBackgroundID );
	mOwningBackground->AddCard( this );
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


void	CCard::SavePropertiesToElementOfDocument( tinyxml2::XMLElement* stackfile, tinyxml2::XMLDocument* document )
{
	CLayer::SavePropertiesToElementOfDocument( stackfile, document );
	
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


CScriptableObject*	CCard::GetParentObject()
{
	return mOwningBackground;
}


bool	CCard::GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler )
{
	Retain();
	Load([this,oldStack,inOpenInMode,completionHandler](CLayer *inThisCard)
	{
		CCard	*	oldCard = oldStack ? oldStack->GetCurrentCard() : NULL;
		bool		destStackWasntOpenYet = GetStack()->GetCurrentCard() == NULL;
		// We're moving away
		if( oldCard && oldStack && oldStack != GetStack() && inOpenInMode == EOpenInSameWindow )	// Leaving this stack? Close it.
		{
			CAutoreleasePool		pool;
			oldCard->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "closeCard" );
			oldCard->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "closeStack" );
			oldCard->GoToSleep();
			oldStack->SetCurrentCard(NULL);
		}
		if( GetStack()->GetCurrentCard() != NULL && GetStack()->GetCurrentCard() != this )	// Dest stack was already open with another card? Close that card (too).
		{
			CAutoreleasePool		pool;
			GetStack()->GetCurrentCard()->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "closeCard" );
			GetStack()->GetCurrentCard()->GoToSleep();
		}
		
		if( GetStack()->GetCurrentCard() != this )	// Dest stack didn't already have this card open?
		{
			GetStack()->SetCurrentCard( this );	// Go there!
			
			WakeUp();
			if( destStackWasntOpenYet )
			{
				CAutoreleasePool		pool;
				SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "openStack" );
			}
			CAutoreleasePool		pool;
			SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "openCard" );
		}
			
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
			LEOContextStopWithError( inContext, SIZE_T_MAX, SIZE_T_MAX, 0, "Card number must be between 1 and %zu.", GetStack()->GetNumCards() );
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


std::string		CCard::GetDisplayName()
{
	std::stringstream		strs;
	if( mName.length() > 0 )
		strs << "Card \"" << mName << "\"";
	else
		strs << "Card ID " << GetID();
	return strs.str();
}



