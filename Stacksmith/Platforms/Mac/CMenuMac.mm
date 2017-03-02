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
#import "UKHelperMacros.h"


using namespace Carlson;


CMenuMac::CMenuMac( CDocument* inDocument )
	: CMenu(inDocument)
{
	mMacMenu = [[NSMenu alloc] initWithTitle: @"Untitled"];
	mOwningMacMenuItem = [[NSMenuItem alloc] initWithTitle: @"Untitled" action: Nil keyEquivalent: @""];
	mOwningMacMenuItem.submenu = mMacMenu;
	mOwningMacMenuItem.tag = (intptr_t) this;
}


CMenuMac::~CMenuMac()
{
	[mOwningMacMenuItem.menu removeItem: mOwningMacMenuItem];
	DESTROY_DEALLOC(mMacMenu);
	DESTROY_DEALLOC(mOwningMacMenuItem);
}


CMenuItem*	CMenuMac::NewMenuItemWithElement( tinyxml2::XMLElement* inElement, TMenuItemMarkChangedFlag inMarkChanged )
{
	CMenuItemRef	newItem( new CMenuItemMac( this ), true );
	newItem->LoadFromElement( inElement );
	mItems.push_back( newItem );
	
	if( inMarkChanged == EMenuItemMarkChanged )
		mDocument->MenuIncrementedChangeCount( newItem, this, true );
	
	return newItem;
}


void	CMenuMac::LoadFromElement( tinyxml2::XMLElement* inElement )
{
	CMenu::LoadFromElement( inElement );

	NSString * nameStr = [NSString stringWithUTF8String: mName.c_str()];
	mMacMenu.title = nameStr;
	mOwningMacMenuItem.title = nameStr;
	NSString * toolTipStr = [NSString stringWithUTF8String: mToolTip.c_str()];
	mOwningMacMenuItem.toolTip = toolTipStr;
	mOwningMacMenuItem.hidden = !mVisible;
	mOwningMacMenuItem.enabled = mEnabled;
}


void	CMenuMac::SetToolTip( std::string inStr )
{
	CMenu::SetToolTip( inStr );
	
	NSString * toolTipStr = [NSString stringWithUTF8String: mToolTip.c_str()];
	mOwningMacMenuItem.toolTip = toolTipStr;
}


void	CMenuMac::SetName( const std::string& inStr )
{
	CMenu::SetName( inStr );
	
	NSString * nameStr = [NSString stringWithUTF8String: mName.c_str()];
	mMacMenu.title = nameStr;
	mOwningMacMenuItem.title = nameStr;
}


void	CMenuMac::SetEnabled( bool inState )
{
	CMenu::SetEnabled( inState );
	
	mOwningMacMenuItem.enabled = inState;
}


void	CMenuMac::SetVisible( bool inState )
{
	CMenu::SetVisible( inState );
	
	mOwningMacMenuItem.hidden = !inState;
}


WILDNSImagePtr	CMenuMac::GetDisplayIcon()
{
	return [NSImage imageNamed: @"MenuIconSmall"];
}


Class	CMenuMac::GetPropertyEditorClass()
{
	return [WILDConcreteObjectInfoViewController class];
}
