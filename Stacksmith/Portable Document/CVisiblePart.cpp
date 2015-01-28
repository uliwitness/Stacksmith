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
	CTinyXMLUtils::GetStringNamed( inElement, "toolTip", mToolTip );
}


void	CVisiblePart::SavePropertiesToElement( tinyxml2::XMLElement * inElement )
{
	tinyxml2::XMLDocument* document = inElement->GetDocument();
	CTinyXMLUtils::AddBoolNamed( inElement, mVisible, "visible" );
	CTinyXMLUtils::AddBoolNamed( inElement, mEnabled, "enabled" );
	
	tinyxml2::XMLElement	*	elem = document->NewElement("fillColor");
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

	elem = document->NewElement("toolTip");
	elem->SetText( mToolTip.c_str() );
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
	printf( "%stoolTip = %s\n", indentStr, mToolTip.c_str() );
}


bool	CVisiblePart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("visible", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetVisible(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("toolTip", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, mToolTip.c_str(), mToolTip.length(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("lineWidth", inPropertyName) == 0 )
	{
		LEOInitNumberValue( outValue, mLineWidth, kLEOUnitNone, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("lineColor", inPropertyName) == 0 )
	{
		struct LEOArrayEntry *theArray = NULL;
		
		LEOAddNumberArrayEntryToRoot( &theArray, "red", mLineColorRed / 65535.0, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "green", mLineColorGreen / 65535.0, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "blue", mLineColorBlue / 65535.0, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "alpha", mLineColorAlpha / 65535.0, kLEOUnitNone, inContext );
		
		LEOInitArrayValue( &outValue->array, theArray, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("fillColor", inPropertyName) == 0 )
	{
		struct LEOArrayEntry *theArray = NULL;
		
		LEOAddNumberArrayEntryToRoot( &theArray, "red", mFillColorRed / 65535.0, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "green", mFillColorGreen / 65535.0, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "blue", mFillColorBlue / 65535.0, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "alpha", mFillColorAlpha / 65535.0, kLEOUnitNone, inContext );
		
		LEOInitArrayValue( &outValue->array, theArray, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("shadowColor", inPropertyName) == 0 )
	{
		struct LEOArrayEntry *theArray = NULL;
		
		LEOAddNumberArrayEntryToRoot( &theArray, "red", mShadowColorRed / 65535.0, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "green", mShadowColorGreen / 65535.0, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "blue", mShadowColorBlue / 65535.0, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "alpha", mShadowColorAlpha / 65535.0, kLEOUnitNone, inContext );
		
		LEOInitArrayValue( &outValue->array, theArray, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("shadowOffset", inPropertyName) == 0 )
	{
		struct LEOArrayEntry *theArray = NULL;
		
		LEOAddNumberArrayEntryToRoot( &theArray, "width", mShadowOffsetWidth, kLEOUnitNone, inContext );
		LEOAddNumberArrayEntryToRoot( &theArray, "height", mShadowOffsetHeight, kLEOUnitNone, inContext );
		
		LEOInitArrayValue( &outValue->array, theArray, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("shadowBlurRadius", inPropertyName) == 0 )
	{
		LEOInitNumberValue( outValue, mShadowBlurRadius, kLEOUnitNone, kLEOInvalidateReferences, inContext );
	}
	else
		return CPart::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CVisiblePart::GetColorFromValue( LEOValuePtr inValue, LEOContext* inContext, int* outRed, int* outGreen, int* outBlue, int* outAlpha )
{
	union LEOValue		tmp = {{0}};
	LEOUnit				theUnit = kLEOUnitNone;
	LEOValuePtr	theValue = LEOGetValueForKey( inValue, "red", &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	*outRed = LEOGetValueAsNumber( theValue, &theUnit, inContext ) * 65535.0;
	if( theValue == &tmp )
		LEOCleanUpValue( &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	
	theValue = LEOGetValueForKey( inValue, "green", &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	*outGreen = LEOGetValueAsNumber( theValue, &theUnit, inContext ) * 65535.0;
	if( theValue == &tmp )
		LEOCleanUpValue( &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	
	theValue = LEOGetValueForKey( inValue, "blue", &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	*outBlue = LEOGetValueAsNumber( theValue, &theUnit, inContext ) * 65535.0;
	if( theValue == &tmp )
		LEOCleanUpValue( &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	
	theValue = LEOGetValueForKey( inValue, "alpha", &tmp, kLEOInvalidateReferences, inContext );
	if( theValue )
	{
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return false;
		*outAlpha = LEOGetValueAsNumber( theValue, &theUnit, inContext ) * 65535.0;
		if( theValue == &tmp )
			LEOCleanUpValue( &tmp, kLEOInvalidateReferences, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return false;
	}
	else
		*outAlpha = 65535;
	
	return true;
}


bool	CVisiblePart::GetSizeFromValue( LEOValuePtr inValue, LEOContext* inContext, double* outWidth, double* outHeight )
{
	union LEOValue		tmp = {{0}};
	LEOUnit				theUnit = kLEOUnitNone;
	LEOValuePtr	theValue = LEOGetValueForKey( inValue, "width", &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	*outWidth = LEOGetValueAsNumber( theValue, &theUnit, inContext );
	if( theValue == &tmp )
		LEOCleanUpValue( &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	
	theValue = LEOGetValueForKey( inValue, "height", &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	*outHeight = LEOGetValueAsNumber( theValue, &theUnit, inContext );
	if( theValue == &tmp )
		LEOCleanUpValue( &tmp, kLEOInvalidateReferences, inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return false;
	
	return true;
}


bool	CVisiblePart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("visible", inPropertyName) == 0 )
	{
		bool	visState = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetVisible( visState );
	}
	else if( strcasecmp("toolTip", inPropertyName) == 0 )
	{
		char	str[1024] = {0};
		const char*	theStr = LEOGetValueAsString( inValue, str, sizeof(str), inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetToolTip( std::string(theStr) );
	}
	else if( strcasecmp("lineWidth", inPropertyName) == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEONumber	lineWidth = LEOGetValueAsNumber( inValue, &theUnit, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetLineWidth( lineWidth );
	}
	else if( strcasecmp("lineColor", inPropertyName) == 0 )
	{
		int	r = 0, g = 0, b = 0, a = 0;
		if( GetColorFromValue( inValue, inContext, &r, &g, &b, &a ) )
			SetLineColor( r, g, b, a );
	}
	else if( strcasecmp("fillColor", inPropertyName) == 0 )
	{
		int	r = 0, g = 0, b = 0, a = 0;
		if( GetColorFromValue( inValue, inContext, &r, &g, &b, &a ) )
			SetFillColor( r, g, b, a );
	}
	else if( strcasecmp("shadowColor", inPropertyName) == 0 )
	{
		int	r = 0, g = 0, b = 0, a = 0;
		if( GetColorFromValue( inValue, inContext, &r, &g, &b, &a ) )
			SetShadowColor( r, g, b, a );
	}
	else if( strcasecmp("shadowOffset", inPropertyName) == 0 )
	{
		double		w = 0, h = 0;
		if( GetSizeFromValue( inValue, inContext, &w, &h ) )
			SetShadowOffset( w, h );
	}
	else if( strcasecmp("shadowBlurRadius", inPropertyName) == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEONumber	lineWidth = LEOGetValueAsNumber( inValue, &theUnit, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetShadowBlurRadius( lineWidth );
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


