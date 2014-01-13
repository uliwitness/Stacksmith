//
//  CFieldPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CFieldPartMac__
#define __Stacksmith__CFieldPartMac__


#include "CFieldPart.h"
#include "CMacPartBase.h"


namespace Carlson {


class CFieldPartMac : public CFieldPart, public CMacPartBase
{
public:
	CFieldPartMac( CLayer *inOwner ) : CFieldPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView()						{ [mView removeFromSuperview]; [mView release]; mView = nil; };
	virtual void	SetPeeking( bool inState )	{ ApplyPeekingStateToView(inState, mView); };
	
protected:
	~CFieldPartMac()	{ DestroyView(); };
	
	NSTextField	*	mView;
};


}

#endif /* defined(__Stacksmith__CFieldPartMac__) */
