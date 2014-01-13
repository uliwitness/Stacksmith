//
//  CMacPartBase.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

/*
	Mac-specific mix-in class for all our CParts. CStackMac creates
	subclasses of each part type mixed in with this class, which it
	then asks to create/destroy the Mac-specific UI.
*/

#ifndef __Stacksmith__CMacPartBase__
#define __Stacksmith__CMacPartBase__

#import <Cocoa/Cocoa.h>


namespace Carlson {


class CMacPartBase
{
public:
	CMacPartBase() {};
	
	virtual void	CreateViewIn( NSView* inSuperView ) = 0;
	virtual void	DestroyView() = 0;
	virtual void	ApplyPeekingStateToView( bool inState, NSView* inView )
	{
		//inView.layer.borderWidth = inState? 1 : 0;
		//inView.layer.borderColor = inState? [NSColor grayColor].CGColor : NULL;
	}

protected:
	virtual ~CMacPartBase() {};
};


}

#endif /* defined(__Stacksmith__CMacPartBase__) */
