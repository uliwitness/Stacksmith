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
#include <iostream>
#include <sstream>


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
		fprintf( stderr, "error: Unknown part type %s, falling back on plain part. This error message will only be printed once.\n", partType.c_str() );
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
	: mOwner(inOwner), mFamily(0), mID(0), mLeft(10), mTop(10), mRight(110), mBottom(60), mPartType(NULL), mSelected(false)
{
	mDocument = inOwner->GetDocument();
}


CPart::~CPart()
{
	//printf("Deleting one part.\n");
}


CPart*	CPart::Retain()
{
	return (CPart*) CConcreteObject::Retain();
}


void	CPart::Release()
{
	CConcreteObject::Release();
}


void	CPart::LoadFromElement( tinyxml2::XMLElement * inElement )
{
	LoadPropertiesFromElement( inElement );
	LoadUserPropertiesFromElement( inElement );
}


void	CPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	mID = CTinyXMLUtils::GetLongLongNamed( inElement, "id" );
	mName.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "name", mName );
	mScript.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "script", mScript );
	tinyxml2::XMLElement * rectElement = inElement->FirstChildElement( "rect" );
	mLeft = CTinyXMLUtils::GetLongLongNamed( rectElement, "left", 10LL );
	mTop = CTinyXMLUtils::GetLongLongNamed( rectElement, "top", 10LL );
	mRight = CTinyXMLUtils::GetLongLongNamed( rectElement, "right", mLeft + 100LL );
	mBottom = CTinyXMLUtils::GetLongLongNamed( rectElement, "bottom", mTop + 100LL );
}


void	CPart::SaveToElement( tinyxml2::XMLElement * inElement )
{
	CTinyXMLUtils::AddLongLongNamed( inElement, mID, "id" );
	
	tinyxml2::XMLDocument	*	document = inElement->GetDocument();
	tinyxml2::XMLElement	*	elem = document->NewElement("type");
	elem->SetText( GetPartType()->GetPartTypeName().c_str() );
	inElement->InsertEndChild(elem);

	CTinyXMLUtils::AddRectNamed( inElement, mLeft, mTop, mRight, mBottom, "rect" );
	
	SavePropertiesToElement( inElement );
	
	elem = document->NewElement("name");
	elem->SetText( mName.c_str() );
	inElement->InsertEndChild(elem);
	
	elem = document->NewElement("script");
	elem->SetText( mScript.c_str() );
	inElement->InsertEndChild(elem);
	
	SaveUserPropertiesToElementOfDocument( inElement, document );
}


void	CPart::SaveAssociatedResourcesToElement( tinyxml2::XMLElement * inElement )
{
	// If a part has associated resources, this is how we copy them when this part is copied.
	//	You'd likely call SaveMediaToElement() for whatever media you depend on, on your document's media cache.
}


void	CPart::UpdateMediaIDs( std::map<ObjectID,ObjectID> changedIDMappings )
{
	// When a part is pasted its associated media are pasted as well. If media uses an ID
	//	that already exists for a different item, it gets re-numbered. This function gets
	//	called in that case to let you fix up any IDs that may have changed. As the new
	//	number may collide with a later one, you get a list of all changed IDs at once,
	//	so subsequent ID changes don't cause your ID to be re-mapped again.
}


void	CPart::SavePropertiesToElement( tinyxml2::XMLElement * inElement )
{
	
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


CPartContents*	CPart::GetContentsOnCurrentCard()
{
	CCard	*	currCard = GetStack()->GetCurrentCard();
	if( !currCard )
		return NULL;
	if( mOwner != currCard && !GetSharedText() )	// We're on the background layer, not on the card?
		return currCard->GetPartContentsByID( GetID(), (mOwner != currCard) );
	else
		return mOwner->GetPartContentsByID( GetID(), (mOwner != currCard) );
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
		bool bgPartWithNonSharedText = (mOwner != currCard && !GetSharedText());
		contents = new CPartContents( bgPartWithNonSharedText ? currCard : mOwner );
		contents->SetID( mID );
		contents->SetText( inString );
		contents->SetIsOnBackground( (mOwner != currCard) );
		if( bgPartWithNonSharedText )	// We're on the background layer, not on the card? But we don't have shared text? Add the contents to the current *card*!
			currCard->AddPartContents( contents );
		else	// Otherwise, we're on the card, or on the background with shared text, add the contents to that.
			mOwner->AddPartContents( contents );
	}
	return true;
}



bool	CPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, mName.c_str(), mName.size(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("script", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, mScript.c_str(), mScript.size(), kLEOInvalidateReferences, inContext );
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
		LEOInitRectValue( outValue, mLeft, mTop, mRight, mBottom, kLEOInvalidateReferences, inContext );
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
		LEOContextStopWithError( inContext, SIZE_T_MAX, SIZE_T_MAX, 0, "The ID of an object can't be changed." );
	}
	else if( strcasecmp("script", inPropertyName) == 0 )
	{
		char		scriptBuf[1024];
		const char*	scriptStr = LEOGetValueAsString( inValue, scriptBuf, sizeof(scriptBuf), inContext );
		SetScript( scriptStr );
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


THitPart	CPart::HitTestForEditing( LEONumber x, LEONumber y )
{
	THitPart	hitPart = ENothingHitPart;
	if( x > mLeft && x < (mLeft + 8) )
		hitPart |= ELeftGrabberHitPart;
	else if( x < mRight && x > (mRight - 8) )
		hitPart |= ERightGrabberHitPart;
	if( y > mTop && y < (mTop + 8) )
		hitPart |= ETopGrabberHitPart;
	else if( y < mBottom && y > (mBottom - 8) )
		hitPart |= EBottomGrabberHitPart;
	
	if( hitPart == ENothingHitPart && x > mLeft && x < mRight && y > mTop && y < mBottom )
		hitPart = EContentHitPart;
	
	return hitPart;
}


void	CPart::Grab( THitPart inHitPart, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock )
{
	LEONumber	oldL = mLeft, oldT = mTop, oldB = mBottom, oldR = mRight;
	LEONumber	oldX = 0, oldY = 0;
	CCursor::GetGlobalPosition( &oldX, &oldY );
	CCursor::Grab( [oldL,oldT,oldB,oldR,oldX,oldY,inHitPart,addGuidelineBlock,this]()
	{
		LEONumber	x = 0, y = 0;
		CCursor::GetGlobalPosition( &x, &y );
		
		long long	l = (inHitPart & ELeftGrabberHitPart) ? (oldL +(x -oldX)) : oldL,
					t = (inHitPart & ETopGrabberHitPart) ? (oldT +(y -oldY)) : oldT,
					r = (inHitPart & ERightGrabberHitPart) ? (oldR +(x -oldX)) : oldR,
					b = (inHitPart & EBottomGrabberHitPart) ? (oldB +(y -oldY)) : oldB;
		
		GetOwner()->CorrectRectOfPart( this, inHitPart, &l, &t, &r, &b, addGuidelineBlock );
		SetRect( l, t, r, b );
	});
	addGuidelineBlock( LLONG_MAX, EGuidelineCallbackActionClearAllDone );
//	std::cout << "Done tracking." << std::endl;
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


bool	CPart::GetShouldSendMouseEventsRightNow()
{
	return GetStack()->GetTool() == EBrowseTool && !GetStack()->GetDocument()->GetPeeking();
}



