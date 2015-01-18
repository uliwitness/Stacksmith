//
//  CBackground.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CBackground.h"
#include "CStack.h"
#include <sstream>


using namespace Carlson;


CBackground::~CBackground()
{
	for( auto currCard : mMemberCards )
	{
		currCard->SetBackground( NULL );
	}
}


void	CBackground::WakeUp()
{
	CLayer::WakeUp();
	
	mStack->WakeUp();
}


void	CBackground::GoToSleep()
{
	CLayer::GoToSleep();
	
	mStack->GoToSleep();
}


CScriptableObject*	CBackground::GetParentObject()
{
	return mStack;
}


bool	CBackground::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp(inPropertyName, "number") == 0 )
	{
		LEOInitIntegerValue( outValue, GetStack()->GetIndexOfBackground(this) +1, kLEOUnitNone, kLEOInvalidateReferences, inContext );
		return true;
	}
	else
		return CLayer::GetPropertyNamed(inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
}


bool	CBackground::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp(inPropertyName, "number") == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEOInteger	number = LEOGetValueAsInteger( inValue, &theUnit, inContext );
		if( number <= 0 || number > (LEOInteger)GetStack()->GetNumBackgrounds() )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Background number must be between 1 and %zu.", GetStack()->GetNumBackgrounds() );
		}
		else
		{
			GetStack()->SetIndexOfBackgroundTo( this, number -1 );
		}
		return true;
	}
	else
		return CLayer::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
}


void	CBackground::AddCard( CCard* inCard )
{
	mMemberCards.insert(inCard);
}


void	CBackground::RemoveCard( CCard* inCard )
{
	mMemberCards.erase(inCard);
}


size_t	CBackground::GetNumCards()
{
	return mMemberCards.size();
}


bool	CBackground::GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler )
{
	CCard*	searchStart = GetStack()->GetCurrentCard();
	if( searchStart && searchStart->GetBackground() == this )
		return searchStart->GoThereInNewWindow( inOpenInMode, oldStack, overPart, completionHandler );
	else
		return GetStack()->GetCardWithBackground( this, searchStart )->GoThereInNewWindow( inOpenInMode, oldStack, overPart, completionHandler );
	return false;
}


void	CBackground::LoadPastedPartBackgroundContents( CPart* newPart, tinyxml2::XMLElement* currBgContents, bool haveCardContents, CStyleSheet * inStyleSheet )
{
	CPartContents*	pc = new CPartContents( this, currBgContents, inStyleSheet );
	mContents.push_back( pc );
	pc->Release();
}


void	CBackground::LoadPastedPartCardContents( CPart* newPart, tinyxml2::XMLElement* currCardContents, bool haveBgContents, CStyleSheet * inStyleSheet )
{
	if( haveBgContents )
	{
		CPartContents*	pc = new CPartContents( this, currCardContents, inStyleSheet );
		pc->SetID( newPart->GetID() );
		mStack->GetCurrentCard()->AddPartContents( pc );
		pc->Release();
	}
	else
	{
		if( !newPart->GetSharedText() )
			newPart->SetSharedText( true );
		CPartContents*	pc = new CPartContents( this, currCardContents, inStyleSheet );
		pc->SetID( newPart->GetID() );
		pc->SetIsOnBackground( true );
		mContents.push_back( pc );
		pc->Release();
	}
}


std::string		CBackground::GetDisplayName()
{
	std::stringstream		strs;
	if( mName.length() > 0 )
		strs << "Background \"" << mName << "\"";
	else
		strs << "Background ID " << GetID();
	return strs.str();
}


void	CBackground::CorrectRectOfPart( CPart* inMovedPart, THitPart partsToCorrect, long long *ioLeft, long long *ioTop, long long *ioRight, long long *ioBottom, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock )
{
	std::vector<CPartRef>	parts( mParts );
	if( !GetStack()->GetEditingBackground() )
		GetStack()->GetCurrentCard()->AddPartsToList( parts );
	CPlatformLayer::CorrectRectOfPart( inMovedPart, parts, partsToCorrect, ioLeft, ioTop, ioRight, ioBottom, addGuidelineBlock );
}




