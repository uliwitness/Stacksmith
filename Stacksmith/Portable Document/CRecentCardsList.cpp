//
//  CRecentCardsList.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CRecentCardsList.h"


using namespace Carlson;


static CRecentCardsList*	sRecentCardsList = NULL;


CRecentCardsList*	CRecentCardsList::GetSharedInstance()
{
	return sRecentCardsList;
}


template<class RecentCardInfoSubclass>
void	CRecentCardsList::Initialize()
{
	sRecentCardsList = new CRecentCardsListConcrete<RecentCardInfoSubclass>;
}



