//
//  CMessageWatcher.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMessageWatcher__
#define __Stacksmith__CMessageWatcher__

#include "CScriptableObjectValue.h"
#include "LEOHandlerID.h"


namespace Carlson {


struct CMessageWatcherEntry
{
	std::string		mMessage;
	size_t			mNumOccurrences;
};


class CMessageWatcher : public CScriptableObject
{
public:
	static void			SetSharedInstance( CMessageWatcher* inMsg );	// Call once at startup
	static CMessageWatcher*	GetSharedInstance();
	
	CMessageWatcher() {};
	
	virtual void		AddMessage( const std::string& inMessage );
	size_t				GetNumMessages()							{ return mMessages.size(); };
	std::string			GetMessageAtIndex( size_t inIndex );
	
protected:
	std::vector<CMessageWatcherEntry>	mMessages;
};


}

#endif /* defined(__Stacksmith__CMessageWatcher__) */
