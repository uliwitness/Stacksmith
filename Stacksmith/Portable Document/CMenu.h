//
//  CMenu.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 20/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#ifndef CMenu_hpp
#define CMenu_hpp

#include "CConcreteObject.h"
#include "tinyxml2.h"


namespace Carlson
{
	class CMenu;
	
	
	typedef enum
	{
		EMenuItemStyleStandard,
		EMenuItemStyleSeparator,
		EMenuItemStyle_Last
	} TMenuItemStyle;
	
	
	class CMenuItem : public CConcreteObject
	{
	public:
		explicit CMenuItem( CMenu * inParent );
		
		std::string		GetCommandChar()	{ return mCommandChar; }
		TMenuItemStyle	GetStyle()			{ return mStyle; }
		
		void	LoadFromElement( tinyxml2::XMLElement* inElement );
		bool	SaveToElement( tinyxml2::XMLElement* inElement );

		virtual CScriptableObject*	GetParentObject();

		virtual std::string		GetTypeName()			{ return "menuItem"; };
		
		static TMenuItemStyle	GetMenuItemStyleFromString( const char* inStyleStr );
		
	protected:
		LEOObjectID			mID;
		std::string			mCommandChar;
		CMenu*				mParent;
		TMenuItemStyle		mStyle;
	};
	
	typedef CRefCountedObjectRef<CMenuItem>		CMenuItemRef;
	
	
	class CMenu : public CConcreteObject
	{
	public:
		explicit CMenu( CDocument* inDocument ) : mID(0)	{ mDocument = inDocument; }
		
		size_t		GetNumItems()				{ return mItems.size(); }
		CMenuItem*	GetItem( size_t inIndex )	{ return mItems[inIndex]; }

		virtual std::string		GetTypeName()			{ return "menu"; };
		
		void	LoadFromElement( tinyxml2::XMLElement* inElement );
		bool	SaveToElement( tinyxml2::XMLElement* inElement );
		
		virtual CScriptableObject*	GetParentObject();
		
	protected:
		std::vector<CMenuItemRef>		mItems;
		LEOObjectID						mID;
	};

	typedef CRefCountedObjectRef<CMenu>		CMenuRef;

}

#endif /* CMenu_hpp */
