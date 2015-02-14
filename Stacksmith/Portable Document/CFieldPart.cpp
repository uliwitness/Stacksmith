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
#include "CDocument.h"


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
	"search",
	"*UNKNOWN*"
};


static const char*	sColumnTypeStrings[EColumnType_Last +1] =
{
	"text",
	"checkbox",
	"icon",
	"*UNKNOWN*"
};


TFieldStyle	CFieldPart::GetFieldStyleFromString( const char* inStyleStr )
{
	for( size_t x = 0; x < EFieldStyle_Last; x++ )
	{
		if( strcasecmp(sFieldStyleStrings[x],inStyleStr) == 0 )
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
	mCursorID = CTinyXMLUtils::GetLongLongNamed( inElement, "cursor", 128 );
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
	mHasColumnHeaders = CTinyXMLUtils::GetBoolNamed( inElement, "hasColumnHeaders", false );
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
			mSelectedLines.insert( CTinyXMLUtils::GetLongLongNamed( currSelLine, NULL ) );
			currSelLine = currSelLine->NextSiblingElement( "integer" );
		}
	}
	
	bool					columnObjects = true;
	tinyxml2::XMLElement *	column = inElement->FirstChildElement("column");
	if( !column )
	{
		column = inElement->FirstChildElement("columnType");
		columnObjects = false;
	}
	while( column )
	{
		tinyxml2::XMLElement	*	currType = column->FirstChildElement("type");
		tinyxml2::XMLElement	*	currName = column->FirstChildElement("name");
		long long					currWidth = CTinyXMLUtils::GetLongLongNamed( column, "width", 100 );
		bool						currEditable = CTinyXMLUtils::GetBoolNamed( column, "editable", false );
		if( !columnObjects )
		{
			currType = column;
		}
		const char*	columnTypeStr = currType->GetText();
		for( size_t x = 0; x < EColumnType_Last; x++ )
		{
			if( strcasecmp(columnTypeStr, sColumnTypeStrings[x]) == 0 )
			{
				CColumnInfo	info = { (TColumnType) x, currWidth, "", currEditable };
				if( currName )
					info.mName = currName->GetText();
				mColumns.push_back( info );
				break;
			}
		}
		column = column->NextSiblingElement( columnObjects ? "column" : "columnType" );
	}
}


