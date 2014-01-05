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


namespace Carlson {

class CBackground;


class CCard : public CLayer
{
public:
	CCard( std::string inURL, WILDObjectID inID, const std::string inName, CStack* inStack, bool inMarked ) : CLayer(inURL,inID,inName,inStack), mMarked(inMarked), mOwningBackground(NULL)	{};
	
	bool		IsMarked()					{ return mMarked; };
	void		SetMarked( bool inMarked )	{ mMarked = inMarked; };
	
protected:
	virtual void	LoadPropertiesFromElement( tinyxml2::XMLElement* root );
	virtual void	CallAllCompletionBlocks();

	virtual const char*	GetIdentityForDump()		{ return "Card"; };

protected:
	bool			mMarked;
	CBackground	*	mOwningBackground;
};

typedef CRefCountedObjectRef<CCard>	CCardRef;

}

#endif /* defined(__Stacksmith__CCard__) */
