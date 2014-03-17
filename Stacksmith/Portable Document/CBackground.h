//
//  CBackground.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CBackground__
#define __Stacksmith__CBackground__

#include "CPlatformLayer.h"
#include <set>

namespace Carlson {

class CCard;
class CStyleSheet;

class CBackground : public CPlatformLayer
{
public:
	CBackground( std::string inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CStack* inStack ) : CPlatformLayer(inURL,inID,inName,inFileName,inStack)	{};
	~CBackground();

	virtual void	WakeUp();		// The current card has started its timers etc.
	virtual void	GoToSleep();	// The current card has stopped its timers etc.
	virtual bool	GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler );

	virtual bool	GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool	SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	
	virtual void	AddCard( CCard* inCard )	{ mMemberCards.insert(inCard); };
	virtual void	RemoveCard( CCard* inCard )	{ mMemberCards.erase(inCard); };
	virtual size_t	GetNumCards()				{ return mMemberCards.size(); };
	
	virtual std::string			GetDisplayName();
	
	virtual CScriptableObject*	GetParentObject();
	
protected:
	virtual void	LoadPastedPartBackgroundContents( CPart* newPart, tinyxml2::XMLElement* currBgContents, bool haveCardContents, CStyleSheet * inStyleSheet );
	virtual void	LoadPastedPartCardContents( CPart* newPart, tinyxml2::XMLElement* currCardContents, bool haveBgContents, CStyleSheet * inStyleSheet );
	virtual const char*	GetLayerXMLType()			{ return "background"; };
	virtual const char*	GetIdentityForDump()		{ return "Background"; };
	
	std::set<CCard*>	mMemberCards;
};

typedef CRefCountedObjectRef<CBackground>	CBackgroundRef;

}

#endif /* defined(__Stacksmith__CBackground__) */
