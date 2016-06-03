//
//  CPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CPart.h"
#include "CTinyXMLUtils.h"
#include "CLayer.h"
#include "CStack.h"
#include "CCursor.h"
#include "CDocument.h"
#include "CUndoStack.h"
#include "CAlert.h"
#include <iostream>
#include <sstream>
#include "math.h"


using namespace Carlson;


static std::map<std::string,CPartCreatorBase*>	sPartCreators;


/*static*/ CPart*	CPart::NewPartWithElement( tinyxml2::XMLElement * inElement, CLayer *inOwner )
{
	std::string		partType;
	CTinyXMLUtils::GetStringNamed( inElement, "type", partType );
	CPart	*		thePart = NULL;

	auto	foundItem = sPartCreators.find( partType );
	if( foundItem != sPartCreators.end() )
	{
		thePart = foundItem->second->NewPartInOwner( inOwner );
	}
	else
	{
		CPartCreator<CPart>* pc = new CPartCreator<CPart>(partType);
		RegisterPartCreator( pc );
		thePart = pc->NewPartInOwner( inOwner );
		fprintf( stderr, "error: Unknown part type \"%s\", falling back on plain part. This error message will only be printed once.\n", partType.c_str() );
    	tinyxml2::XMLPrinter printer;
    	inElement->Accept( &printer );
		fprintf( stderr, "note: XML is <<%s>>\n", printer.CStr() );
	}
	thePart->LoadFromElement( inElement );
	return thePart;
}


/*static*/ void		CPart::RegisterPartCreator( CPartCreatorBase* inCreator )
{
	sPartCreators[inCreator->GetPartTypeName()] = inCreator;
}


CPartCreatorBase*	CPart::GetPartCreatorForType( const char* inType )
{
	if( !inType )
		return NULL;
	auto	foundPartCreator = sPartCreators.find(inType);
	if( foundPartCreator == sPartCreators.end() )
		return NULL;
	return (*foundPartCreator).second;
}


CPart::CPart( CLayer *inOwner )
	: mOwner(inOwner), mFamily(0), mID(0), mLeft(10), mTop(10), mRight(110), mBottom(60), mPartType(NULL), mSelected(false), mPartLayoutFlags(0), mSelectedHandle(EAllHandlesSelected)
{
	//printf("part %s created.\n", DebugNameForPointer(this) );
	mDocument = inOwner->GetDocument();
}


CPart::~CPart()
{
	//printf("part %s deleted.\n", DebugNameForPointer(this) );
}


CPart*	CPart::Retain()
{
	//printf("retaining part %s.\n", DebugNameForPointer(this) );
	return (CPart*) CConcreteObject::Retain();
}


void	CPart::Release()
{
	//printf("releasing part %s.\n", DebugNameForPointer(this) );
	CConcreteObject::Release();
}


void	CPart::LoadFromElement( tinyxml2::XMLElement * inElement )
{
	LoadPropertiesFromElement( inElement );

	mName.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "name", mName );
	mScript.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "script", mScript );

	LoadUserPropertiesFromElement( inElement );
}


void	CPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	mID = CTinyXMLUtils::GetLongLongNamed( inElement, "id" );
	
	// No need to load the type here, whoever created us already looked at it when deciding to create *us* and not another subclass.
	
	tinyxml2::XMLElement *	layoutFlagsElem = inElement->FirstChildElement( "pinning" );
	if( layoutFlagsElem )
	{
		mPartLayoutFlags = 0;
		if( layoutFlagsElem->FirstChildElement( "centerHorizontally" ) )
			mPartLayoutFlags |= EPartLayoutAlignHCenter;
		if( layoutFlagsElem->FirstChildElement( "centerVertically" ) )
			mPartLayoutFlags |= EPartLayoutAlignVCenter;
		if( layoutFlagsElem->FirstChildElement( "stretchHorizontally" ) )
			mPartLayoutFlags |= EPartLayoutAlignHBoth;
		if( layoutFlagsElem->FirstChildElement( "stretchVertically" ) )
			mPartLayoutFlags |= EPartLayoutAlignVBoth;
		if( layoutFlagsElem->FirstChildElement( "right" ) )
			mPartLayoutFlags |= EPartLayoutAlignRight;
		if( layoutFlagsElem->FirstChildElement( "bottom" ) )
			mPartLayoutFlags |= EPartLayoutAlignBottom;
	}
	
	tinyxml2::XMLElement * rectElement = inElement->FirstChildElement( "rect" );
	mLeft = CTinyXMLUtils::GetLongLongNamed( rectElement, "left", 10LL );
	mTop = CTinyXMLUtils::GetLongLongNamed( rectElement, "top", 10LL );
	mRight = CTinyXMLUtils::GetLongLongNamed( rectElement, "right", mLeft + 100LL );
	mBottom = CTinyXMLUtils::GetLongLongNamed( rectElement, "bottom", mTop + 100LL );
}


