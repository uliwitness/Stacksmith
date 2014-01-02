//
//  CVisiblePart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CVisiblePart.h"
#include "CTinyXMLUtils.h"


using namespace Calhoun;


void	CVisiblePart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CPart::LoadPropertiesFromElement( inElement );
	
	mVisible = CTinyXMLUtils::GetBoolNamed( inElement, "visible", true );
	mEnabled = CTinyXMLUtils::GetBoolNamed( inElement, "enabled", true );
	tinyxml2::XMLElement *	fillColorElem = inElement->FirstChildElement( "fillColor" );
	mFillColorRed = fillColorElem ? CTinyXMLUtils::GetIntNamed( fillColorElem, "red", 65535 ) : 65535;
	mFillColorGreen = fillColorElem ? CTinyXMLUtils::GetIntNamed( fillColorElem, "green", 65535 ) : 65535;
	mFillColorBlue = fillColorElem ? CTinyXMLUtils::GetIntNamed( fillColorElem, "blue", 65535 ) : 65535;
	mFillColorAlpha = fillColorElem ? CTinyXMLUtils::GetIntNamed( fillColorElem, "alpha", 65535 ) : 65535;
	tinyxml2::XMLElement *	lineColorElem = inElement->FirstChildElement( "lineColor" );
	mLineColorRed = lineColorElem ? CTinyXMLUtils::GetIntNamed( lineColorElem, "red", 0 ) : 0;
	mLineColorGreen = lineColorElem ? CTinyXMLUtils::GetIntNamed( lineColorElem, "green", 0 ) : 0;
	mLineColorBlue = lineColorElem ? CTinyXMLUtils::GetIntNamed( lineColorElem, "blue", 0 ) : 0;
	mLineColorAlpha = lineColorElem ? CTinyXMLUtils::GetIntNamed( lineColorElem, "alpha", 65535 ) : 65535;
	tinyxml2::XMLElement *	shadowColorElem = inElement->FirstChildElement( "shadowColor" );
	mShadowColorRed = shadowColorElem ? CTinyXMLUtils::GetIntNamed( shadowColorElem, "red", 0 ) : 0;
	mShadowColorGreen = shadowColorElem ? CTinyXMLUtils::GetIntNamed( shadowColorElem, "green", 0 ) : 0;
	mShadowColorBlue = shadowColorElem ? CTinyXMLUtils::GetIntNamed( shadowColorElem, "blue", 0 ) : 0;
	mShadowColorAlpha = shadowColorElem ? CTinyXMLUtils::GetIntNamed( shadowColorElem, "alpha", 0 ) : 0;
	tinyxml2::XMLElement *	shadowOffsetElem = inElement->FirstChildElement( "shadowOffset" );
	mShadowOffsetWidth = shadowOffsetElem ? CTinyXMLUtils::GetIntNamed( shadowOffsetElem, "width", 0 ) : 0;
	mShadowOffsetHeight = shadowOffsetElem ? CTinyXMLUtils::GetIntNamed( shadowOffsetElem, "height", 0 ) : 0;
	mShadowBlurRadius = CTinyXMLUtils::GetIntNamed( inElement, "shadowBlurRadius", 0 );
	mLineWidth = CTinyXMLUtils::GetIntNamed( inElement, "lineWidth", 1 );
	mBevelWidth = CTinyXMLUtils::GetIntNamed( inElement, "bevelWidth", 1 );
	mBevelAngle = CTinyXMLUtils::GetIntNamed( inElement, "bevelAngle", 315 );
}


void	CVisiblePart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CPart::DumpProperties( inIndentLevel );
	
	printf( "%svisible = %s\n", indentStr, (mVisible ? "true" : "false") );
	printf( "%senabled = %s\n", indentStr, (mEnabled ? "true" : "false") );
	printf( "%sfillColor = %d,%d,%d,%d\n", indentStr, mFillColorRed, mFillColorGreen, mFillColorBlue, mFillColorAlpha );
	printf( "%slineColor = %d,%d,%d,%d\n", indentStr, mLineColorRed, mLineColorGreen, mLineColorBlue, mLineColorAlpha );
	printf( "%sshadowColor = %d,%d,%d,%d\n", indentStr, mShadowColorRed, mShadowColorGreen, mShadowColorBlue, mShadowColorAlpha );
	printf( "%sshadowOffset = %f,%f\n", indentStr, mShadowOffsetWidth, mShadowOffsetHeight );
	printf( "%sshadowBlurRadius = %f\n", indentStr, mShadowBlurRadius );
	printf( "%slineWidth = %d\n", indentStr, mLineWidth );
	printf( "%sbevelWidth = %d\n", indentStr, mBevelWidth );
	printf( "%sbevelAngle = %d\n", indentStr, mBevelAngle );
}


