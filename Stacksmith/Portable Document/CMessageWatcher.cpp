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
#include <sstream>


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


void	CMessageWatcher::AddMessage( const std::string& inMessage )
{
	if( inMessage.compare(":run") == 0 )
		return;	// Ignore message box
	while( mMessages.size() >= 50 )
		mMessages.erase( mMessages.begin() );
	
	size_t	msgCount = mMessages.size();
	if( msgCount > 0 && mMessages[msgCount-1].mMessage.compare(inMessage) == 0 )
		mMessages[msgCount-1].mNumOccurrences++;
	else
	{
		CMessageWatcherEntry	entry = { inMessage, 1 };
		mMessages.push_back( entry );
	}
}


std::string		CMessageWatcher::GetMessageAtIndex( size_t inIndex )
{
	CMessageWatcherEntry&	entry = mMessages[inIndex];
	size_t	occurrences = entry.mNumOccurrences;
	if( occurrences == 1 )
		return entry.mMessage;
	else
	{
		std::stringstream	msg;
		msg << entry.mMessage;
		msg << " ×";
		msg << entry.mNumOccurrences;
		return msg.str();
	}
}

