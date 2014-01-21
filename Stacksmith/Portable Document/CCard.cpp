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

