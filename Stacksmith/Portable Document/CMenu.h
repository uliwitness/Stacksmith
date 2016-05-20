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
	class CMenuItem : public CConcreteObject
	{
	public:
		CMenuItem() : mID(0)	{}
		
		void	LoadFromElement( tinyxml2::XMLElement* inElement );
		bool	SaveToElement( tinyxml2::XMLElement* inElement );
		
	protected:
		LEOObjectID						mID;
	};
	
	typedef CRefCountedObjectRef<CMenuItem>		CMenuItemRef;
	
	
	class CMenu : public CConcreteObject
	{
	public:
		CMenu() : mID(0)	{}

		void	LoadFromElement( tinyxml2::XMLElement* inElement );
		bool	SaveToElement( tinyxml2::XMLElement* inElement );
		
	protected:
		std::vector<CMenuItemRef>		mItems;
		LEOObjectID						mID;
	};

	typedef CRefCountedObjectRef<CMenu>		CMenuRef;

}

#endif /* CMenu_hpp */
