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


void	CMessageWatcher::AddMessage( const std::string & inMessage, const std::string & inTarget )
{
	if( inMessage.compare(":run") == 0 )
		return;	// Ignore message box
	while( mMessages.size() >= 50 )
		mMessages.erase( mMessages.begin() );
	
	size_t	msgCount = mMessages.size();
	if( msgCount > 0 && mMessages[msgCount-1].mMessage.compare(inMessage) == 0 && mMessages[msgCount-1].mTarget.compare(inTarget) == 0 )
		mMessages[msgCount-1].mNumOccurrences++;
	else
	{
		CMessageWatcherEntry	entry = { inMessage, 1, inTarget };
		mMessages.push_back( entry );
	}
}


void	CMessageWatcher::GetMessageAtIndex( size_t inIndex, std::string & outMessage, std::string & outTarget )
{
	CMessageWatcherEntry&	entry = mMessages[inIndex];
	size_t	occurrences = entry.mNumOccurrences;
	if( occurrences == 1 )
	{
		outMessage = entry.mMessage;
		outTarget = entry.mTarget;
	}
	else
	{
		std::stringstream	msg;
		msg << entry.mMessage;
		msg << " ×";
		msg << entry.mNumOccurrences;
		outMessage = msg.str();
		outTarget = entry.mTarget;
	}
}

