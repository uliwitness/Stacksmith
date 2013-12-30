//
//  CConcreteObject.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CConcreteObject__
#define __Stacksmith__CConcreteObject__

#include "CRefCountedObject.h"
#include <string>
#include <map>
#include "tinyxml2.h"


class CConcreteObject : public CRefCountedObject
{
public:
	void		LoadUserPropertiesFromElement( tinyxml2::XMLElement * elem );
	
protected:
	std::string							mName;		// Name of this object for referring to it from scripts (not including type like 'stack').
	std::string							mScript;	// Uncompiled text of this object's script.
	std::map<std::string,std::string>	mUserProperties;
};

typedef CRefCountedObjectRef<CConcreteObject>	CConcreteObjectRef;

#endif /* defined(__Stacksmith__CConcreteObject__) */
