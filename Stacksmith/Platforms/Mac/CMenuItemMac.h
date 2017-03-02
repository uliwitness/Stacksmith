//
//  CMenuItemMac.hpp
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
@class NSMenuItem;
typedef NSMenuItem *WILDNSMenuItemPtr;

@protocol WILDMacMenuItemTarget
-(IBAction) projectMenuItemSelected: (NSMenuItem*)sender;
@end
#else
typedef struct NSMenuItem *WILDNSMenuItemPtr;
#endif


namespace Carlson
{
	class CMenuItemMac : public CMenuItem, public CMacScriptableObjectBase
	{
	public:
		explicit CMenuItemMac( CMenu * inParent );
		~CMenuItemMac();
		
		virtual void		SetName( const std::string& inName ) override;
		virtual void		SetCommandChar( const std::string& inName ) override;
		virtual void		SetVisible( bool inState ) override;
		virtual void		SetStyle( TMenuItemStyle inStyle ) override;
		virtual void		SetToolTip( const std::string& inToolTip ) override;
		
		virtual void		LoadFromElement( tinyxml2::XMLElement* inElement ) override;

		virtual WILDNSImagePtr	GetDisplayIcon() override;
		virtual Class			GetPropertyEditorClass() override;
		virtual void			OpenScriptEditorAndShowOffset( size_t byteOffset ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowOffset( byteOffset ); }
		virtual void			OpenScriptEditorAndShowLine( size_t lineIndex ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowLine( lineIndex ); }
		
		virtual WILDNSMenuItemPtr	GetMacMenuItem()	{ return mMacMenuItem; }
		
	protected:
		WILDNSMenuItemPtr mMacMenuItem = nil;
	};
}
