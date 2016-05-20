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
		std::string		GetMarkChar()		{ return mMarkChar; }
		TMenuItemStyle	GetStyle()			{ return mStyle; }
		bool			GetVisible()		{ return mVisible; }
		bool			GetEnabled()		{ return mEnabled; }
		
		void	LoadFromElement( tinyxml2::XMLElement* inElement );
		bool	SaveToElement( tinyxml2::XMLElement* inElement );

		virtual CScriptableObject*	GetParentObject() override;

		virtual std::string		GetTypeName() override			{ return "menuItem"; };
		
		static TMenuItemStyle	GetMenuItemStyleFromString( const char* inStyleStr );
		
	protected:
		LEOObjectID			mID;
		std::string			mCommandChar;
		std::string			mMarkChar;
		CMenu*				mParent;
		TMenuItemStyle		mStyle;
		bool				mVisible;
	};
	
	typedef CRefCountedObjectRef<CMenuItem>		CMenuItemRef;
	
	
	class CMenu : public CConcreteObject
	{
	public:
		explicit CMenu( CDocument* inDocument ) : mID(0), mVisible(true)	{ mDocument = inDocument; }
		
		size_t		GetNumItems()				{ return mItems.size(); }
		CMenuItem*	GetItem( size_t inIndex )	{ return mItems[inIndex]; }
		bool		GetVisible()				{ return mVisible; }

		virtual std::string		GetTypeName() override			{ return "menu"; };
		
		void	LoadFromElement( tinyxml2::XMLElement* inElement );
		bool	SaveToElement( tinyxml2::XMLElement* inElement );
		
		virtual CScriptableObject*	GetParentObject() override;
		
	protected:
		std::vector<CMenuItemRef>		mItems;
		LEOObjectID						mID;
		bool							mVisible;
	};

	typedef CRefCountedObjectRef<CMenu>		CMenuRef;

}

#endif /* CMenu_hpp */
