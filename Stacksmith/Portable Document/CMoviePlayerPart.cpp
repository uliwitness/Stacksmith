//
//  CMoviePlayerPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMoviePlayerPart.h"
#include "CTinyXMLUtils.h"


using namespace Carlson;


void	CMoviePlayerPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::LoadPropertiesFromElement( inElement );
	
	mMediaPath.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "mediaPath", mMediaPath );
	mCurrentTime = CTinyXMLUtils::GetLongLongNamed( inElement, "currentTime", 0 );
	mControllerVisible = CTinyXMLUtils::GetBoolNamed( inElement, "controllerVisible", true );
}


void	CMoviePlayerPart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
	printf( "%smediaPath = %s\n", indentStr, mMediaPath.c_str() );
	printf( "%scurrentTime = %lld\n", indentStr, mCurrentTime );
	printf( "%scontrollerVisible = %s\n", indentStr, (mControllerVisible ? "true" : "false") );
}