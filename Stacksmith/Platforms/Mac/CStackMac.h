//
//  CStackMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CStackMac__
#define __Stacksmith__CStackMac__

#include "CStack.h"


#if __OBJC__
@class WILDStackWindowController;
typedef WILDStackWindowController*			WILDStackWindowControllerPtr;
#else
typedef struct WILDStackWindowController*	WILDStackWindowControllerPtr;
#endif


namespace Carlson {

class CStackMac : public CStack
{
public:
	CStackMac( const std::string& inURL, WILDObjectID inID, const std::string& inName, CDocument * inDocument );

	virtual bool				GoThereInNewWindow( bool inNewWindow );

	virtual void				SetCurrentCard( CCard* inCard );
	
	static void					RegisterPartCreators();

protected:
	WILDStackWindowControllerPtr	mMacWindowController;
};

}

#endif /* defined(__Stacksmith__CStackMac__) */
