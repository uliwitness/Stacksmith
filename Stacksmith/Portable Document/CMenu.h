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
	
	typedef enum
	{
		EMenuItemDontMarkChanged,
		EMenuItemMarkChanged
	} TMenuItemMarkChangedFlag;
	
	
	extern const char*	EMenuItemMarkCharChecked;
	extern const char*	EMenuItemMarkCharMixed;
	extern const char*	EMenuItemMarkCharNone;
	
	
	class CMenuItem : public CConcreteObject
	{
	public:
		explicit CMenuItem( CMenu * inParent );
		
		virtual ObjectID	GetID()	const override	{ return mID; }
		virtual void		SetName( const std::string& inName ) override;
		virtual void		SetCommandChar( const std::string& inName );
		virtual void		SetMarkChar( const std::string& inName );
		virtual void		SetVisible( bool inState );
		virtual void		SetEnabled( bool inState );
		virtual void		SetStyle( TMenuItemStyle inStyle );
		virtual void		SetMessage( const std::string& inMessage );
		virtual void		SetToolTip( const std::string& inToolTip );
		
		std::string		GetCommandChar()	{ return mCommandChar; }
		std::string		GetMarkChar()		{ return mMarkChar; }
		TMenuItemStyle	GetStyle()			{ return mStyle; }
		bool			GetVisible()		{ return mVisible; }
		bool			GetEnabled()		{ return mEnabled; }
		std::string		GetMessage()		{ return mMessage; }
		std::string		GetToolTip()		{ return mToolTip; }
		
		void	LoadFromElement( tinyxml2::XMLElement* inElement );
		bool	SaveToElement( tinyxml2::XMLElement* inElement );

		virtual bool		GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue ) override;
		virtual bool		SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd ) override;

		virtual CScriptableObject*	GetParentObject( CScriptableObject* previousParent ) override;

		virtual std::string		GetTypeName() override			{ return "menuItem"; };
		
		static TMenuItemStyle	GetMenuItemStyleFromString( const char* inStyleStr );
	protected:
		ObjectID			mID;
		std::string			mCommandChar;
		std::string			mMarkChar;
		CMenu*				mParent;
		std::string			mMessage;
		std::string			mToolTip;
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
		virtual void		SetName( const std::string& inName ) override;
		virtual void		SetVisible( bool inState );
		virtual void		SetEnabled( bool inState );
		
		size_t		GetNumItems()				{ return mItems.size(); }
		CMenuItem*	GetItem( size_t inIndex )	{ return mItems[inIndex]; }
		CMenuItem*	GetItemWithID( ObjectID inID );
		CMenuItem*	GetItemWithName( const std::string& inName );
		LEOInteger	GetIndexOfItem( CMenuItem* inItem );
		void		SetIndexOfItem( CMenuItem* inItem, LEOInteger inIndex );
		ObjectID	GetUniqueIDForItem();
		bool		GetVisible()				{ return mVisible; }
		bool		GetEnabled()				{ return mEnabled; }

		virtual std::string		GetTypeName() override			{ return "menu"; };
		
		virtual CMenuItem*		NewMenuItemWithElement( tinyxml2::XMLElement* inElement, TMenuItemMarkChangedFlag markChanged = EMenuItemMarkChanged );
		void					LoadFromElement( tinyxml2::XMLElement* inElement );
		bool					SaveToElement( tinyxml2::XMLElement* inElement );

		virtual bool		GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue ) override;
		virtual bool		SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd ) override;

		virtual CScriptableObject*	GetParentObject( CScriptableObject* previousParent ) override;
		
		virtual void	MenuItemIncrementedChangeCount( CMenuItem* inItem, bool parentNeedsFullRebuild );
		
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
