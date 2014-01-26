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


class CMessageWatcher : public CScriptableObject
{
public:
	static void			SetSharedInstance( CMessageWatcher* inMsg );	// Call once at startup
	static CMessageWatcher*	GetSharedInstance();
	
	CMessageWatcher() {};
	
	virtual void		AddMessage( const std::string& inMessage )	{ while( mMessages.size() >= 50 ) mMessages.erase( mMessages.begin() ); mMessages.push_back( inMessage ); };
	size_t				GetNumMessages()							{ return mMessages.size(); };
	std::string			GetMessageAtIndex( size_t inIndex )			{ return mMessages[inIndex]; };
	
protected:
	std::vector<std::string>	mMessages;
};


}

#endif /* defined(__Stacksmith__CMessageWatcher__) */
