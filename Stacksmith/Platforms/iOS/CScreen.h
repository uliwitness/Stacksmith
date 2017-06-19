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
@class UIScreen;
typedef UIScreen * WILDUIScreenPtr;
#else
typedef struct UIScreen * WILDUIScreenPtr;
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
	explicit CScreen( WILDUIScreenPtr inScreen );
	
	WILDUIScreenPtr	mIOSScreen;
};

}

#endif /* defined(__Stacksmith__CScreen__) */
