//
//  CBackground.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CBackground__
#define __Stacksmith__CBackground__

#include "CLayer.h"

namespace Carlson {

class CBackground : public CLayer
{
public:
	CBackground( std::string inURL, ObjectID inID, const std::string inName, const std::string& inFileName, CStack* inStack ) : CLayer(inURL,inID,inName,inFileName,inStack)	{};
	~CBackground()	{ printf("Released Background %p\n",this); };

	virtual void	WakeUp();		// The current card has started its timers etc.
	virtual void	GoToSleep();	// The current card has stopped its timers etc.
	virtual bool	GoThereInNewWindow( bool inNewWindow, CStack* oldStack );
	
	virtual CScriptableObject*	GetParentObject();
	
protected:
	virtual const char*	GetLayerXMLType()			{ return "background"; };
	virtual const char*	GetIdentityForDump()		{ return "Background"; };
};

typedef CRefCountedObjectRef<CBackground>	CBackgroundRef;

}

#endif /* defined(__Stacksmith__CBackground__) */
