//
//  CFieldPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CFieldPart.h"
#include "CTinyXMLUtils.h"
#include "CCard.h"
#include "CBackground.h"
#include "CStack.h"


using namespace Carlson;


static const char*	sFieldStyleStrings[EFieldStyle_Last +1] =
{
	"transparent",
	"opaque",
	"rectangle",
	"shadow",
	"scrolling",
	"standard",
	"popup",
	"*UNKNOWN*"
};


TFieldStyle	CFieldPart::GetFieldStyleFromString( const char* inStyleStr )
{
	for( size_t x = 0; x < EFieldStyle_Last; x++ )
	{
		if( strcmp(sFieldStyleStrings[x],inStyleStr) == 0 )
			return (TFieldStyle)x;
	}
	return EFieldStyle_Last;
}


void	CFieldPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::LoadPropertiesFromElement( inElement );
	
	mDontWrap = CTinyXMLUtils::GetBoolNamed( inElement, "dontWrap", false );
	mDontSearch = CTinyXMLUtils::GetBoolNamed( inElement, "dontSearch", false );
	mSharedText = CTinyXMLUtils::GetBoolNamed( inElement, "sharedText", false );
	mFixedLineHeight = CTinyXMLUtils::GetBoolNamed( inElement, "fixedLineHeight", false );
	mAutoTab = CTinyXMLUtils::GetBoolNamed( inElement, "autoTab", false );
	mLockText = CTinyXMLUtils::GetBoolNamed( inElement, "lockText", false );
	mAutoSelect = CTinyXMLUtils::GetBoolNamed( inElement, "autoSelect", false );
	mMultipleLines = CTinyXMLUtils::GetBoolNamed( inElement, "multipleLines", false );
	mShowLines = CTinyXMLUtils::GetBoolNamed( inElement, "showLines", false );
	mWideMargins = CTinyXMLUtils::GetBoolNamed( inElement, "wideMargins", false );
	std::string	textAlignStr;
	CTinyXMLUtils::GetStringNamed( inElement, "textAlign", textAlignStr );
	mTextAlign = CVisiblePart::GetTextAlignFromString( textAlignStr.c_str() );
	mFont.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "font", mFont );
	mTextSize = CTinyXMLUtils::GetIntNamed( inElement, "textSize", 12 );
	mTextHeight = CTinyXMLUtils::GetIntNamed( inElement, "textHeight", 12 );
	tinyxml2::XMLElement * currStyle = inElement->FirstChildElement("textStyle");
	mTextStyle = EPartTextStylePlain;
	while( currStyle )
	{
		mTextStyle |= GetStyleFromString( currStyle->GetText() );
		currStyle = currStyle->NextSiblingElement( "textStyle" );
	}
	mHasHorizontalScroller = CTinyXMLUtils::GetBoolNamed( inElement, "hasHorizontalScroller", false );
	mHasVerticalScroller = CTinyXMLUtils::GetBoolNamed( inElement, "hasVerticalScroller", false );
	std::string	styleStr;
	CTinyXMLUtils::GetStringNamed( inElement, "style", styleStr );
	mFieldStyle = GetFieldStyleFromString( styleStr.c_str() );
	
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


void	CFieldPart::SavePropertiesToElementOfDocument( tinyxml2::XMLElement * inElement, tinyxml2::XMLDocument* document )
{
	CVisiblePart::SavePropertiesToElementOfDocument( inElement, document );
	
	tinyxml2::XMLElement	*	elem = document->NewElement("dontWrap");
	elem->SetBoolFirstChild(mDontWrap);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("dontSearch");
	elem->SetBoolFirstChild(mDontSearch);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("sharedText");
	elem->SetBoolFirstChild(mSharedText);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("fixedLineHeight");
	elem->SetBoolFirstChild(mFixedLineHeight);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("autoTab");
	elem->SetBoolFirstChild(mAutoTab);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("lockText");
	elem->SetBoolFirstChild(mLockText);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("style");
	elem->SetText( sFieldStyleStrings[mFieldStyle] );
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("autoSelect");
	elem->SetBoolFirstChild(mAutoSelect);
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("showLines");
	elem->SetBoolFirstChild(mShowLines);
	inElement->InsertEndChild(elem);

	elem = document->NewElement("wideMargins");
	elem->SetBoolFirstChild(mWideMargins);
	inElement->InsertEndChild(elem);

	elem = document->NewElement("multipleLines");
	elem->SetBoolFirstChild(mMultipleLines);
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
	
	elem = document->NewElement("textHeight");
	elem->SetText(mTextHeight);
	inElement->InsertEndChild(elem);
}


bool	CFieldPart::GetTextContents( std::string &outString )
{
	if( mViewTextNeedsSync )
		LoadChangedTextFromView();
		
	return CVisiblePart::GetTextContents( outString );
}


