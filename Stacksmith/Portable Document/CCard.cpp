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


using namespace Calhoun;


void	CCard::LoadPropertiesFromElement( tinyxml2::XMLElement* root )
{
	CLayer::LoadPropertiesFromElement( root );
	
	WILDObjectID owningBackgroundID = CTinyXMLUtils::GetLongLongNamed( root, "owner", 0 );
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
