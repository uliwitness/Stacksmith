//
//  CGraphicPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CGraphicPart.h"
#include "CTinyXMLUtils.h"
#include "CCard.h"
#include "CBackground.h"
#include "CStack.h"
#include "CDocument.h"
#include <math.h>


using namespace Carlson;


static const char*	sGraphicStyleStrings[EGraphicStyle_Last +1] =
{
	"rectangle",
	"roundrect",
	"oval",
	"line",
	"bezierpath",
	"*UNKNOWN*"
};


TGraphicStyle	CGraphicPart::GetGraphicStyleFromString( const char* inStr )
{
	for( size_t x = 0; x < EGraphicStyle_Last; x++ )
	{
		if( strcasecmp( sGraphicStyleStrings[x], inStr ) == 0 )
		{
			return (TGraphicStyle)x;
		}
	}
	return EGraphicStyle_Last;
}


void	CGraphicPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::LoadPropertiesFromElement( inElement );
	
	std::string		styleStr("rectangle");
	CTinyXMLUtils::GetStringNamed( inElement, "style", styleStr );
	mStyle = GetGraphicStyleFromString( styleStr.c_str() );
	if( mStyle == EGraphicStyle_Last )
		mStyle = EGraphicStyleRectangle;
	
	mPoints.erase(mPoints.begin(), mPoints.end());
	tinyxml2::XMLElement * selLines = inElement->FirstChildElement("path");
	if( selLines )
	{
		tinyxml2::XMLElement * currSelLine = selLines->FirstChildElement("segment");
		while( currSelLine )
		{
			LEONumber		x = CTinyXMLUtils::GetDoubleNamed( currSelLine, "x" );
			LEONumber		y = CTinyXMLUtils::GetDoubleNamed( currSelLine, "y" );
			LEONumber		lineWidth = CTinyXMLUtils::GetDoubleNamed( currSelLine, "lineWidth", 1.0 );
			CPathSegment	segment = { x, y, lineWidth };
			mPoints.push_back( segment );
			currSelLine = currSelLine->NextSiblingElement( "segment" );
		}
	}
}


void	CGraphicPart::SavePropertiesToElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::SavePropertiesToElement( inElement );
	
	CTinyXMLUtils::AddStringNamed( inElement, sGraphicStyleStrings[mStyle], "style" );

	tinyxml2::XMLDocument* document = inElement->GetDocument();
	
	if( !mPoints.empty() )
	{
		tinyxml2::XMLElement	*	elem = document->NewElement("path");
		for( const CPathSegment& currLine : mPoints )
		{
			tinyxml2::XMLElement	*	segmentElem = document->NewElement("segment");
			CTinyXMLUtils::AddDoubleNamed( segmentElem, currLine.x, "x" );
			CTinyXMLUtils::AddDoubleNamed( segmentElem, currLine.y, "y" );
			if( currLine.lineWidth == 1.0 )
				CTinyXMLUtils::AddDoubleNamed( segmentElem, currLine.lineWidth, "lineWidth" );
			elem->InsertEndChild(segmentElem);
		}
		inElement->InsertEndChild(elem);
	}
}


bool	CGraphicPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("points", inPropertyName) == 0 )
	{
		LEOArrayEntry	*	theArray = NULL;
		char				tmpKey[512] = {0};
		size_t				x = 0;
		
		for( const CPathSegment& currLine :	mPoints )
		{
			snprintf(tmpKey, sizeof(tmpKey) -1, "%zu", ++x );
			LEOAddPointArrayEntryToRoot( &theArray, tmpKey, currLine.x +GetLeft(), currLine.y +GetTop(), inContext );
		}

		LEOInitArrayValue( &outValue->array, theArray, kLEOInvalidateReferences, inContext );
	}
	else
	{
		return CVisiblePart::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	}
	return true;
}


