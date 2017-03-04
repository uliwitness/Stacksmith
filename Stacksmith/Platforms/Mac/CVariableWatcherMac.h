//
//  CVariableWatcherMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-17.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CVariableWatcherMac__
#define __Stacksmith__CVariableWatcherMac__

#include "CVariableWatcher.h"


#if __OBJC__
@class WILDVariableWatcherWindowController;
typedef WILDVariableWatcherWindowController*			WILDVariableWatcherWindowControllerPtr;
#else
typedef struct WILDVariableWatcherWindowController*	WILDVariableWatcherWindowControllerPtr;
#endif


namespace Carlson
{


class CVariableWatcherMac : public CVariableWatcher
{
public:
	CVariableWatcherMac();

	virtual bool	SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	virtual bool	GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	
	virtual void	SetVisible( bool n );
	virtual bool	IsVisible()					{ return mVisible; };
	void			UpdateVisible( bool inVis )	{ mVisible = inVis; };
	
protected:
	~CVariableWatcherMac();

	virtual void		UpdateVariables();

	WILDVariableWatcherWindowControllerPtr	mMacWindowController;
	bool									mVisible;
};


}

#endif /* defined(__Stacksmith__CVariableWatcherMac__) */
