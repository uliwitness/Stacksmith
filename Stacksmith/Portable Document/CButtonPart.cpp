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
#include "CStack.h"


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


bool	CButtonPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("family", inPropertyName) == 0 )
	{
		LEOInitIntegerValue( outValue, GetFamily(), kLEOUnitNone, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("highlight", inPropertyName) == 0 )
	{
		CPartContents*	theContents = NULL;
		CCard	*		currCard = GetStack()->GetCurrentCard();
		if( mOwner != currCard && !GetSharedHighlight() )	// We're on the background layer, not on the card?
			theContents = currCard->GetPartContentsByID( GetID(), (mOwner != currCard) );
		LEOInitBooleanValue( outValue, (theContents ? theContents->GetHighlight() : GetHighlight()), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("sharedHighlight", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetSharedHighlight(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("autoHighlight", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetSharedHighlight(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("showName", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetShowName(), kLEOInvalidateReferences, inContext );
	}
	else
		return CVisiblePart::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CButtonPart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("family", inPropertyName) == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEOInteger	familyNum = LEOGetValueAsInteger( inValue, &theUnit, inContext );
		if( !inContext->keepRunning )
			return true;
		SetFamily( familyNum );
	}
	else if( strcasecmp("highlight", inPropertyName) == 0 )
	{
		CPartContents*	theContents = NULL;
		bool			theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		CCard	*		currCard = GetStack()->GetCurrentCard();
		if( mOwner != currCard && !GetSharedHighlight() )	// We're on the background layer, not on the card?
		{
			theContents = currCard->GetPartContentsByID( GetID(), (mOwner != currCard) );
			if( !theContents )
			{
				theContents = new CPartContents( currCard );
				theContents->SetID( GetID() );
				theContents->SetIsOnBackground( mOwner != currCard );
				theContents->SetHighlight( theHighlight );
				currCard->AddPartContents( theContents );
			}
			else
				theContents->SetHighlight( theHighlight );
		}
		else
			SetHighlight( theHighlight );
	}
	else if( strcasecmp("autoHighlight", inPropertyName) == 0 )
	{
		bool	theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		SetAutoHighlight( theHighlight );
	}
	else if( strcasecmp("sharedHighlight", inPropertyName) == 0 )
	{
		bool	theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		SetSharedHighlight( theHighlight );
	}
	else if( strcasecmp("showName", inPropertyName) == 0 )
	{
		bool	theShowName = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		SetShowName( theShowName );
	}
	else
		return CVisiblePart::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
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
	printf( "%sfamily = %lld\n", indentStr, mFamily );
}