bool	CGraphicPart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("points", inPropertyName) == 0 )
	{
//		CPartContents*	theContents = NULL;
//		size_t	numStyles = LEOGetKeyCount( inValue, inContext );
//		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
//			return true;
//		CCard	*		currCard = GetStack()->GetCurrentCard();
//		CLayer	*		contentsOwner = (mOwner != currCard && !GetSharedText()) ? currCard : mOwner;
//		theContents = contentsOwner->GetPartContentsByID( GetID(), (mOwner != currCard) );
//		if( !theContents )
//		{
//			theContents = new CPartContents( currCard );
//			theContents->SetID( GetID() );
//			theContents->SetIsOnBackground( mOwner != currCard );
//			contentsOwner->AddPartContents( theContents );
//		}
//
//		mColumns.clear();	// Clear columns.
//		LEOValue	tmpStorage = {{0}};
//		char		tmpKey[512] = {0};
//		for( size_t x = 1; x <= numStyles; x++ )
//		{
//			bool		foundType = false;
//			
//			snprintf(tmpKey, sizeof(tmpKey)-1, "%zu", x );
//			LEOValuePtr theValue = LEOGetValueForKey( inValue, tmpKey, &tmpStorage, kLEOInvalidateReferences, inContext );
//			const char*	currColumnType = LEOGetValueAsString( theValue, tmpKey, sizeof(tmpKey), inContext );
//			if( (inContext->flags & kLEOContextKeepRunning) == 0 )
//				return true;
//			
//			for( size_t y = 0; (y < EColumnType_Last) && !foundType; y++ )
//			{
//				if( strcasecmp( sColumnTypeStrings[y], currColumnType ) == 0 )
//				{
//					CColumnInfo	info = { (TColumnType) y, 100, "New Column", (y == EColumnTypeCheckbox) || (y == EColumnTypeText) };	// Check boxes *must* be editable, and text is useful for creating new rows. Images are usually not intended for editing, so default to false.
//					mColumns.push_back( info );
//					foundType = true;
//				}
//			}
//			
//			if( !foundType )
//			{
//				size_t		lineNo = 0;
//				uint16_t	fileID = 0;
//				LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
//				LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unknown column type '%s'.", currColumnType );
//			}
//			
//			if( theValue == &tmpStorage )
//			{
//				LEOCleanUpValue( theValue, kLEOInvalidateReferences, inContext );
//			}
//			
//			if( !foundType )
//				return true;
//		}
	}
	else
		return CVisiblePart::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


void	CGraphicPart::AddPoint( LEONumber x, LEONumber y, LEONumber lineWidth )
{
	CPathSegment		newPoint = {0};
	newPoint.x = x;
	newPoint.y = y;
	newPoint.lineWidth = lineWidth;
	mPoints.push_back( newPoint );
	
	IncrementChangeCount();
}


void	CGraphicPart::UpdateLastPoint( LEONumber x, LEONumber y, LEONumber lineWidth )
{
	CPathSegment& lastSegment = mPoints.back();
	lastSegment.x = x;
	lastSegment.y = y;
	lastSegment.lineWidth = lineWidth;
	
	IncrementChangeCount();
}


bool	CGraphicPart::CanBeEditedWithTool( TTool inTool )
{
	if( inTool == EPointerTool )
		return true;
	if( mStyle == EGraphicStyleRectangle && inTool == ERectangleTool )
		return true;
	if( mStyle == EGraphicStyleRoundrect && inTool == ERoundrectTool )
		return true;
	if( mStyle == EGraphicStyleOval && inTool == EOvalTool )
		return true;
	if( mStyle == EGraphicStyleLine && inTool == ELineTool )
		return true;
	if( mStyle == EGraphicStyleBezierPath && inTool == EBezierPathTool )
		return true;
	
	return false;
}


void	CGraphicPart::SizeToFit()
{
	if( mStyle == EGraphicStyleLine || mStyle == EGraphicStyleBezierPath )	// All other styles' sizes are defined by the part rect.
	{
		LEONumber	originalTop = GetTop(), originalLeft = GetLeft(),
					originalBottom = GetBottom(), originalRight = GetRight();
		LEONumber	top = originalBottom, bottom = originalTop, left = originalRight, right = originalLeft;	// Set to opposite sides so we can increment to calc min/max.
		for( const CPathSegment& currPoint : mPoints )
		{
			if( (currPoint.y +originalTop) < top )
				top = (currPoint.y +originalTop);
			if( (currPoint.y +originalTop) > bottom )
				bottom = (currPoint.y +originalTop);
			if( (currPoint.x +originalLeft) < left )
				left = (currPoint.x +originalLeft);
			if( (currPoint.x +originalLeft) > right )
				right = (currPoint.x +originalLeft);
		}
		
		left = truncf(left) -GetLineWidth();
		right = ceilf(right) +GetLineWidth();
		top = truncf(top) -GetLineWidth();
		bottom = ceilf(bottom) +GetLineWidth();
		
		LEONumber	xoffs = originalLeft -left, yoffs = originalTop -top;
		
		if( xoffs != 0 || yoffs != 0 )
		{
			for( CPathSegment& currPoint : mPoints )
			{
				currPoint.x += xoffs;
				currPoint.y += yoffs;
			}
		}
		
		if( left != originalLeft || right != originalRight || top != originalTop || bottom != originalBottom )
		{
			SetRect( left, top, right, bottom );
			IncrementChangeCount();
		}
	}
}


