//
//  CButtonPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CButtonPart.h"
#include "CTinyXMLUtils.h"


using namespace Calhoun;


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
	if( textAlignStr.compare("left") )
		mTextAlign = EPartTextAlignLeft;
	else if( textAlignStr.compare("center") )
		mTextAlign = EPartTextAlignCenter;
	else if( textAlignStr.compare("right") )
		mTextAlign = EPartTextAlignRight;
	else if( textAlignStr.compare("justified") )
		mTextAlign = EPartTextAlignJustified;
	else
		mTextAlign = EPartTextAlignDefault;
	mFont.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "font", mFont );
	mTextSize = CTinyXMLUtils::GetIntNamed( inElement, "textSize", 12 );
	mFamily = CTinyXMLUtils::GetIntNamed( inElement, "family", 0 );
}


void	CButtonPart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
	printf( "%sshowName = %s\n", indentStr, (mShowName ? "true" : "false") );
	printf( "%shighlight = %s\n", indentStr, (mHighlight ? "true" : "false") );
	printf( "%sautoHighlight = %s\n", indentStr, (mAutoHighlight ? "true" : "false") );
	printf( "%ssharedHighlight = %s\n", indentStr, (mSharedHighlight ? "true" : "false") );
	printf( "%stitleWidth = %d\n", indentStr, mTitleWidth );
	printf( "%sicon = %lld\n", indentStr, mIconID );
	printf( "%stextAlign = %d\n", indentStr, mTextAlign );
	printf( "%sfont = %s\n", indentStr, mFont.c_str() );
	printf( "%stextSize = %d\n", indentStr, mTextSize );
	printf( "%sfamily = %d\n", indentStr, mFamily );
}