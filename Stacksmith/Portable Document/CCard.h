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


typedef enum
{
    EVisualEffectSpeedVerySlow,
    EVisualEffectSpeedSlow,
    EVisualEffectSpeedNormal,
    EVisualEffectSpeedFast,
    EVisualEffectSpeedVeryFast
} TVisualEffectSpeed;


class CCard : public CLayer
{
public:
	CCard( std::string inURL, ObjectID inID, const std::string inName, const std::string& inFileName, CStack* inStack, bool inMarked ) : CLayer(inURL,inID,inName,inFileName,inStack), mMarked(inMarked), mOwningBackground(NULL)	{};
	
	bool			IsMarked()					{ return mMarked; };
	void			SetMarked( bool inMarked )	{ mMarked = inMarked; };
	
	virtual void	WakeUp();
	virtual void	GoToSleep();
	
	virtual void	SetTransitionTypeAndSpeed( const std::string& inType, TVisualEffectSpeed inSpeed ) {  mTransitionType = inType; mSpeed = inSpeed; };
	
	virtual void	SetPeeking( bool inState );
	
	virtual CScriptableObject*	GetParentObject();
	virtual CBackground*		GetBackground()		{ return mOwningBackground; };
	
	virtual bool				GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart );
	
protected:
	virtual void	LoadPropertiesFromElement( tinyxml2::XMLElement* root );
	virtual void	SavePropertiesToElementOfDocument( tinyxml2::XMLElement* stackfile, tinyxml2::XMLDocument* document );
	virtual void	CallAllCompletionBlocks();
	virtual const char*	GetLayerXMLType()			{ return "card"; };

	virtual const char*	GetIdentityForDump()		{ return "Card"; };

protected:
	bool			    mMarked;
	CBackground	*	    mOwningBackground;
	std::string		    mTransitionType;
    TVisualEffectSpeed	mSpeed;
};

typedef CRefCountedObjectRef<CCard>	CCardRef;

}

#endif /* defined(__Stacksmith__CCard__) */