LEOInteger	CGraphicPart::GetNumCustomHandlesForTool( TTool inTool )
{
	if( mStyle == EGraphicStyleLine && inTool == ELineTool )
	{
		return mPoints.size();
	}
	else if( mStyle == EGraphicStyleBezierPath && inTool == EBezierPathTool )
	{
		return mPoints.size();
	}
	
	return -1;
}


void	CGraphicPart::SetPositionOfCustomHandleAtIndex( LEOInteger idx, LEONumber x, LEONumber y )
{
	CPathSegment& currPoint = mPoints[idx];
	
	currPoint.x = x -GetLeft();
	currPoint.y = y -GetTop();
	
	SizeToFit();
	IncrementChangeCount();
}


void	CGraphicPart::GetPositionOfCustomHandleAtIndex( LEOInteger idx, LEONumber *outX, LEONumber *outY )
{
	const CPathSegment& currPoint = mPoints[idx];
	
	*outX = currPoint.x +GetLeft();
	*outY = currPoint.y +GetTop();
}


void	CGraphicPart::SetSelected( bool inSelected, LEOInteger inHandleIndex )
{
	CVisiblePart::SetSelected( inSelected, inHandleIndex );
}


/*static*/ void	CGraphicPart::ConvertPointsToStepSize( const std::vector<LEONumber>& inCoordinates, LEONumber stepSize, std::vector<LEONumber>& outCoordinates )
{
	LEONumber		oldX = 0;
	LEONumber		oldY = 0;
	bool			firstRound = true;
	LEONumber		leftoverLength = 0;
	size_t			idx = 0;
	
	auto coordItty = inCoordinates.begin();
	while( coordItty != inCoordinates.end() )
	{
		LEONumber	x = *coordItty;
		coordItty++;
		if( coordItty == inCoordinates.end() )
			break;
		LEONumber	y = *coordItty;
		coordItty++;
		
		if( !firstRound )
		{
			LEONumber		xdiff = x - oldX;
			LEONumber		ydiff = y - oldY;
			LEONumber		startX = oldX;
			LEONumber		startY = oldY;
			
			LEONumber		segmentLength = sqrt( xdiff * xdiff + ydiff * ydiff );
			LEONumber		currLen = 0;
			LEONumber		radians = (xdiff == 0) ? (M_PI / 2.0) : atan( ydiff / xdiff );
			if( radians > (M_PI * 2.0) )
			{
				radians -= M_PI * 2.0;
			}
			if( radians < 0 )
			{
				radians += M_PI * 2.0;
			}
			for( currLen = leftoverLength; currLen <= segmentLength; currLen += stepSize )
			{
				LEONumber		newX = startX + currLen * cos( radians );
				LEONumber		newY = startY + currLen * sin( radians );
				
				idx++;
				idx++;
				std::cout << idx << ": " << x << "," << y << " -> " << newX << "," << newY << " [" << currLen << ", " << (radians / (2 * M_PI)) << "]" << std::endl;
				
				outCoordinates.push_back( newX );
				outCoordinates.push_back( newY );
			}
			
			leftoverLength = std::min( LEONumber(0), segmentLength -currLen );
		}
		else
		{
			firstRound = false;
			std::cout << idx << ": " << x << "," << y << std::endl;
		}
		
		oldX = x;
		oldY = y;
	}
	
	if( leftoverLength > 0 )
	{
		outCoordinates.push_back( oldX );
		outCoordinates.push_back( oldY );
	}
}


void	CGraphicPart::DumpProperties( size_t inIndentLevel )
{
//	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
//	for( const CColumnInfo& currColumn : mColumns )
//	{
//		printf( " [%s \"%s\" (%lld pt)%s]", sColumnTypeStrings[currColumn.mType], currColumn.mName.c_str(), currColumn.mWidth, currColumn.mEditable? " editable" : "" );
//	}
//	printf( "\n" );
}