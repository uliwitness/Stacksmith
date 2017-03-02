//
//  CMenuMac.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 12/02/17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#pragma once

#include "CMenu.h"
#include "CMacScriptableObjectBase.h"
#include <objc/objc.h>


#if __OBJC__
@class NSMenu;
@class NSMenuItem;
typedef NSMenu *WILDNSMenuPtr;
typedef NSMenuItem *WILDNSMenuItemPtr;
#else
typedef struct NSMenu *WILDNSMenuPtr;
typedef struct NSMenuItem *WILDNSMenuItemPtr;
#endif


namespace Carlson {
	
	class CMenuMac : public CMenu, public CMacScriptableObjectBase
	{
	public:
		explicit CMenuMac( CDocument* inDocument );
		~CMenuMac();

		virtual CMenuItem*	NewMenuItemWithElement( tinyxml2::XMLElement* inElement, TMenuItemMarkChangedFlag markChanged = EMenuItemMarkChanged ) override;
		virtual void			LoadFromElement( tinyxml2::XMLElement* inElement ) override;

		virtual WILDNSImagePtr	GetDisplayIcon() override;
		virtual Class			GetPropertyEditorClass() override;
		virtual void			OpenScriptEditorAndShowOffset( size_t byteOffset ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowOffset( byteOffset ); }
		virtual void			OpenScriptEditorAndShowLine( size_t lineIndex ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowLine( lineIndex ); }

		virtual void			SetToolTip( std::string inStr ) override;
		virtual void			SetName( const std::string& inStr ) override;
		virtual void			SetEnabled( bool inState ) override;
		virtual void			SetVisible( bool inState ) override;

		virtual void			SetIndexOfItem( CMenuItem* inItem, LEOInteger inIndex ) override;
		
		virtual WILDNSMenuPtr		GetMacMenu()			{ return mMacMenu; }
		virtual WILDNSMenuItemPtr	GetOwningMacMenuItem()	{ return mOwningMacMenuItem; }
		
	protected:
		WILDNSMenuPtr		mMacMenu = nil;
		WILDNSMenuItemPtr	mOwningMacMenuItem = nil;
	};
	
}

