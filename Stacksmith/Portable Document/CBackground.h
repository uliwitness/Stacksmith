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
#include "CCard.h"
#include <set>

namespace Carlson {

class CStyleSheet;

class CBackground : public CPlatformLayer
{
public:
	CBackground( std::string inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CStack* inStack ) : CPlatformLayer(inURL,inID,inName,inFileName,inStack)	{ /* printf("bkgnd %s created.\n", DebugNameForPointer(this) ); */ };
	~CBackground();

	virtual void	WakeUp() override;		// The current card has started its timers etc.
	virtual void	GoToSleep() override;	// The current card has stopped its timers etc.
	virtual bool	GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler, const std::string& inEffectType, TVisualEffectSpeed inSpeed ) override;

	virtual bool	GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue ) override;
	virtual bool	SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd ) override;
	
	virtual void	AddCard( CCard* inCard );
	virtual void	RemoveCard( CCard* inCard );
	virtual size_t	GetNumCards();
	virtual CCard*	GetCard( size_t inIndex );
	
	virtual std::string			GetDisplayName() override;
	virtual std::string			GetTypeName() override			{ return std::string("background"); };
	
	virtual CScriptableObject*	GetParentObject( CScriptableObject* previousParent ) override;
	
	virtual void				CorrectRectOfPart( CPart* inMovedPart, THitPart partsToCorrect, long long *ioLeft, long long *ioTop, long long *ioRight, long long *ioBottom, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock ) override;
	

protected:
	virtual void	LoadPastedPartBackgroundContents( CPart* newPart, tinyxml2::XMLElement* currBgContents, bool haveCardContents, CStyleSheet * inStyleSheet ) override;
	virtual void	LoadPastedPartCardContents( CPart* newPart, tinyxml2::XMLElement* currCardContents, bool haveBgContents, CStyleSheet * inStyleSheet ) override;
	virtual const char*	GetLayerXMLType() override			{ return "background"; };
	virtual const char*	GetIdentityForDump() override		{ return "Background"; };
	
	std::set<CCardRef>	mMemberCards;
};

typedef CRefCountedObjectRef<CBackground>	CBackgroundRef;

}

#endif /* defined(__Stacksmith__CBackground__) */