void	CFieldPart::SavePropertiesToElement( tinyxml2::XMLElement * inElement )
{
	if( mViewTextNeedsSync )
		LoadChangedTextFromView();

	CVisiblePart::SavePropertiesToElement( inElement );

	tinyxml2::XMLDocument* document = inElement->GetDocument();
	
	CTinyXMLUtils::AddBoolNamed( inElement, mDontWrap, "dontWrap" );
	CTinyXMLUtils::AddBoolNamed( inElement, mDontSearch, "dontSearch" );
	CTinyXMLUtils::AddBoolNamed( inElement, mSharedText, "sharedText" );
	CTinyXMLUtils::AddBoolNamed( inElement, mFixedLineHeight, "fixedLineHeight" );
	CTinyXMLUtils::AddBoolNamed( inElement, mAutoTab, "autoTab" );
	CTinyXMLUtils::AddBoolNamed( inElement, mLockText, "lockText" );

	tinyxml2::XMLElement	*	elem = document->NewElement("style");
	elem->SetText( sFieldStyleStrings[mFieldStyle] );
	inElement->InsertEndChild(elem);
	
	CTinyXMLUtils::AddBoolNamed( inElement, mAutoSelect, "autoSelect" );
	CTinyXMLUtils::AddBoolNamed( inElement, mShowLines, "showLines" );
	CTinyXMLUtils::AddBoolNamed( inElement, mWideMargins, "wideMargins" );
	CTinyXMLUtils::AddBoolNamed( inElement, mMultipleLines, "multipleLines" );
	CTinyXMLUtils::AddLongLongNamed( inElement, mCursorID, "cursor");
	CTinyXMLUtils::AddBoolNamed( inElement, mHasHorizontalScroller, "hasHorizontalScroller" );
	CTinyXMLUtils::AddBoolNamed( inElement, mHasVerticalScroller, "hasVerticalScroller" );
	CTinyXMLUtils::AddBoolNamed( inElement, mHasColumnHeaders, "hasColumnHeaders" );
	
	if( !mSelectedLines.empty() )
	{
		elem = document->NewElement("selectedLines");
		for( size_t currLine : mSelectedLines )
		{
			CTinyXMLUtils::AddLongLongNamed( elem, currLine, "integer" );
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

	for( const CColumnInfo& currColumn : mColumns )
	{
		elem = document->NewElement("column");
		CTinyXMLUtils::AddStringNamed( elem, sColumnTypeStrings[currColumn.mType], "type" );
		CTinyXMLUtils::AddLongLongNamed( elem, currColumn.mWidth, "width" );
		CTinyXMLUtils::AddStringNamed( elem, currColumn.mName.c_str(), "name" );
		CTinyXMLUtils::AddBoolNamed( elem, currColumn.mEditable, "editable" );
		inElement->InsertEndChild(elem);
	}
}


bool	CFieldPart::GetTextContents( std::string &outString )
{
	if( mViewTextNeedsSync )
		LoadChangedTextFromView();
		
	return CVisiblePart::GetTextContents( outString );
}


bool	CFieldPart::SetTextContents( const std::string& inString )
{
	CVisiblePart::SetTextContents( inString );
	
	LoadChangedTextStylesIntoView();
	
	return true;
}


bool	CFieldPart::ParseRowColumnString( const char* inPropertyName, LEOInteger *outRow, LEOInteger *outColumn )
{
	if( strncasecmp("column ", inPropertyName, 7) != 0 )
		return false;
	
	char*		endPtr = NULL;
	LEOInteger	oneBasedColumnIndex = strtoll(inPropertyName + 7, &endPtr, 10 );
	LEOInteger	oneBasedRowIndex = 0LL;
	if( strncasecmp(endPtr, " row ", 5 ) == 0 )	// We have a row.
	{
		char*		rowStr = endPtr +5;
		char*		endPtr2 = NULL;
		oneBasedRowIndex = strtoll(rowStr, &endPtr2, 10 );
		
		if( endPtr2 != (rowStr +strlen(rowStr)) )
			return false;
	}
	else if( (*endPtr) != 0 )	// String hasn't ended after column but isn't " row "? Invalid!
		return false;
	
	*outColumn = oneBasedColumnIndex;
	*outRow = oneBasedRowIndex;
	
	return true;
}


bool	CFieldPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	LEOInteger		oneBasedColumnIndex = 0;
	LEOInteger		oneBasedRowIndex = 0;

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
		CMap<std::string>	styles;
		bool				mixed = false;
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
			LEOInitRangeValue( outValue, *foundLine, *foundLine, kLEOChunkTypeLine, kLEOInvalidateReferences, inContext );
		else
			LEOInitStringConstantValue( outValue, "none", kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("selectedRange", inPropertyName) == 0 )
	{
		size_t			startOffs = 0, endOffs = 0;
		LEOChunkType	type = kLEOChunkTypeINVALID;
		GetSelectedRange( &type, &startOffs, &endOffs );
		LEOInitRangeValue( outValue, startOffs, endOffs, type, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("style", inPropertyName) == 0 )
	{
		LEOInitStringConstantValue( outValue, sFieldStyleStrings[mFieldStyle], kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("hasHorizontalScroller", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mHasHorizontalScroller, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("hasVerticalScroller", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mHasVerticalScroller, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("hasColumnHeaders", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mHasColumnHeaders, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("columnTypes", inPropertyName) == 0 )
	{
		LEOArrayEntry	*	theArray = NULL;
		char				tmpKey[512] = {0};
		size_t				x = 0;
		for( const CColumnInfo& currColumn : mColumns )
		{
			snprintf(tmpKey, sizeof(tmpKey) -1, "%zu", ++x );
			LEOAddStringConstantArrayEntryToRoot( &theArray, tmpKey, sColumnTypeStrings[currColumn.mType], inContext );
		}
		
		LEOInitArrayValue( &outValue->array, theArray, kLEOInvalidateReferences, inContext );
	}
	else if( ParseRowColumnString( inPropertyName, &oneBasedRowIndex, &oneBasedColumnIndex ) )	// Starts with "column "?
	{
		std::string			currText;
		if( oneBasedRowIndex != 0 )
		{
			CPartContents*		contents = GetContentsOnCurrentCard();
			if( contents )
			{
				currText = contents->GetAttributedTextInRowColumn( oneBasedRowIndex -1, oneBasedColumnIndex -1 ).GetString();
			}
		}
		else
		{
			if( oneBasedColumnIndex < 1 || (size_t)oneBasedColumnIndex > mColumns.size() )
				return false;
			
			currText = mColumns[oneBasedColumnIndex-1].mName;
		}
		
		LEOInitStringValue( outValue, currText.c_str(), currText.length(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("cursor", inPropertyName) == 0 )
	{
		LEOInitIntegerValue( outValue, mCursorID, kLEOUnitNone, kLEOInvalidateReferences, inContext );
	}
	else
	{
		return CVisiblePart::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	}
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
	LEOInteger		oneBasedColumnIndex = 0;
	LEOInteger		oneBasedRowIndex = 0;
	
	if( strcasecmp("family", inPropertyName) == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEOInteger	familyNum = LEOGetValueAsInteger( inValue, &theUnit, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetFamily( familyNum );
	}
	else if( strcasecmp("textStyle", inPropertyName) == 0 )
	{
		if( mViewTextNeedsSync )
			LoadChangedTextFromView();
		
		CPartContents*	theContents = NULL;
		size_t	numStyles = LEOGetKeyCount( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		{
			numStyles = 0;	// Single style is caught below.
			inContext->flags |= kLEOContextKeepRunning;
		}
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
			if( (inContext->flags & kLEOContextKeepRunning) == 0 )
				return true;
			ApplyStyleStringToRangeOfAttributedString( currStyleName, byteRangeStart, byteRangeEnd, attrStr );
			if( theValue == &tmpStorage )
				LEOCleanUpValue( theValue, kLEOInvalidateReferences, inContext );
		}
		
		if( numStyles == 0 )	// Not a valid array? Also permit just specifying a single style string.
		{
			const char*	currStyleName = LEOGetValueAsString( inValue, tmpKey, sizeof(tmpKey), inContext );
			if( (inContext->flags & kLEOContextKeepRunning) == 0 )
				return true;
			ApplyStyleStringToRangeOfAttributedString( currStyleName, byteRangeStart, byteRangeEnd, attrStr );
		}
		
		LoadChangedTextStylesIntoView();
	}
	else if( strcasecmp("autoSelect", inPropertyName) == 0 )
	{
		bool	theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetAutoSelect( theHighlight );
	}
	else if( strcasecmp("sharedText", inPropertyName) == 0 )
	{
		bool	theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetSharedText( theHighlight );
	}
	else if( strcasecmp("lockText", inPropertyName) == 0 )
	{
		bool	theShowName = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
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
			if( (inContext->flags & kLEOContextKeepRunning) == 0 )
				return true;
		}
		mSelectedLines.erase(mSelectedLines.begin(), mSelectedLines.end());
		if( theSelectedLine != 0 )
			mSelectedLines.insert(theSelectedLine);
		ApplyChangedSelectedLinesToView();
	}
	else if( strcasecmp("selectedRange",inPropertyName) == 0 )
	{
		LEOInteger		s = 0, e = 0;
		LEOChunkType	t = kLEOChunkTypeINVALID;
		LEOGetValueAsRange( inValue, &s, &e, &t, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetSelectedRange( t, s, e );
	}
	else if( strcasecmp("style", inPropertyName) == 0 )
	{
		char		nameBuf[1024];
		const char*	nameStr = LEOGetValueAsString( inValue, nameBuf, sizeof(nameBuf), inContext );
		TFieldStyle	style = GetFieldStyleFromString(nameStr);
		if( style == EFieldStyle_Last )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unknown field style \"%s\".", nameStr );
		}
		else
			SetStyle( style );
	}
	else if( strcasecmp("hasHorizontalScroller", inPropertyName) == 0 )
	{
		bool	theHasScroller = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetHasHorizontalScroller( theHasScroller );
	}
	else if( strcasecmp("hasVerticalScroller", inPropertyName) == 0 )
	{
		bool	theHasScroller = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetHasVerticalScroller( theHasScroller );
	}
	else if( strcasecmp("hasColumnHeaders", inPropertyName) == 0 )
	{
		bool	theHasScroller = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetHasColumnHeaders( theHasScroller );
	}
	else if( strcasecmp("columnTypes", inPropertyName) == 0 )
	{
		CPartContents*	theContents = NULL;
		size_t	numStyles = LEOGetKeyCount( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
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

		mColumns.clear();	// Clear columns.
		LEOValue	tmpStorage = {{0}};
		char		tmpKey[512] = {0};
		for( size_t x = 1; x <= numStyles; x++ )
		{
			bool		foundType = false;
			
			snprintf(tmpKey, sizeof(tmpKey)-1, "%zu", x );
			LEOValuePtr theValue = LEOGetValueForKey( inValue, tmpKey, &tmpStorage, kLEOInvalidateReferences, inContext );
			const char*	currColumnType = LEOGetValueAsString( theValue, tmpKey, sizeof(tmpKey), inContext );
			if( (inContext->flags & kLEOContextKeepRunning) == 0 )
				return true;
			
			for( size_t y = 0; (y < EColumnType_Last) && !foundType; y++ )
			{
				if( strcasecmp( sColumnTypeStrings[y], currColumnType ) == 0 )
				{
					CColumnInfo	info = { (TColumnType) y, 100, "New Column", (y == EColumnTypeCheckbox) || (y == EColumnTypeText) };	// Check boxes *must* be editable, and text is useful for creating new rows. Images are usually not intended for editing, so default to false.
					mColumns.push_back( info );
					foundType = true;
				}
			}
			
			if( !foundType )
			{
				size_t		lineNo = 0;
				uint16_t	fileID = 0;
				LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
				LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unknown column type '%s'.", currColumnType );
			}
			
			if( theValue == &tmpStorage )
			{
				LEOCleanUpValue( theValue, kLEOInvalidateReferences, inContext );
			}
			
			if( !foundType )
				return true;
		}
	}
	else if( strcasecmp("cursor", inPropertyName) == 0 )
	{
		LEOInteger	theIconID = 0;
		char		strBuf[100] = {0};
		const char* str = LEOGetValueAsString( inValue, strBuf, sizeof(strBuf), inContext );
		if( strcasecmp(str, "none") != 0 && str[0] != 0 )
		{
			if( LEOCanGetAsNumber( inValue, inContext ) )
			{
				LEOUnit		outUnit = kLEOUnitNone;
				theIconID = LEOGetValueAsInteger( inValue, &outUnit, inContext );
			}
			else
			{
				theIconID = GetStack()->GetDocument()->GetMediaCache().GetMediaIDByNameOfType( str, EMediaTypeCursor );
			}
			if( (inContext->flags & kLEOContextKeepRunning) == 0 )
				return true;
		}
		SetCursorID(theIconID);
	}
	else if( ParseRowColumnString( inPropertyName, &oneBasedRowIndex, &oneBasedColumnIndex ) )
	{
		char		tmpStr[1024] = {0};
		const char*	newColumnName = LEOGetValueAsString( inValue, tmpStr, sizeof(tmpStr), inContext );
		
		if( oneBasedRowIndex != 0 )
		{
			CPartContents*		contents = GetContentsOnCurrentCard();
			if( contents )
			{
				contents->SetAttributedTextInRowColumn( CAttributedString(newColumnName), oneBasedRowIndex -1, oneBasedColumnIndex -1 );
			}
		}
		else
		{
			if( oneBasedColumnIndex < 1 || (size_t)oneBasedColumnIndex > mColumns.size() )
				return false;
			
			mColumns[oneBasedColumnIndex-1].mName = newColumnName;
		}
		
		LoadChangedTextStylesIntoView();
		
		return true;
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
	printf( "%shasColumnHeaders = %s\n", indentStr, (mHasColumnHeaders ? "true" : "false") );
	printf( "%scolumnTypes =", indentStr );
	for( const CColumnInfo& currColumn : mColumns )
	{
		printf( " [%s \"%s\" (%lld pt)%s]", sColumnTypeStrings[currColumn.mType], currColumn.mName.c_str(), currColumn.mWidth, currColumn.mEditable? " editable" : "" );
	}
	printf( "\n" );
}