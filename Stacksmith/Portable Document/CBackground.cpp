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


