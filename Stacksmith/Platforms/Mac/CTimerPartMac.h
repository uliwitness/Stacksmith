//
//  CTimerPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CTimerPartMac__
#define __Stacksmith__CTimerPartMac__

#include "CTimerPart.h"
#include "CMacPartBase.h"


namespace Carlson
{

class CTimerPartMac : public CTimerPart, public CMacPartBase
{
public:
	explicit CTimerPartMac( CLayer *inOwner ) : CTimerPart( inOwner ) {};
	
};

}

#endif /* defined(__Stacksmith__CTimerPartMac__) */
