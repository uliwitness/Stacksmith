//
//  CBackground.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CBackground.h"
#include "CStack.h"


using namespace Carlson;


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


bool	CBackground::GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart )
{
	CCard*	searchStart = GetStack()->GetCurrentCard();
	if( searchStart && searchStart->GetBackground() == this )
		return searchStart->GoThereInNewWindow( inOpenInMode, oldStack, overPart );
	else
		return GetStack()->GetCardWithBackground( this, searchStart )->GoThereInNewWindow( inOpenInMode, oldStack, overPart );
	return false;
}