void	CPart::SavePropertiesToElement( tinyxml2::XMLElement * inElement )
{
	CTinyXMLUtils::AddLongLongNamed( inElement, mID, "id" );
	
	tinyxml2::XMLDocument	*	document = inElement->GetDocument();
	tinyxml2::XMLElement	*	elem = document->NewElement("type");
	elem->SetText( GetPartType()->GetPartTypeName().c_str() );
	inElement->InsertEndChild(elem);

	tinyxml2::XMLElement	*	subElem = NULL;
	if( mPartLayoutFlags != 0 )	// No need to add layout flags element if it's the default, top/left:
	{
		elem = document->NewElement("pinning");
		if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignHCenter )
		{
			subElem = document->NewElement("centerHorizontally");
			elem->InsertEndChild(subElem);
		}
		if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignHBoth )
		{
			subElem = document->NewElement("stretchHorizontally");
			elem->InsertEndChild(subElem);
		}
		else if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignRight )
		{
			subElem = document->NewElement("right");
			elem->InsertEndChild(subElem);
		}
		if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignVCenter )
		{
			subElem = document->NewElement("centerVertically");
			elem->InsertEndChild(subElem);
		}
		if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignVBoth )
		{
			subElem = document->NewElement("stretchVertically");
			elem->InsertEndChild(subElem);
		}
		else if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignBottom )
		{
			subElem = document->NewElement("bottom");
			elem->InsertEndChild(subElem);
		}
		inElement->InsertEndChild(elem);
	}

	CTinyXMLUtils::AddRectNamed( inElement, mLeft, mTop, mRight, mBottom, "rect" );
}


void	CPart::SaveToElement( tinyxml2::XMLElement * inElement )
{
	SavePropertiesToElement( inElement );
	
	tinyxml2::XMLDocument*	document = inElement->GetDocument();
	tinyxml2::XMLElement* elem = document->NewElement("name");
	elem->SetText( mName.c_str() );
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("script");
	elem->SetText( mScript.c_str() );
	inElement->InsertEndChild(elem);
	
	SaveUserPropertiesToElementOfDocument( inElement, document );
}


void	CPart::SetRect( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b )
{
	LEONumber	w = r -l, h = b -t;
	
	if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignLeft )
	{
		mLeft = l;
		mRight = r;
	}
	else if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignRight )
	{
		mRight = GetStack()->GetCardWidth() -r;
		mLeft = mRight + w;
	}
	else if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignHBoth )
	{
		mRight = GetStack()->GetCardWidth() -r;
		mLeft = l;
	}
	else if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignHCenter )
	{
		mLeft = (GetStack()->GetCardWidth() -w) /2;
		mRight = mLeft +w;
	}
	
	if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignTop )
	{
		mTop = t;
		mBottom = b;
	}
	else if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignBottom )
	{
		mBottom = GetStack()->GetCardHeight() -b;
		mTop = mBottom + h;
	}
	else if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignVBoth )
	{
		mBottom = GetStack()->GetCardHeight() -b;
		mTop = t;
	}
	else if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignVCenter )
	{
		mTop = (GetStack()->GetCardHeight() -h) /2;
		mBottom = mTop +h;
	}
}


LEOInteger	CPart::GetLeft()
{
	if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignRight )
		return GetStack()->GetCardWidth() -mLeft;
	else if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignHCenter )
		return (GetStack()->GetCardWidth() -(mRight -mLeft)) / 2;
	
	return mLeft;
}


