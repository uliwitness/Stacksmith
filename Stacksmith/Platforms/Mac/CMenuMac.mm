//
//  CMenuMac.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 12/02/17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CMenuMac.h"
#include "CMenuItemMac.h"
#include "CDocument.h"
#import "WILDConcreteObjectInfoViewController.h"


using namespace Carlson;


CMenuItem*	CMenuMac::NewMenuItemWithElement( tinyxml2::XMLElement* inElement )
{
	CMenuItemRef	newItem( new CMenuItemMac( this ), true );
	newItem->LoadFromElement( inElement );
	mItems.push_back( newItem );
	mDocument->MenuIncrementedChangeCount( newItem, this, true );
	
	return newItem;
}


WILDNSImagePtr	CMenuMac::GetDisplayIcon()
{
	return [NSImage imageNamed: @"MenuIconSmall"];
}


Class	CMenuMac::GetPropertyEditorClass()
{
	return [WILDConcreteObjectInfoViewController class];
}
