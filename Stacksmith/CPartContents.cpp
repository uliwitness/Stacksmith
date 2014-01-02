//
//  CPartContents.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CPartContents.h"
#include "CTinyXMLUtils.h"



CPartContents::CPartContents( tinyxml2::XMLElement * inElement )
{
	mID = CTinyXMLUtils::GetLongLongNamed( inElement, "id" );
	mHighlight = CTinyXMLUtils::GetBoolNamed( inElement, "highlight", false );
	CTinyXMLUtils::GetStringNamed( inElement, "text", mText );
	std::string	theLayerStr;
	CTinyXMLUtils::GetStringNamed( inElement, "layer", theLayerStr );
	mIsOnBackground = (theLayerStr.compare("background") == 0);
}


void	CPartContents::Dump( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%sContents for %s part ID %lld\n%s{\n", indentStr, (mIsOnBackground?"bg":"cd"), mID, indentStr );
	printf( "%s\thighlight = %s\n", indentStr, (mHighlight?"true":"false") );
	printf( "%s\ttext = %s\n", indentStr, mText.c_str() );
	printf( "%s}\n", indentStr );
}
