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


void	CRecentCardsList::SetSharedInstance( CRecentCardsList* inSI )
{
	sRecentCardsList = inSI;
}


CRecentCardsList*	CRecentCardsList::GetSharedInstance()
{
	return sRecentCardsList;
}



