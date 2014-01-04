//
//  CPicturePart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CPicturePart.h"
#include "CTinyXMLUtils.h"


using namespace Calhoun;


void	CPicturePart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::LoadPropertiesFromElement( inElement );
	
	mMediaPath.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "mediaPath", mMediaPath );
	mTransparent = CTinyXMLUtils::GetBoolNamed( inElement, "transparent", mTransparent );
}


void	CPicturePart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
	printf( "%smediaPath = %s\n", indentStr, mMediaPath.c_str() );
	printf( "%stransparent = %s\n", indentStr, (mTransparent?"true":"false") );
}