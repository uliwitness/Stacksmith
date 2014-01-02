//
//  CTimerPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CTimerPart__
#define __Stacksmith__CTimerPart__

#include "CPart.h"
#include <string>
#include "CTimer.h"


namespace Calhoun {

class CTimerPart : public CPart
{
public:
	explicit CTimerPart( CLayer *inOwner ) : CPart( inOwner ) {};
	
	virtual void			SetStarted( bool inStarted )	{ mStarted = inStarted; if( inStarted ) mActualTimer.Start(); else mActualTimer.Stop(); };
	virtual bool			GetStarted()					{ return mStarted; };
	
	virtual void			SetInterval( long long inInterval )	{ mInterval = inInterval; mActualTimer.SetInterval( inInterval ); };
	virtual long long		GetInterval()						{ return mInterval; };
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	
	virtual const char*		GetIdentityForDump()	{ return "Timer"; };
	virtual void			DumpProperties( size_t inIndent );
	
	virtual void			Trigger();
	
protected:
	std::string		mMessage;
	long long		mInterval;
	bool			mStarted;
	bool			mRepeat;
	CTimer			mActualTimer;
};

}

#endif /* defined(__Stacksmith__CTimerPart__) */
