//
//  CCard.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CCard__
#define __Stacksmith__CCard__

#include "CPlatformLayer.h"


namespace Carlson {

class CBackground;


/*!
	@class CCard
	This is the class that implements each card. It contains an ordered list of
	parts (HyperCard terminology for controls like buttons and text fields) and
	of contents (which contain contents of both the card, and for any background
	parts that have sharedText turned off). Each card is a member of a background.
*/

class CCard : public CPlatformLayer
{
public:
	CCard( std::string inURL, ObjectID inID, CBackground* inOwningBackground, const std::string& inName, const std::string& inFileName, CStack* inStack, bool inMarked );
	~CCard();
	
	bool			IsMarked()					{ return mMarked; };
	void			SetMarked( bool inMarked );
	
	virtual void	WakeUp() override;
	virtual void	GoToSleep() override;
		
	virtual void	SetPeeking( bool inState ) override;
	
	virtual CScriptableObject*	GetParentObject( CScriptableObject* previousParent ) override;
	virtual CBackground*		GetBackground()		{ return mOwningBackground; };
	virtual void				SetBackground( CBackground* inBg )	{ mOwningBackground = inBg; };	// Used mainly for assigning a background to a newly-created, never-before saved card in RAM.
	
	virtual bool				GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler, const std::string& inEffectType, TVisualEffectSpeed inSpeed ) override;
	virtual bool				GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue ) override;
	virtual bool				SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd ) override;
	
	virtual std::string			GetDisplayName() override;
	virtual std::string			GetTypeName() override			{ return std::string("card"); };

	virtual void	CorrectRectOfPart( CPart* inMovedPart, THitPart partsToCorrect, long long *ioLeft, long long *ioTop, long long *ioRight, long long *ioBottom, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock ) override;	// addGuidelineBlock gets called to create guidelines.
	
protected:
	virtual void	LoadPropertiesFromElement( tinyxml2::XMLElement* root ) override;
	virtual void	SavePropertiesToElement( tinyxml2::XMLElement* stackfile ) override;
	virtual void	CallAllCompletionBlocks() override;
	virtual const char*	GetLayerXMLType() override			{ return "card"; };

	virtual const char*	GetIdentityForDump() override		{ return "Card"; };

protected:
	bool			    mMarked;
	CBackground	*	    mOwningBackground;
};

typedef CRefCountedObjectRef<CCard>	CCardRef;

}

#endif /* defined(__Stacksmith__CCard__) */
