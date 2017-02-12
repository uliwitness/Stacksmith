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
#else
typedef struct NSMenuItem *WILDNSMenuItemPtr;
#endif


namespace Carlson
{
	class CMenuItemMac : public CMenuItem, public CMacScriptableObjectBase
	{
	public:
		explicit CMenuItemMac( CMenu * inParent ) : CMenuItem( inParent ) {}
		
		virtual WILDNSImagePtr	GetDisplayIcon() override;
		virtual Class			GetPropertyEditorClass() override;
		virtual void			OpenScriptEditorAndShowOffset( size_t byteOffset ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowOffset( byteOffset ); }
		virtual void			OpenScriptEditorAndShowLine( size_t lineIndex ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowLine( lineIndex ); }
		
	protected:
		WILDNSMenuItemPtr mMacMenuItem = nil;
	};
}
