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
	
	tinyxml2::XMLElement*	elem = document->NewElement("owner");
	elem->SetText( mOwningBackground->GetID() );
	stackfile->InsertEndChild(elem);
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


bool	CCard::GoThereInNewWindow( bool inNewWindow, CStack* oldStack )
{
	Retain();
	Load([this,oldStack,inNewWindow](CLayer *inThisCard)
	{
		CCard	*	oldCard = oldStack ? oldStack->GetCurrentCard() : NULL;
		bool		destStackWasntOpenYet = GetStack()->GetCurrentCard() == NULL;
		// We're moving away
		if( oldCard && oldStack && oldStack != GetStack() && !inNewWindow )	// Leaving this stack? Close it.
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