LEOInteger	CPart::GetTop()
{
	if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignBottom )
		return GetStack()->GetCardHeight() -mTop;
	else if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignVCenter )
		return (GetStack()->GetCardHeight() -(mBottom -mTop)) /2;
	
	return mTop;
}


LEOInteger	CPart::GetRight()
{
	if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignRight || PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignHBoth )
		return GetStack()->GetCardWidth() -mRight;
	else if( PART_H_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignHCenter )
		return (GetStack()->GetCardWidth() +(mRight -mLeft)) / 2;
	
	return mRight;
}


LEOInteger	CPart::GetBottom()
{
	if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignBottom || PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignVBoth )
		return GetStack()->GetCardHeight() -mBottom;
	else if( PART_V_LAYOUT_MODE(mPartLayoutFlags) == EPartLayoutAlignVCenter )
		return (GetStack()->GetCardHeight() +(mBottom -mTop)) / 2;
	
	return mBottom;
}


void	CPart::SetPartLayoutFlags( TPartLayoutFlags inFlags )
{
	IncrementChangeCount();
	
	// Save rect so we can change current rect to whatever relative format the new flags demand:
	LEONumber	l = GetLeft(), t = GetTop(), r = GetRight(), b = GetBottom();
	
	// Actually change the flags:
	mPartLayoutFlags = inFlags;
	
	SetRect( l, t, r, b );	// Re-set the rect so it's in whatever relative format the new flags demand.
}


CScriptableObject*	CPart::GetParentObject()
{
	return mOwner;
}


CStack*		CPart::GetStack()
{
	return mOwner->GetStack();
}


void	CPart::DumpProperties( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%slayoutFlags = %u\n", indentStr, mPartLayoutFlags );
	printf( "%srect = %lld,%lld,%lld,%lld\n", indentStr, mLeft, mTop, mRight, mBottom );
}


void	CPart::Dump( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%s%s ID %lld \"%s\"\n%s{\n", indentStr, GetIdentityForDump(), mID, mName.c_str(), indentStr );
	DumpProperties( inIndent +1 );
	DumpUserProperties( inIndent +1 );
	CPartContents*	theContents = GetContentsOnCurrentCard();
	std::string		contents = theContents? theContents->GetText() : std::string();
	printf( "%s\tcontents = <<%s>>\n", indentStr, contents.c_str() );
	printf( "%s\tscript = <<%s>>\n", indentStr, mScript.c_str() );
	printf( "%s}\n", indentStr );
}


void	CPart::IncrementChangeCount()
{
	mOwner->IncrementChangeCount();
}


CUndoStack*		CPart::GetUndoStack()
{
	return GetStack()->GetUndoStack();
}


CPartContents*	CPart::GetContentsOnCurrentCard()
{
	CPartContents*	contents = NULL;
	CStack		*	currStack = GetStack();
	if( !currStack )
		return NULL;
	CCard		*	currCard = currStack->GetCurrentCard();
	if( !currCard )
		return NULL;
	bool	isBgPart = dynamic_cast<CBackground*>(mOwner) != NULL;
	bool 	bgPartWithNonSharedText = (isBgPart && !GetSharedText());
	if( isBgPart && !GetSharedText() )	// We're on the background layer, not on the card, and don't have shared text?
	{
		contents = currCard->GetPartContentsByID( GetID(), isBgPart );
	}
	else
	{
		contents = mOwner->GetPartContentsByID( GetID(), isBgPart );
	}
	
	if( !contents )
	{
		contents = new CPartContents( currCard );
		contents->SetID( mID );
		contents->SetIsOnBackground( isBgPart );
		if( bgPartWithNonSharedText )
			currCard->AddPartContents( contents );
		else
			mOwner->AddPartContents( contents );
	}

	return contents;
}


bool	CPart::GetTextContents( std::string& outString )
{
	CPartContents*	contents = GetContentsOnCurrentCard();
	if( contents )
		outString = contents->GetText();
	return true;
}


