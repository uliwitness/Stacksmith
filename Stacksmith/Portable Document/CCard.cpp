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


using namespace Carlson;


void	CCard::LoadPropertiesFromElement( tinyxml2::XMLElement* root )
{
	CLayer::LoadPropertiesFromElement( root );
	
	ObjectID owningBackgroundID = CTinyXMLUtils::GetLongLongNamed( root, "owner", 0 );
	mOwningBackground = mStack->GetBackgroundByID( owningBackgroundID );
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


bool	CCard::GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart )
{
	Retain();
	Load([this,oldStack,inOpenInMode](CLayer *inThisCard)
	{
		CCard	*	oldCard = oldStack ? oldStack->GetCurrentCard() : NULL;
		bool		destStackWasntOpenYet = GetStack()->GetCurrentCard() == NULL;
		// We're moving away
		if( oldCard && oldStack && oldStack != GetStack() && inOpenInMode == EOpenInSameWindow )	// Leaving this stack? Close it.
		{
			oldCard->SendMessage( NULL, [](const char *errMsg, size_t, size_t, CScriptableObject *){ if( errMsg ) CAlert::RunMessageAlert( errMsg ); }, "closeCard" );
			oldCard->SendMessage( NULL, [](const char *errMsg, size_t, size_t, CScriptableObject *){ if( errMsg ) CAlert::RunMessageAlert( errMsg ); }, "closeStack" );
			oldCard->GoToSleep();
			oldStack->SetCurrentCard(NULL);
		}
		if( GetStack()->GetCurrentCard() != NULL && GetStack()->GetCurrentCard() != this )	// Dest stack was already open with another card? Close that card (too).
		{
			GetStack()->GetCurrentCard()->SendMessage( NULL, [](const char *errMsg, size_t, size_t, CScriptableObject *){ if( errMsg ) CAlert::RunMessageAlert( errMsg ); }, "closeCard" );
			GetStack()->GetCurrentCard()->GoToSleep();
		}
		
		if( GetStack()->GetCurrentCard() != this )	// Dest stack didn't already have this card open?
		{
			GetStack()->SetCurrentCard( this );	// Go there!
			
			WakeUp();
			if( destStackWasntOpenYet )
			{
				SendMessage( NULL, [](const char *errMsg, size_t, size_t, CScriptableObject *){ if( errMsg ) CAlert::RunMessageAlert( errMsg ); }, "openStack" );
			}
			SendMessage( NULL, [](const char *errMsg, size_t, size_t, CScriptableObject *){ if( errMsg ) CAlert::RunMessageAlert( errMsg ); }, "openCard" );
		}
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
			LEOContextStopWithError( inContext, "Card number must be between 1 and %zu.", GetStack()->GetNumCards() );
		}
		else
		{
			GetStack()->SetIndexOfCardTo( this, number -1 );
		}
		return true;
	}
	else
		return CLayer::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
}

