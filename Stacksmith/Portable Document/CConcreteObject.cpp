//
//  CConcreteObject.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CConcreteObject.h"
#include "CTinyXMLUtils.h"


void	CConcreteObject::LoadUserPropertiesFromElement( tinyxml2::XMLElement * elem )
{
	tinyxml2::XMLElement	*	userPropsElem = elem->FirstChildElement( "userProperties" );
	tinyxml2::XMLElement	*	currUserPropNameNode = userPropsElem ? userPropsElem->FirstChildElement() : NULL;
	while( currUserPropNameNode )
	{
		std::string		propName = currUserPropNameNode ? CTinyXMLUtils::EnsureNonNULLString(currUserPropNameNode->GetText()) : std::string();
		currUserPropNameNode = currUserPropNameNode->NextSiblingElement();
		std::string		propValue = currUserPropNameNode ? CTinyXMLUtils::EnsureNonNULLString(currUserPropNameNode->GetText()) : std::string();
		currUserPropNameNode = currUserPropNameNode->NextSiblingElement();
		
		mUserProperties[propName] = propValue;
	}
}