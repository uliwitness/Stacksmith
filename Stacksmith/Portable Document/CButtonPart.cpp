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
	tinyxml2::XMLElement * currStyle = inElement->FirstChildElement("textStyle");
	mTextStyle = EPartTextStylePlain;
	while( currStyle )
	{
		mTextStyle |= GetStyleFromString( currStyle->GetText() );
		currStyle = currStyle->NextSiblingElement( "textStyle" );
	}
	mFamily = CTinyXMLUtils::GetIntNamed( inElement, "family", 0 );
	std::string	styleStr;
	CTinyXMLUtils::GetStringNamed( inElement, "style", styleStr );
	mButtonStyle = GetButtonStyleFromString( styleStr.c_str() );
	
	mSelectedLines.erase(mSelectedLines.begin(), mSelectedLines.end());
	tinyxml2::XMLElement * selLines = inElement->FirstChildElement("selectedLines");
	if( selLines )
	{
		tinyxml2::XMLElement * currSelLine = selLines->FirstChildElement("integer");
		while( currSelLine )
		{
			mSelectedLines.insert( currSelLine->LongLongText() );
			currSelLine = currSelLine->NextSiblingElement( "integer" );
		}
	}
}


void	CButtonPart::SavePropertiesToElementOfDocument( tinyxml2::XMLElement * inElement, tinyxml2::XMLDocument* document )
{
	CVisiblePart::SavePropertiesToElementOfDocument( inElement, document );
	
	tinyxml2::XMLElement	*	elem = document->NewElement("style");
	elem->SetText( sButtonStyleStrings[mButtonStyle] );
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("showName");
	elem->SetBoolFirstChild(mShowName);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("highlight");
	elem->SetBoolFirstChild(mHighlight);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("autoHighlight");
	elem->SetBoolFirstChild(mAutoHighlight);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("sharedHighlight");
	elem->SetBoolFirstChild(mSharedHighlight);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("family");
	elem->SetText(mFamily);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("titleWidth");
	elem->SetText(mTitleWidth);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("icon");
	elem->SetText(mIconID);
	inElement->InsertEndChild(elem);
	
	if( !mSelectedLines.empty() )
	{
		elem = document->NewElement("selectedLines");
		for( size_t currLine : mSelectedLines )
		{
			tinyxml2::XMLElement	*	subElem = document->NewElement("integer");
			subElem->SetText( (long long) currLine );
			elem->InsertEndChild( subElem );
		}
		inElement->InsertEndChild(elem);
	}
	
	elem = document->NewElement("textAlign");
	elem->SetText(GetStringFromTextAlign(mTextAlign));
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("font");
	elem->SetText(mFont.c_str());
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("textSize");
	elem->SetText(mTextSize);
	inElement->InsertEndChild(elem);
	
	std::vector<const char*>	styles = GetStringsForStyle( mTextStyle );
	for( const char* currStyle : styles )
	{
		elem = document->NewElement("textStyle");
		elem->SetText(currStyle);
		inElement->InsertEndChild(elem);
	}
	if( styles.size() == 0 )
	{
		elem = document->NewElement("textStyle");
		elem->SetText("plain");
		inElement->InsertEndChild(elem);
	}
}


bool	CButtonPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("family", inPropertyName) == 0 )
	{
		LEOInitIntegerValue( outValue, GetFamily(), kLEOUnitNone, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("highlight", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetHighlight(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("pressed", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mHighlightForTracking, kLEOInvalidateReferences, inContext );
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
	else if( strcasecmp("selectedLine", inPropertyName) == 0 )
	{
		auto foundLine = mSelectedLines.lower_bound(0);
		if( foundLine != mSelectedLines.end() )
			LEOInitIntegerValue( outValue, *foundLine, kLEOUnitNone, kLEOInvalidateReferences, inContext );
		else
			LEOInitStringConstantValue( outValue, "none", kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("style", inPropertyName) == 0 )
	{
		LEOInitStringConstantValue( outValue, sButtonStyleStrings[mButtonStyle], kLEOInvalidateReferences, inContext );
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
		bool			theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		SetHighlight( theHighlight );
	}
	else if( strcasecmp("pressed", inPropertyName) == 0 )
	{
		bool			theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		SetHighlightForTracking( theHighlight );
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
	else if( strcasecmp("selectedLine", inPropertyName) == 0 )
	{
		LEOInteger	theSelectedLine = 0;
		char		strBuf[5] = {0};
		const char* str = LEOGetValueAsString( inValue, strBuf, sizeof(strBuf), inContext );
		if( strcasecmp(str, "none") != 0 && str[0] != 0 )
		{
			LEOUnit		outUnit = kLEOUnitNone;
			theSelectedLine = LEOGetValueAsInteger( inValue, &outUnit, inContext );
			if( !inContext->keepRunning )
				return true;
		}
		mSelectedLines.erase(mSelectedLines.begin(), mSelectedLines.end());
		if( theSelectedLine != 0 )
			mSelectedLines.insert(theSelectedLine);
		ApplyChangedSelectedLinesToView();
	}
	else if( strcasecmp("style", inPropertyName) == 0 )
	{
		char		nameBuf[1024];
		const char*	nameStr = LEOGetValueAsString( inValue, nameBuf, sizeof(nameBuf), inContext );
		TButtonStyle	style = GetButtonStyleFromString(nameStr);
		if( style == EButtonStyle_Last )
			LEOContextStopWithError( inContext, "Unknown button style \"%s\".", nameStr );
		else
			SetButtonStyle( style );
	}
	else
		return CVisiblePart::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


void	CButtonPart::SetHighlight(bool inHighlight)
{
	CPartContents*	theContents = NULL;
	CCard	*		currCard = GetStack()->GetCurrentCard();
	if( mOwner != currCard && !GetSharedHighlight() )	// We're on the background layer, not on the card?
	{
		theContents = currCard->GetPartContentsByID( GetID(), (mOwner != currCard) );
		if( !theContents )
		{
			theContents = new CPartContents( currCard );
			theContents->SetID( GetID() );
			theContents->SetIsOnBackground( mOwner != currCard );
			theContents->SetHighlight( inHighlight );
			currCard->AddPartContents( theContents );
		}
		else
			theContents->SetHighlight( inHighlight );
	}
	else
		mHighlight = inHighlight;
}


bool	CButtonPart::GetHighlight()
{
	CPartContents*	theContents = NULL;
	CCard	*	currCard = GetStack()->GetCurrentCard();
	if( mOwner != currCard && !GetSharedHighlight() )	// We're on the background layer, not on the card?
		theContents = currCard->GetPartContentsByID( GetID(), (mOwner != currCard) );
	return (theContents ? theContents->GetHighlight() : mHighlight);
}


void	CButtonPart::PrepareMouseUp()
{
	if( mAutoHighlight && mFamily != 0 )	// Select this button in its radio button group.
	{
		SetHighlight(true);
		if( mFamily != 0 )
			mOwner->UnhighlightFamilyMembersOfPart( this );
	}
	else if( mAutoHighlight && (mButtonStyle == EButtonStyleCheckBox || mButtonStyle == EButtonStyleRadioButton) ) // Toggle checkboxes (and radio buttons abused as checkboxes).
	{
		SetHighlight(!GetHighlight());
	}
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