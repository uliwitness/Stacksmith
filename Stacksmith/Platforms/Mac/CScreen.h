//
//  CScreen.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2017-06-19.
//  Copyright (c) 2017 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CScreen__
#define __Stacksmith__CScreen__

#include <cstddef>
#include "CCanvas.h"


#if __OBJC__
@class NSScreen;
typedef NSScreen * WILDNSScreenPtr;
#else
typedef struct NSScreen * WILDNSScreenPtr;
#endif


namespace Carlson {

class CScreen
{
public:
	static size_t		GetNumScreens();
	static CScreen		GetScreen( size_t inIndex );

	CScreen( const CScreen& inOriginal );
	~CScreen();

	CRect		GetRectangle() const;
	CRect		GetWorkingRectangle() const;
	TCoordinate	GetScale() const;
	
protected:
	explicit CScreen( WILDNSScreenPtr inScreen );
	
	WILDNSScreenPtr	mMacScreen;
};

}

#endif /* defined(__Stacksmith__CScreen__) */
