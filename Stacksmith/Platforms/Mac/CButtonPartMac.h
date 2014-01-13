//
//  CButtonPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CButtonPartMac__
#define __Stacksmith__CButtonPartMac__

#include "CButtonPart.h"
#include "CMacPartBase.h"


@class WILDButtonView;


namespace Carlson {


class CButtonPartMac : public CButtonPart, public CMacPartBase
{
public:
	CButtonPartMac( CLayer *inOwner ) : CButtonPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView();
	virtual void	SetName( const std::string& inStr );
	virtual void	SetPeeking( bool inState );
	
protected:
	~CButtonPartMac()	{ DestroyView(); };
	
	WILDButtonView	*	mView;
};


}

#endif /* defined(__Stacksmith__CButtonPartMac__) */
