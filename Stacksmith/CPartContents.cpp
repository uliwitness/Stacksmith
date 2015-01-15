//
//  CPartContents.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CPartContents.h"
#include "CTinyXMLUtils.h"
#include "CDocument.h"


using namespace Carlson;



CPartContents::CPartContents( CLayer* owningLayer, tinyxml2::XMLElement * inElement, CStyleSheet* inStyleSheet )
{
	mID = CTinyXMLUtils::GetLongLongNamed( inElement, "id" );
	mHighlight = CTinyXMLUtils::GetBoolNamed( inElement, "highlight", false );
	tinyxml2::XMLElement * tableElement = inElement->FirstChildElement( "table" );
	if( tableElement )
	{
		tinyxml2::XMLElement * rowElement = tableElement->FirstChildElement( "tr" );
		while( rowElement )
		{
			mCells.push_back( std::vector<CAttributedString>() );
			std::vector<CAttributedString>&		currRow = mCells.back();
			
			tinyxml2::XMLElement * cellElement = tableElement->FirstChildElement( "td" );
			while( cellElement )
			{
				CAttributedString	attrStr;
				attrStr.LoadFromElementWithStyles( cellElement, inStyleSheet ? *inStyleSheet : owningLayer->GetStyles() );
				currRow.push_back(attrStr);
				
				cellElement = cellElement->NextSiblingElement( "td" );
			}
			rowElement = rowElement->NextSiblingElement( "tr" );
		}
	}
	else
	{
		tinyxml2::XMLElement * textElement = inElement->FirstChildElement( "text" );
		if( textElement )
		{
			mAttributedString.LoadFromElementWithStyles( textElement, inStyleSheet ? *inStyleSheet : owningLayer->GetStyles() );
		}
	}
	std::string	theLayerStr;
	CTinyXMLUtils::GetStringNamed( inElement, "layer", theLayerStr );
	mIsOnBackground = (theLayerStr.compare("background") == 0);
	mOwningLayer = owningLayer;
}


void	CPartContents::SaveToElementAndStyleSheet( tinyxml2::XMLElement * inElement, CStyleSheet *styleSheet )
{
	tinyxml2::XMLDocument	*	document = inElement->GetDocument();
	CTinyXMLUtils::AddStringNamed(inElement, (mIsOnBackground ? "background" : "card"), "layer" );
	CTinyXMLUtils::AddLongLongNamed( inElement, mID, "id" );
	tinyxml2::XMLElement	*	elem = NULL;
	
	if( mHighlight )
		CTinyXMLUtils::AddBoolNamed( inElement, mHighlight, "highlight" );
	
	if( mCells.size() > 0 )
	{
		elem = document->NewElement("table");
		for( const std::vector<CAttributedString>& currRow : mCells )
		{
			tinyxml2::XMLElement	*	rowElem = document->NewElement("tr");
			for( const CAttributedString& currCell : currRow )
			{
				tinyxml2::XMLElement	*	cellElem = document->NewElement("td");
				currCell.SaveToXMLDocumentElementStyleSheet( document, cellElem, styleSheet );
				rowElem->InsertEndChild(cellElem);
			}
			elem->InsertEndChild(rowElem);
		}
		inElement->InsertEndChild(elem);
	}
	else if( mAttributedString.GetLength() > 0 )
	{
		elem = document->NewElement("text");
		mAttributedString.SaveToXMLDocumentElementStyleSheet( document, elem, styleSheet );
		inElement->InsertEndChild(elem);
	}
}


void	CPartContents::IncrementChangeCount()
{
	mOwningLayer->IncrementChangeCount();
}


void	CPartContents::Dump( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%sContents for %s part ID %lld\n%s{\n", indentStr, (mIsOnBackground?"bg":"cd"), mID, indentStr );
	printf( "%s\thighlight = %s\n", indentStr, (mHighlight?"true":"false") );
	printf( "%s\ttable =\n%s\t{\n", indentStr, indentStr );
	for( const std::vector<CAttributedString>& currRow : mCells )
	{
		for( const CAttributedString& currCell : currRow )
			currCell.Dump( inIndent +2 );
		printf( "%s\t---------------\n", indentStr );
	}
	printf( "%s\t}\n", indentStr );
	printf( "%s\ttext =\n%s\t{\n", indentStr, indentStr );
	mAttributedString.Dump( inIndent +2 );
	printf( "%s\t}\n", indentStr );
	printf( "%s}\n", indentStr );
}
