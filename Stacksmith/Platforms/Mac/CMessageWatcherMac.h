//
//  CMessageWatcherMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-17.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMessageWatcherMac__
#define __Stacksmith__CMessageWatcherMac__

#include "CMessageWatcher.h"


#if __OBJC__
@class WILDMessageWatcherWindowController;
typedef WILDMessageWatcherWindowController*			WILDMessageWatcherWindowControllerPtr;
#else
#include <objc/objc.h>
typedef struct WILDMessageWatcherWindowController*	WILDMessageWatcherWindowControllerPtr;
#endif


namespace Carlson
{


class CMessageWatcherMac : public CMessageWatcher
{
public:
	CMessageWatcherMac();

	virtual bool	SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	virtual bool	GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	
	virtual void	SetVisible( bool n );
	virtual bool	IsVisible()					{ return mVisible; };
	void			UpdateVisible( bool inVis )	{ mVisible = inVis; };

	virtual void	AddMessage( const std::string &inMessage );
	
protected:
	~CMessageWatcherMac();

	WILDMessageWatcherWindowControllerPtr	mMacWindowController;
	bool									mVisible;
};


}

#endif /* defined(__Stacksmith__CMessageWatcherMac__) */
