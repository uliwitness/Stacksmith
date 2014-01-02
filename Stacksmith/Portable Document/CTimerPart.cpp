//
//  CTimerPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CTimerPart.h"
#include "CTinyXMLUtils.h"


using namespace Calhoun;


void	CTimerPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	mMessage.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "message", mMessage );
	mInterval = CTinyXMLUtils::GetLongLongNamed( inElement, "interval", 0 );
	mRepeat = CTinyXMLUtils::GetBoolNamed( inElement, "repeat", true );
}

void	CTimerPart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CPart::DumpProperties( inIndentLevel );
	
	printf( "%smessage = %s\n", indentStr, mMessage.c_str() );
	printf( "%sinterval = %lld\n", indentStr, mInterval );
	printf( "%srepeat = %s\n", indentStr, (mRepeat ? "true" : "false") );
}