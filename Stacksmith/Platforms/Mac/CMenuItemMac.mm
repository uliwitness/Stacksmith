//
//  CMenuItemMac.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 12/02/17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CMenuItemMac.h"
#include "CMenuMac.h"
#import "WILDMenuItemInfoViewController.h"
#import "UKHelperMacros.h"


using namespace Carlson;


CMenuItemMac::CMenuItemMac( CMenu * inParent )
: CMenuItem( inParent )
{
	if( mStyle == EMenuItemStyleStandard )
	{
		mMacMenuItem = [[NSMenuItem alloc] initWithTitle: @"" action: @selector(projectMenuItemSelected:) keyEquivalent: @""];
	}
	else
	{
		mMacMenuItem = [[NSMenuItem separatorItem] retain];
	}
	mMacMenuItem.tag = (intptr_t) this;
	CMenuMac * theMenu = dynamic_cast<CMenuMac*>(inParent);
	[theMenu->GetMacMenu() addItem: mMacMenuItem];
}


CMenuItemMac::~CMenuItemMac()
{
	[mMacMenuItem.menu removeItem: mMacMenuItem];
	DESTROY_DEALLOC(mMacMenuItem);
}

		
void	CMenuItemMac::SetName( const std::string& inName )
{
	CMenuItem::SetName(inName);
	
	mMacMenuItem.title = [NSString stringWithUTF8String: mName.c_str()];
}


void	CMenuItemMac::SetCommandChar( const std::string& inName )
{
	CMenuItem::SetCommandChar( inName );
	
	mMacMenuItem.keyEquivalent = [NSString stringWithUTF8String: mCommandChar.c_str()];
}


void	CMenuItemMac::SetVisible( bool inState )
{
	CMenuItem::SetVisible(inState);
	
	mMacMenuItem.hidden = !mVisible;
}


void	CMenuItemMac::SetStyle( TMenuItemStyle inStyle )
{
	if( inStyle != mStyle )
	{
		CMenuItem::SetStyle( inStyle );
		
		NSMenu * theMenu = mMacMenuItem.menu;
		NSUInteger theItemIndex = [theMenu indexOfItem: mMacMenuItem];
		[theMenu removeItem: mMacMenuItem];
		DESTROY_DEALLOC(mMacMenuItem);
		if( mStyle == EMenuItemStyleStandard )
		{
			mMacMenuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithUTF8String: mName.c_str()] action: @selector(projectMenuItemSelected:) keyEquivalent: @""];
		}
		else
		{
			mMacMenuItem = [[NSMenuItem separatorItem] retain];
		}
		mMacMenuItem.tag = (intptr_t) this;
		[theMenu insertItem: mMacMenuItem atIndex: theItemIndex];
	}
}


void	CMenuItemMac::SetToolTip( const std::string& inToolTip )
{
	CMenuItem::SetToolTip( inToolTip );
	
	mMacMenuItem.toolTip = [NSString stringWithUTF8String: mToolTip.c_str()];
}


void	CMenuItemMac::LoadFromElement( tinyxml2::XMLElement* inElement )
{
	CMenuItem::LoadFromElement( inElement );
	
	mMacMenuItem.title = [NSString stringWithUTF8String: mName.c_str()];
	mMacMenuItem.keyEquivalent = [NSString stringWithUTF8String: mCommandChar.c_str()];
	mMacMenuItem.hidden = !mVisible;
	mMacMenuItem.enabled = mEnabled;
	mMacMenuItem.toolTip = [NSString stringWithUTF8String: mToolTip.c_str()];
}

WILDNSImagePtr	CMenuItemMac::GetDisplayIcon()
{
	return [NSImage imageNamed: @"MenuItemIconSmall"];
}


Class	CMenuItemMac::GetPropertyEditorClass()
{
	return [WILDMenuItemInfoViewController class];
}