bool	CFieldPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("textStyle", inPropertyName) == 0 )
	{
		if( mViewTextNeedsSync )
			LoadChangedTextFromView();
		
		CPartContents*	theContents = NULL;
		CCard	*		currCard = GetStack()->GetCurrentCard();
		if( mOwner != currCard && !GetSharedText() )	// We're on the background layer, not on the card?
			theContents = currCard->GetPartContentsByID( GetID(), (mOwner != currCard) );
		else
			theContents = mOwner->GetPartContentsByID( GetID(), (mOwner != currCard) );
		std::map<std::string,std::string>	styles;
		bool								mixed = false;
		theContents->GetAttributedText().GetAttributesInRange( byteRangeStart, byteRangeEnd, styles, &mixed );
		if( mixed )
			LEOInitStringConstantValue( outValue, "mixed", kLEOInvalidateReferences, inContext );
		else if( styles.size() == 0 )
			LEOInitStringConstantValue( outValue, "plain", kLEOInvalidateReferences, inContext );
		else
		{
			LEOArrayEntry	*	theArray = NULL;
			char				tmpKey[512] = {0};
			size_t				x = 0;
			for( auto currStyle : styles )
			{
				if( currStyle.first.compare( "font-weight" ) == 0 && currStyle.second.compare( "bold" ) == 0 )
				{
					snprintf(tmpKey, sizeof(tmpKey) -1, "%zu", ++x );
					LEOAddStringConstantArrayEntryToRoot( &theArray, tmpKey, "bold", inContext );
				}
				else if( currStyle.first.compare( "text-style" ) == 0 && currStyle.second.compare( "italic" ) == 0 )
				{
					snprintf(tmpKey, sizeof(tmpKey) -1, "%zu", ++x );
					LEOAddStringConstantArrayEntryToRoot( &theArray, tmpKey, "italic", inContext );
				}
				else if( currStyle.first.compare( "text-decoration" ) == 0 && currStyle.second.compare( "underline" ) == 0 )
				{
					snprintf(tmpKey, sizeof(tmpKey) -1, "%zu", ++x );
					LEOAddStringConstantArrayEntryToRoot( &theArray, tmpKey, "underline", inContext );
				}
				else if( currStyle.first.compare( "$link" ) == 0 )
				{
					snprintf(tmpKey, sizeof(tmpKey) -1, "%zu", ++x );
					LEOAddStringConstantArrayEntryToRoot( &theArray, tmpKey, "group", inContext );
				}
				// +++ Add outline/shadow/condense/extend
			}
			
			LEOInitArrayValue( &outValue->array, theArray, kLEOInvalidateReferences, inContext );
		}
	}
	else if( strcasecmp("sharedText", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetSharedText(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("lockText", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mLockText, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("autoSelect", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mAutoSelect, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("selectedLine", inPropertyName) == 0 )
	{
		auto foundLine = mSelectedLines.lower_bound(0);
		if( foundLine != mSelectedLines.end() )
			LEOInitIntegerValue( outValue, *foundLine, kLEOUnitNone, kLEOInvalidateReferences, inContext );
		else
			LEOInitStringConstantValue( outValue, "none", kLEOInvalidateReferences, inContext );
	}
	else
		return CVisiblePart::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


/*static*/ void	CFieldPart::ApplyStyleStringToRangeOfAttributedString( const char* currStyleName, size_t byteRangeStart, size_t byteRangeEnd, CAttributedString& attrStr )
{
	if( strcasecmp(currStyleName, "plain") == 0 )
	{
		attrStr.ClearAttributeForRange( "text-decoration", byteRangeStart, byteRangeEnd );
		attrStr.ClearAttributeForRange( "font-weight", byteRangeStart, byteRangeEnd );
		attrStr.ClearAttributeForRange( "text-style", byteRangeStart, byteRangeEnd );
		attrStr.ClearAttributeForRange( "$link", byteRangeStart, byteRangeEnd );
	}
	else if( strcasecmp(currStyleName, "bold") == 0 )
		attrStr.AddAttributeValueForRange( "font-weight", "bold", byteRangeStart, byteRangeEnd );
	else if( strcasecmp(currStyleName, "italic") == 0 )
		attrStr.AddAttributeValueForRange( "text-style", "italic", byteRangeStart, byteRangeEnd );
	else if( strcasecmp(currStyleName, "underline") == 0 )
		attrStr.AddAttributeValueForRange( "text-decoration", "underline", byteRangeStart, byteRangeEnd );
	else if( strcasecmp(currStyleName, "group") == 0 )
		attrStr.AddAttributeValueForRange( "$link", "#", byteRangeStart, byteRangeEnd );
	else
		;	// +++ Add outline/shadow/condense/extend
}


bool	CFieldPart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("family", inPropertyName) == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEOInteger	familyNum = LEOGetValueAsInteger( inValue, &theUnit, inContext );
		if( !inContext->keepRunning )
			return true;
		SetFamily( familyNum );
	}
	else if( strcasecmp("textStyle", inPropertyName) == 0 )
	{
		if( mViewTextNeedsSync )
			LoadChangedTextFromView();
		
		CPartContents*	theContents = NULL;
		size_t	numStyles = LEOGetKeyCount( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		CCard	*		currCard = GetStack()->GetCurrentCard();
		CLayer	*		contentsOwner = (mOwner != currCard && !GetSharedText()) ? currCard : mOwner;
		theContents = contentsOwner->GetPartContentsByID( GetID(), (mOwner != currCard) );
		if( !theContents )
		{
			theContents = new CPartContents( currCard );
			theContents->SetID( GetID() );
			theContents->SetIsOnBackground( mOwner != currCard );
			contentsOwner->AddPartContents( theContents );
		}

		CAttributedString&	attrStr = theContents->GetAttributedText();
		ApplyStyleStringToRangeOfAttributedString( "plain", byteRangeStart, byteRangeEnd, attrStr );	// Clear other styles.
		LEOValue	tmpStorage = {{0}};
		char		tmpKey[512] = {0};
		for( size_t x = 1; x <= numStyles; x++ )
		{
			snprintf(tmpKey, sizeof(tmpKey)-1, "%zu", x );
			LEOValuePtr theValue = LEOGetValueForKey( inValue, tmpKey, &tmpStorage, kLEOInvalidateReferences, inContext );
			const char*	currStyleName = LEOGetValueAsString( theValue, tmpKey, sizeof(tmpKey), inContext );
			if( !inContext->keepRunning )
				return true;
			ApplyStyleStringToRangeOfAttributedString( currStyleName, byteRangeStart, byteRangeEnd, attrStr );
			if( theValue == &tmpStorage )
				LEOCleanUpValue( theValue, kLEOInvalidateReferences, inContext );
		}
		
		if( numStyles == 0 )	// Not a valid array? Also permit just specifying a single style string.
		{
			const char*	currStyleName = LEOGetValueAsString( inValue, tmpKey, sizeof(tmpKey), inContext );
			if( !inContext->keepRunning )
				return true;
			ApplyStyleStringToRangeOfAttributedString( currStyleName, byteRangeStart, byteRangeEnd, attrStr );
		}
		
		LoadChangedTextStylesIntoView();
	}
	else if( strcasecmp("autoSelect", inPropertyName) == 0 )
	{
		bool	theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		SetAutoSelect( theHighlight );
	}
	else if( strcasecmp("sharedText", inPropertyName) == 0 )
	{
		bool	theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		SetSharedText( theHighlight );
	}
	else if( strcasecmp("lockText", inPropertyName) == 0 )
	{
		bool	theShowName = LEOGetValueAsBoolean( inValue, inContext );
		if( !inContext->keepRunning )
			return true;
		SetLockText( theShowName );
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
	else
		return CVisiblePart::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


void	CFieldPart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
	printf( "%sstyle = %s\n", indentStr, sFieldStyleStrings[mFieldStyle] );
	printf( "%sdontWrap = %s\n", indentStr, (mDontWrap ? "true" : "false") );
	printf( "%sdontSearch = %s\n", indentStr, (mDontSearch ? "true" : "false") );
	printf( "%ssharedText = %s\n", indentStr, (mSharedText ? "true" : "false") );
	printf( "%sfixedLineHeight = %s\n", indentStr, (mFixedLineHeight ? "true" : "false") );
	printf( "%sautoTab = %s\n", indentStr, (mAutoTab ? "true" : "false") );
	printf( "%slockText = %s\n", indentStr, (mLockText ? "true" : "false") );
	printf( "%sautoSelect = %s\n", indentStr, (mAutoSelect ? "true" : "false") );
	printf( "%smultipleLines = %s\n", indentStr, (mMultipleLines ? "true" : "false") );
	printf( "%sshowLines = %s\n", indentStr, (mShowLines ? "true" : "false") );
	printf( "%swideMargins = %s\n", indentStr, (mWideMargins ? "true" : "false") );
	printf( "%stextAlign = %d\n", indentStr, mTextAlign );
	printf( "%sfont = %s\n", indentStr, mFont.c_str() );
	printf( "%stextSize = %d\n", indentStr, mTextSize );
	printf( "%shasHorizontalScroller = %s\n", indentStr, (mHasHorizontalScroller ? "true" : "false") );
	printf( "%shasVerticalScroller = %s\n", indentStr, (mHasVerticalScroller ? "true" : "false") );
}