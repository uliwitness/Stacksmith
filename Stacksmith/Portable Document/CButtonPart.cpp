//
//  CButtonPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CButtonPart.h"
#include "CTinyXMLUtils.h"
#include "CPartContents.h"


using namespace Carlson;


static const char*	sButtonStyleStrings[EButtonStyle_Last +1] =
{
	"transparent",
	"opaque",
	"rectangle",
	"shadow",
	"roundrect",
	"checkbox",
	"radiobutton",
	"standard",
	"default",
	"popup",
	"oval",
	"*UNKNOWN*"
};


TButtonStyle	CButtonPart::GetButtonStyleFromString( const char* inStyleStr )
{
	for( size_t x = 0; x < EButtonStyle_Last; x++ )
	{
		if( strcmp(sButtonStyleStrings[x],inStyleStr) == 0 )
			return (TButtonStyle)x;
	}
	return EButtonStyle_Last;
}


void	CButtonPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::LoadPropertiesFromElement( inElement );
	
	mShowName = CTinyXMLUtils::GetBoolNamed( inElement, "showName", true );
	mHighlight = CTinyXMLUtils::GetBoolNamed( inElement, "highlight", false );
	mAutoHighlight = CTinyXMLUtils::GetBoolNamed( inElement, "autoHighlight", true );
	mSharedHighlight = CTinyXMLUtils::GetBoolNamed( inElement, "sharedHighlight", true );
	mTitleWidth = CTinyXMLUtils::GetIntNamed( inElement, "titleWidth", 0 );
	mIconID = CTinyXMLUtils::GetLongLongNamed( inElement, "icon", 0 );
	std::string	textAlignStr;
	CTinyXMLUtils::GetStringNamed( inElement, "textAlign", textAlignStr );
	mTextAlign = GetTextAlignFromString( textAlignStr.c_str() );
	mFont.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "font", mFont );
	mTextSize = CTinyXMLUtils::GetIntNamed( inElement, "textSize", 12 );
	mFamily = CTinyXMLUtils::GetIntNamed( inElement, "family", 0 );
	std::string	styleStr;
	CTinyXMLUtils::GetStringNamed( inElement, "style", styleStr );
	mButtonStyle = GetButtonStyleFromString( styleStr.c_str() );
}


bool	CButtonPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOValuePtr outValue )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, mName.c_str(), mName.size(), kLEOInvalidateReferences, NULL );
	}
	return false;
}


bool	CButtonPart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		char		nameBuf[1024];
		const char*	nameStr = LEOGetValueAsString( inValue, nameBuf, sizeof(nameBuf), inContext );
		SetName( nameStr );
	}
	return false;
}



void	CButtonPart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
	printf( "%sstyle = %s\n", indentStr, sButtonStyleStrings[mButtonStyle] );
	printf( "%sshowName = %s\n", indentStr, (mShowName ? "true" : "false") );
	CPartContents*	theContents = GetContentsOnCurrentCard();
	printf( "%shighlight = %s\n", indentStr, ((theContents ? theContents->GetHighlight() : mHighlight) ? "true" : "false") );
	printf( "%sautoHighlight = %s\n", indentStr, (mAutoHighlight ? "true" : "false") );
	printf( "%ssharedHighlight = %s\n", indentStr, (mSharedHighlight ? "true" : "false") );
	printf( "%stitleWidth = %d\n", indentStr, mTitleWidth );
	printf( "%sicon = %lld\n", indentStr, mIconID );
	printf( "%stextAlign = %d\n", indentStr, mTextAlign );
	printf( "%sfont = %s\n", indentStr, mFont.c_str() );
	printf( "%stextSize = %d\n", indentStr, mTextSize );
	printf( "%sfamily = %d\n", indentStr, mFamily );
}