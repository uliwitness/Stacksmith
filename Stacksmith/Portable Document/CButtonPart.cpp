//
//  CButtonPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CButtonPart.h"


using namespace Calhoun;


void	CButtonPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::LoadPropertiesFromElement( inElement );
	
//	mFont.erase();
//	CTinyXMLUtils::GetStringNamed( inElement, "font", mFont );
//	mInterval = CTinyXMLUtils::GetBoolNamed( inElement, "visible", true );
//	mRepeat = CTinyXMLUtils::GetBoolNamed( inElement, "repeat", true );
}


void	CButtonPart::DumpProperties( size_t inIndentLevel )
{
//	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
//	printf( "%smessage = %s\n", indentStr, mMessage.c_str() );
//	printf( "%sinterval = %lld\n", indentStr, mInterval );
//	printf( "%srepeat = %s\n", indentStr, (mRepeat ? "true" : "false") );
}