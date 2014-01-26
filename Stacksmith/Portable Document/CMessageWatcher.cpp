//
//  CMessageWatcher.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMessageWatcher.h"
#include "Forge.h"
#include "CDocument.h"
#include "CAlert.h"


using namespace Carlson;


static CMessageWatcher*		sMessageWatcher = NULL;


void	CMessageWatcher::SetSharedInstance( CMessageWatcher* inMsg )
{
	sMessageWatcher = inMsg;
}


CMessageWatcher*	CMessageWatcher::GetSharedInstance()
{
	return sMessageWatcher;
}