bool	CPart::SetTextContents( const std::string& inString )
{
	CPartContents*	contents = GetContentsOnCurrentCard();
	if( contents )
		contents->SetText( inString );
	else
	{
		CCard	*	currCard = GetStack()->GetCurrentCard();
		bool		isBgPart = dynamic_cast<CBackground*>(mOwner) != NULL;
		bool 		bgPartWithNonSharedText = (isBgPart && !GetSharedText());
		contents = new CPartContents( bgPartWithNonSharedText ? currCard : mOwner );
		contents->SetID( mID );
		contents->SetText( inString );
		contents->SetIsOnBackground( isBgPart );
		if( bgPartWithNonSharedText )	// We're on the background layer, not on the card? But we don't have shared text? Add the contents to the current *card*!
		{
			currCard->AddPartContents( contents );
		}
		else	// Otherwise, we're on the card, or on the background with shared text, add the contents to that.
		{
			mOwner->AddPartContents( contents );
		}
	}
	return true;
}



bool	CPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, mName.c_str(), mName.size(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("id", inPropertyName) == 0 )
	{
		LEOInitIntegerValue( outValue, GetID(), kLEOUnitNone, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("number", inPropertyName) == 0 )
	{
		LEOInitIntegerValue( outValue, GetIndex(GetPartType()) +1, kLEOUnitNone, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("partNumber", inPropertyName) == 0 )
	{
		LEOInitIntegerValue( outValue, GetIndex() +1, kLEOUnitNone, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("rectangle", inPropertyName) == 0 || strcasecmp("rect", inPropertyName) == 0 )
	{
		LEOInitRectValue( outValue, GetLeft(), GetTop(), GetRight(), GetBottom(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("selected", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mSelected, kLEOInvalidateReferences, inContext );
	}
	else
		return CConcreteObject::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CPart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		char		nameBuf[1024];
		const char*	nameStr = LEOGetValueAsString( inValue, nameBuf, sizeof(nameBuf), inContext );
		SetName( nameStr );
	}
	else if( strcasecmp(inPropertyName, "id") == 0 )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "The ID of an object can't be changed." );
	}
	else if( strcasecmp("number", inPropertyName) == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEOInteger	theNum = LEOGetValueAsInteger( inValue, &theUnit, inContext );
		SetIndex( theNum -1, GetPartType() );
	}
	else if( strcasecmp("partNumber", inPropertyName) == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEOInteger	theNum = LEOGetValueAsInteger( inValue, &theUnit, inContext );
		SetIndex( theNum -1 );
	}
	else if( strcasecmp("rectangle", inPropertyName) == 0 || strcasecmp("rect", inPropertyName) == 0 )
	{
		LEOInteger		l = 0, t = 0, r = 0, b = 0;
		LEOGetValueAsRect( inValue, &l, &t, &r, &b, inContext);
		SetRect( l, t, r, b );
	}
	else if( strcasecmp("selected", inPropertyName) == 0 )
	{
		SetSelected( LEOGetValueAsBoolean( inValue, inContext) );
	}
	else
		return CConcreteObject::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


LEOInteger	CPart::GetIndex( CPartCreatorBase* inType )
{
	return mOwner->GetIndexOfPart( this, inType );
}


void		CPart::SetIndex( LEOInteger inIndex, CPartCreatorBase* inType )
{
	mOwner->SetIndexOfPart( this, inIndex, inType );
}


THitPart	CPart::HitTestForEditing( LEONumber x, LEONumber y, THitTestHandlesFlag handlesToo, LEOInteger *outCustomHandleIndex )
{
	THitPart	hitPart = ENothingHitPart;
	
	if( handlesToo == EHitTestHandlesToo )
	{
		LEOInteger	numCustomHandles = GetNumCustomHandlesForTool( GetStack()->GetTool() );
		if( numCustomHandles >= 0 )
		{
			for( LEOInteger n = 0; n < numCustomHandles; n++ )
			{
				LEONumber	l, t, r, b;
				GetRectForCustomHandle( n, &l, &t, &r, &b );
				if( x > l && x < r && y > t && y < b )
				{
					*outCustomHandleIndex = n;
					hitPart = ECustomGrabberHitPart;
					break;
				}
			}
		}
		else
		{
			THitPart	parts[] = { ELeftGrabberHitPart, ELeftGrabberHitPart | ETopGrabberHitPart,
									ETopGrabberHitPart, ERightGrabberHitPart | ETopGrabberHitPart,
									ERightGrabberHitPart, ERightGrabberHitPart | EBottomGrabberHitPart,
									EBottomGrabberHitPart, ELeftGrabberHitPart | EBottomGrabberHitPart,
									0 };
			for( int n = 0; parts[n] != 0; n++ )
			{
				LEONumber	l, t, r, b;
				if( GetRectForHandle( parts[n], &l, &t, &r, &b ) )
				{
					if( x > l && x < r && y > t && y < b )
					{
						hitPart = parts[n];
						*outCustomHandleIndex = -1;
						break;
					}
				}
			}
		}
	}
	
	if( hitPart == ENothingHitPart && x > GetLeft() && x < GetRight() && y > GetTop() && y < GetBottom() )
	{
		hitPart = EContentHitPart;
		*outCustomHandleIndex = -1;
	}
	
	return hitPart;
}


LEONumber	CPart::GetHandleSize( bool *outAllowSideHandles, bool *outAllowCornerHandles )
{
	LEONumber	heightForFullHandles = (GetBottom() -GetTop()) / 3;
	LEONumber	heightForReducedHandles = (GetBottom() -GetTop()) / 2;
	LEONumber	minHeightForHandles = 8;
	LEONumber	maxHeightForHandles = 12;
	LEONumber	handleHeight = minHeightForHandles;
	*outAllowSideHandles = false;
	*outAllowCornerHandles = false;
	
	if( heightForFullHandles >= minHeightForHandles )
	{
		handleHeight = heightForFullHandles;
		*outAllowSideHandles = true;
		*outAllowCornerHandles = true;
	}
	else if( heightForReducedHandles >= minHeightForHandles )
	{
		handleHeight = heightForReducedHandles;
		*outAllowCornerHandles = true;
	}
	
	if( handleHeight > maxHeightForHandles )
		handleHeight = maxHeightForHandles;
	
	return handleHeight;
}


bool	CPart::GetRectForHandle( THitPart inDesiredPart, LEONumber *outLeft, LEONumber *outTop, LEONumber *outRight, LEONumber *outBottom )
{
	bool		allowSideHandles = false;
	bool		allowCornerHandles = false;
	LEONumber	handleHeight = GetHandleSize( &allowSideHandles, &allowCornerHandles );
	
	if( inDesiredPart & ELeftGrabberHitPart )
	{
		*outLeft = GetLeft() -truncf(handleHeight /2);
		*outRight = *outLeft +handleHeight;
	}
	else if( inDesiredPart & ERightGrabberHitPart )
	{
		*outLeft = GetRight() -truncf(handleHeight /2);
		*outRight = *outLeft +handleHeight;
	}
	else
	{
		if( !allowSideHandles )
			return false;
		*outLeft = GetLeft() +truncf((GetRight() -GetLeft()) /2) -truncf(handleHeight /2);
		*outRight = *outLeft +handleHeight;
	}
	
	if( inDesiredPart & ETopGrabberHitPart )
	{
		*outTop = GetTop() -truncf(handleHeight /2);
		*outBottom = *outTop +handleHeight;
	}
	else if( inDesiredPart & EBottomGrabberHitPart )
	{
		*outTop = GetBottom() -truncf(handleHeight /2);
		*outBottom = *outTop +handleHeight;
	}
	else
	{
		if( !allowSideHandles )
			return false;
		*outTop = GetTop() +truncf((GetBottom() -GetTop()) /2) -truncf(handleHeight /2);
		*outBottom = *outTop +handleHeight;
	}
	
	if( !allowSideHandles && !allowCornerHandles && ((inDesiredPart & EBottomGrabberHitPart) == 0 || (inDesiredPart & ERightGrabberHitPart) == 0) )
		return false;	// Minimal is only lower right handle.
	
	return true;
}


void	CPart::GetRectForCustomHandle( LEOInteger idx, LEONumber *outLeft, LEONumber *outTop, LEONumber *outRight, LEONumber *outBottom )
{
	bool		outAllowSideHandles, outAllowCornerHandles;
	LEONumber	handleSize = GetHandleSize( &outAllowSideHandles, &outAllowCornerHandles );
	LEONumber	x = 0, y = 0;
	GetPositionOfCustomHandleAtIndex( idx, &x, &y );
	*outLeft = x -truncf(handleSize /2);
	*outRight = (*outLeft) + handleSize;
	*outTop = y -truncf(handleSize /2);
	*outBottom = (*outTop) + handleSize;
}


void	CPart::Grab( THitPart inHitPart, LEOInteger customGrabPartIndex, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock )
{
	LEONumber	oldL = GetLeft(), oldT = GetTop(), oldB = GetBottom(), oldR = GetRight();
	LEONumber	oldX = 0, oldY = 0;
	LEONumber	originalGHX = 0, originalGHY = 0;
	if( inHitPart & ECustomGrabberHitPart )
		GetPositionOfCustomHandleAtIndex( customGrabPartIndex, &originalGHX, &originalGHY );
	CCursor::GetGlobalPosition( &oldX, &oldY );
	CCursor::Grab( 0, [oldL,oldT,oldB,oldR,oldX,oldY,inHitPart,addGuidelineBlock,originalGHX,originalGHY,customGrabPartIndex,this]( LEONumber x, LEONumber y, LEONumber pressure )
	{
		if( inHitPart & ECustomGrabberHitPart )
		{
			SetPositionOfCustomHandleAtIndex( customGrabPartIndex, originalGHX +(x -oldX), originalGHY +(y -oldY) );
		}
		else
		{
			long long	l = (inHitPart & ELeftGrabberHitPart) ? (oldL +(x -oldX)) : oldL,
						t = (inHitPart & ETopGrabberHitPart) ? (oldT +(y -oldY)) : oldT,
						r = (inHitPart & ERightGrabberHitPart) ? (oldR +(x -oldX)) : oldR,
						b = (inHitPart & EBottomGrabberHitPart) ? (oldB +(y -oldY)) : oldB;
			if( l > r )
				std::swap(l,r);
			if( t > b )
				std::swap(t,b);

			GetOwner()->CorrectRectOfPart( this, inHitPart, &l, &t, &r, &b, addGuidelineBlock );
			SetRect( l, t, r, b );
		}
		IncrementChangeCount();
		
		return true;
	});
	
	ObjectID	myID = GetID();
	CLayer*		owner = GetOwner();
	GetUndoStack()->AddUndoAction( "Move/Resize", [owner,myID,oldL,oldT,oldR,oldB]()
								  {
									  owner->GetPartWithID(myID)->SetRectFromUndo( oldL, oldT, oldR, oldB );
								  } );
	
	addGuidelineBlock( LLONG_MAX, EGuidelineCallbackActionClearAllDone );
//	std::cout << "Done tracking." << std::endl;
}


void	CPart::SetRectFromUndo( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b )
{
	LEONumber	oldL = GetLeft(), oldT = GetTop(), oldB = GetBottom(), oldR = GetRight();
	SetRect( l, t, r, b );
	ObjectID	myID = GetID();
	CLayer*		owner = GetOwner();
	GetUndoStack()->AddUndoAction( "Move/Resize", [owner,myID,oldL,oldT,oldR,oldB]()
								  {
									   owner->GetPartWithID(myID)->SetRectFromUndo( oldL, oldT, oldR, oldB );
								  } );
}


std::string		CPart::GenerateDisplayName( const char* inTypeName )
{
	std::stringstream		strs;
	strs << (dynamic_cast<CCard*>(GetOwner()) ? "Card " : "Background ");
	if( mName.length() > 0 )
		strs << inTypeName << " \"" << mName << "\"";
	else
		strs << inTypeName << " ID " << GetID();
	return strs.str();
}


void	CPart::SetSelected( bool inSelected, LEOInteger inHandleIndex )
{
	if( inSelected != mSelected || mSelectedHandle != inHandleIndex )
	{
		mSelected = inSelected;
		mSelectedHandle = inHandleIndex;
		GetStack()->SelectedPartChanged();
		
		SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "selectionChangeWhileEditing" );
	}
}


bool	CPart::GetShouldSendMouseEventsRightNow()
{
	return GetStack()->GetTool() == EBrowseTool && !GetStack()->GetDocument()->GetPeeking();
}


bool	CPart::DeleteObject()
{
	return GetOwner()->DeletePart( this, false );	// +++ Doesn't record undo. Should we let scripts override this?
}

