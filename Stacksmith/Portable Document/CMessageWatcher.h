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
	std::string		mTarget;
};


class CMessageWatcher : public CScriptableObject
{
public:
	static void			SetSharedInstance( CMessageWatcher* inMsg );	// Call once at startup
	static CMessageWatcher*	GetSharedInstance();
	
	CMessageWatcher() {};
	
	virtual void		AddMessage( const std::string & inMessage, const std::string & inTarget );
	size_t				GetNumMessages()							{ return mMessages.size(); };
	void				GetMessageAtIndex( size_t inIndex, std::string & outMessage, std::string & outTarget );
	// We don't provide InitValue here because the message watcher can be referenced from many context groups.
	
	virtual void		SetVisible( bool n )						{};
	virtual bool		IsVisible()									{ return false; };
	
protected:
	std::vector<CMessageWatcherEntry>	mMessages;
};


}

#endif /* defined(__Stacksmith__CMessageWatcher__) */
