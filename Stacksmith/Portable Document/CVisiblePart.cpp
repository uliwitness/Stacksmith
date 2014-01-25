//
//  CVisiblePart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CVisiblePart.h"
#include "CTinyXMLUtils.h"


using namespace Carlson;


static const char*		sTextStyleNames[EPartTextStyleBit_Last] =
{
	"bold",
	"italic",
	"underline",
	"outline",
	"shadow",
	"condensed",
	"extended",
	"group"
};


static const char*		sTextAlignNames[EPartTextAlign_Last] =
{
	"default",
	"left",
	"center",
	"right",
	"justified"
};


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
	mShadowOffsetWidth = shadowOffsetElem ? CTinyXMLUtils::GetDoubleNamed( shadowOffsetElem, "width", 0 ) : 0;
	mShadowOffsetHeight = shadowOffsetElem ? CTinyXMLUtils::GetDoubleNamed( shadowOffsetElem, "height", 0 ) : 0;
	mShadowBlurRadius = CTinyXMLUtils::GetDoubleNamed( inElement, "shadowBlurRadius", 0 );
	mLineWidth = CTinyXMLUtils::GetIntNamed( inElement, "lineWidth", 1 );
	mBevelWidth = CTinyXMLUtils::GetIntNamed( inElement, "bevelWidth", 1 );
	mBevelAngle = CTinyXMLUtils::GetIntNamed( inElement, "bevelAngle", 315 );
}


void	CVisiblePart::SavePropertiesToElementOfDocument( tinyxml2::XMLElement * inElement, tinyxml2::XMLDocument* document )
{
	tinyxml2::XMLElement	*	elem = document->NewElement("visible");
	elem->SetBoolFirstChild(mVisible);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("enabled");
	elem->SetBoolFirstChild(mEnabled);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("fillColor");
	tinyxml2::XMLElement	*	subElem = document->NewElement("red");
	subElem->SetText(mFillColorRed);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("green");
	subElem->SetText(mFillColorGreen);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("blue");
	subElem->SetText(mFillColorBlue);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("alpha");
	subElem->SetText(mFillColorAlpha);
	elem->InsertEndChild(subElem);
	inElement->InsertEndChild(elem);

	elem = document->NewElement("lineColor");
	subElem = document->NewElement("red");
	subElem->SetText(mLineColorRed);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("green");
	subElem->SetText(mLineColorGreen);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("blue");
	subElem->SetText(mLineColorBlue);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("alpha");
	subElem->SetText(mLineColorAlpha);
	elem->InsertEndChild(subElem);
	inElement->InsertEndChild(elem);

	elem = document->NewElement("shadowColor");
	subElem = document->NewElement("red");
	subElem->SetText(mShadowColorRed);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("green");
	subElem->SetText(mShadowColorGreen);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("blue");
	subElem->SetText(mShadowColorBlue);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("alpha");
	subElem->SetText(mShadowColorAlpha);
	elem->InsertEndChild(subElem);
	inElement->InsertEndChild(elem);

	elem = document->NewElement("shadowOffset");
	subElem = document->NewElement("width");
	subElem->SetText(mShadowOffsetWidth);
	elem->InsertEndChild(subElem);
	subElem = document->NewElement("height");
	subElem->SetText(mShadowOffsetHeight);
	elem->InsertEndChild(subElem);
	inElement->InsertEndChild(elem);

	elem = document->NewElement("shadowBlurRadius");
	elem->SetText(mShadowBlurRadius);
	inElement->InsertEndChild(elem);

	elem = document->NewElement("lineWidth");
	elem->SetText(mLineWidth);
	inElement->InsertEndChild(elem);

	elem = document->NewElement("bevelWidth");
	elem->SetText(mBevelWidth);
	inElement->InsertEndChild(elem);

	elem = document->NewElement("bevelAngle");
	elem->SetText(mBevelAngle);
	inElement->InsertEndChild(elem);
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


bool	CVisiblePart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("visible", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetVisible(), kLEOInvalidateReferences, inContext );
	}
	else
		return CPart::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CVisiblePart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("visible", inPropertyName) == 0 )
	{
		bool	visState = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		SetVisible( visState );
	}
	else
		return CPart::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


/*static*/ TPartTextAlign	CVisiblePart::GetTextAlignFromString( const char* inString )
{
	if( !inString )
		return EPartTextAlignDefault;
		
	for( TPartTextAlign x = 0; x < EPartTextAlign_Last; x++ )
	{
		if( strcasecmp(inString,sTextAlignNames[x]) == 0 )
			return x;
	}
	
	return EPartTextAlignDefault;
}


/*static*/ const char*	CVisiblePart::GetStringFromTextAlign( TPartTextAlign inAlign )
{
	if( inAlign >= EPartTextAlign_Last )
		return "";
	else
		return sTextAlignNames[inAlign];
}


/*static*/ TPartTextStyle	CVisiblePart::GetStyleFromString( const char* inString )
{
	if( !inString )
		return EPartTextStylePlain;
		
	for( size_t x = 0; x < EPartTextStyleBit_Last; x++ )
	{
		if( strcasecmp(inString,sTextStyleNames[x]) == 0 )
			return (1 << x);
	}
	return EPartTextStylePlain;
}


/*static*/ std::vector<const char*>		CVisiblePart::GetStringsForStyle( TPartTextStyle inStyle )
{
	std::vector<const char*>	styles;
	for( size_t x = 0; x < EPartTextStyleBit_Last; x++ )
	{
		if( inStyle & (1 << x) )
			styles.push_back( sTextStyleNames[x] );
	}
	return styles;
}


