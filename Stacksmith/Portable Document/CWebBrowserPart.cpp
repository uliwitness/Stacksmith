//
//  CWebBrowserPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CWebBrowserPart.h"
#include "CTinyXMLUtils.h"


using namespace Calhoun;


void	CWebBrowserPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::LoadPropertiesFromElement( inElement );
	
	mCurrentURL.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "currentURL", mCurrentURL );
}


void	CWebBrowserPart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
	printf( "%scurrentURL = %s\n", indentStr, mCurrentURL.c_str() );
}