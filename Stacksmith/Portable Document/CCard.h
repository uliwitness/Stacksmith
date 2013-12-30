//
//  CCard.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CCard__
#define __Stacksmith__CCard__

#include "CLayer.h"

class CCard : public CLayer
{
public:
	CCard( std::string inURL, bool inMarked ) : CLayer(inURL), mMarked(inMarked)	{};
	
	bool		IsMarked()					{ return mMarked; };
	void		SetMarked( bool inMarked )	{ mMarked = inMarked; };
	
protected:
	bool			mMarked;
};

typedef CRefCountedObjectRef<CCard>	CCarddRef;

#endif /* defined(__Stacksmith__CCard__) */
