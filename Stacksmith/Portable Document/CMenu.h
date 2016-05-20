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
		
		virtual ObjectID	GetID()	const override	{ return mID; }
		
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
		ObjectID			mID;
		std::string			mCommandChar;
		std::string			mMarkChar;
		CMenu*				mParent;
		TMenuItemStyle		mStyle;
		bool				mVisible;
		bool				mEnabled;
	};
	
	typedef CRefCountedObjectRef<CMenuItem>		CMenuItemRef;
	
	
	class CMenu : public CConcreteObject
	{
	public:
		explicit CMenu( CDocument* inDocument ) : mID(0), mVisible(true), mEnabled(true), mItemIDSeed(100)	{ mDocument = inDocument; }
		
		virtual ObjectID	GetID() const override	{ return mID; }
		
		size_t		GetNumItems()				{ return mItems.size(); }
		CMenuItem*	GetItem( size_t inIndex )	{ return mItems[inIndex]; }
		ObjectID	GetUniqueIDForItem();
		bool		GetVisible()				{ return mVisible; }
		bool		GetEnabled()				{ return mEnabled; }

		virtual std::string		GetTypeName() override			{ return "menu"; };
		
		void	LoadFromElement( tinyxml2::XMLElement* inElement );
		bool	SaveToElement( tinyxml2::XMLElement* inElement );
		
		virtual CScriptableObject*	GetParentObject() override;
		
	protected:
		std::vector<CMenuItemRef>		mItems;
		ObjectID						mID;
		bool							mVisible;
		bool							mEnabled;
		
		ObjectID						mItemIDSeed;
	};

	typedef CRefCountedObjectRef<CMenu>		CMenuRef;

}

#endif /* CMenu_hpp */
