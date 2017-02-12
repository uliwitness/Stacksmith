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
typedef NSMenu *WILDNSMenuPtr;
#else
typedef struct NSMenu *WILDNSMenuPtr;
#endif


namespace Carlson {
	
	class CMenuMac : public CMenu, public CMacScriptableObjectBase
	{
	public:
		explicit CMenuMac( CDocument* inDocument ) : CMenu(inDocument) {}

		virtual CMenuItem*	NewMenuItemWithElement( tinyxml2::XMLElement* inElement, TMenuItemMarkChangedFlag markChanged = EMenuItemMarkChanged ) override;

		virtual WILDNSImagePtr	GetDisplayIcon() override;
		virtual Class			GetPropertyEditorClass() override;
		virtual void			OpenScriptEditorAndShowOffset( size_t byteOffset ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowOffset( byteOffset ); }
		virtual void			OpenScriptEditorAndShowLine( size_t lineIndex ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowLine( lineIndex ); }

	protected:
		WILDNSMenuPtr mMacMenu = nil;
	};
	
}

