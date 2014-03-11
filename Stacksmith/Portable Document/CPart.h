//
//  CPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CPart__
#define __Stacksmith__CPart__

#include "CConcreteObject.h"
#include "tinyxml2.h"
#include "CObjectID.h"


namespace Carlson {

class CLayer;
class CPart;
class CPartContents;


enum
{
	ENothingHitPart			= 0,
	ELeftGrabberHitPart		= (1 << 0),
	ETopGrabberHitPart		= (1 << 1),
	ERightGrabberHitPart	= (1 << 2),
	EBottomGrabberHitPart	= (1 << 3),
	EContentHitPart			= (ELeftGrabberHitPart | ETopGrabberHitPart | ERightGrabberHitPart | EBottomGrabberHitPart),
	// Left & right == horizontal move with shift key.
	// Top & bottom == vertical move with shift key.
};
typedef uint32_t THitPart;


enum
{
	EGuidelineCallbackActionAddHorizontal,			// Request to add a guideline at the given h coordinate.
	EGuidelineCallbackActionAddVertical,			// Request to add a guideline at the given v coordinate.
	EGuidelineCallbackActionAddHorizontalSpacer,	// Request to add a 'distance indicator' between the corrected coordinate and the given h coordinate.
	EGuidelineCallbackActionAddVerticalSpacer,		// Request to add a 'distance indicator' between the corrected coordinate and the given v coordinate.
	EGuidelineCallbackActionClearAllForFilling,		// Request to clear your list of guidelines in preparation for us calling you back with the new set. (don't redraw yet)
	EGuidelineCallbackActionClearAllDone			// Request to clear your list of guidelines, we're done tracking. (redraw now)
};
typedef uint8_t	TGuidelineCallbackAction;



class CPartCreatorBase
{
public:
	CPartCreatorBase( const std::string& inTypeString = std::string() ) : mPartTypeName(inTypeString) {};
	virtual ~CPartCreatorBase() {};
	
	virtual CPart	*	NewPartInOwner( CLayer *inOwner )	{ return NULL; };
	
	std::string			GetPartTypeName()	{ return mPartTypeName; };
	
protected:
	std::string		mPartTypeName;
};


class CPart : public CConcreteObject
{
public:
	static CPart*				NewPartWithElement( tinyxml2::XMLElement * inElement, CLayer *inOwner );
	static void					RegisterPartCreator( CPartCreatorBase* inCreator );
	static CPartCreatorBase*	GetPartCreatorForType( const char* inType );
	
	explicit CPart( CLayer *inOwner );
	
	virtual void				LoadFromElement( tinyxml2::XMLElement * inElement );
	virtual void				SaveToElement( tinyxml2::XMLElement * inElement );
	
	virtual CPart*				Retain();
	virtual void				Release();
	
	ObjectID					GetID()				{ return mID; };
	virtual void				SetID( ObjectID i )	{ mID = i; };
	LEOInteger					GetFamily()								{ return mFamily; };
	virtual void				SetFamily( LEOInteger inFamily )		{ mFamily = inFamily; };
	virtual void				SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom )	{ mLeft = left; mTop = top; mRight = right; mBottom = bottom; };
	LEOInteger					GetLeft()		{ return mLeft; };
	LEOInteger					GetTop()		{ return mTop; };
	LEOInteger					GetRight()		{ return mRight; };
	LEOInteger					GetBottom()		{ return mBottom; };
	virtual void				SetPartType( CPartCreatorBase* inType )	{ mPartType = inType; };	// Remembers the type, can't possibly change the type of this class.
	virtual CPartCreatorBase*	GetPartType()							{ return mPartType; };
	virtual LEOInteger			GetIndex( CPartCreatorBase* inType = NULL );
	virtual void				SetIndex( LEOInteger inIndex, CPartCreatorBase* inType = NULL );
	
	virtual bool				GetTextContents( std::string& outString );
	virtual bool				SetTextContents( const std::string& inString);

	virtual bool				GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool				SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	
	virtual void				WakeUp()		{};
	virtual void				GoToSleep()		{};
	virtual void				SetPeeking( bool inState )				{};
	virtual CScriptableObject*	GetParentObject();
	virtual CStack*				GetStack();
	virtual CPartContents*		GetContentsOnCurrentCard();
	
	virtual bool				GetSharedText()					{ return true; };	// By default, background part contents are the same on all cards of that background.
	virtual void				SetSelected( bool inSelected )	{ mSelected = inSelected; };
	virtual bool				IsSelected()					{ return mSelected; };
	virtual void				SetHighlight( bool inHighlighted )	{};
	virtual void				PrepareMouseUp()				{};	// Sent when a mouse click was inside, right before we send mouseUp.
	
	virtual CLayer*				GetOwner()						{ return mOwner; };
	
	virtual THitPart			HitTestForEditing( LEONumber x, LEONumber y );	// Stack-relative coordinates relative to top left, descending down and right.
	virtual void				Grab( THitPart inHitPart, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock );	// If the callback coord is LLONG_MAX and bool is TRUE, this means tracking has finished and you should remove all guidelines from the screen. If bool is FALSE in this situation, it just means we're starting a new set of guidelines.
	virtual std::string			GetDisplayName()	{ return GenerateDisplayName( GetIdentityForDump() ); };
	
	virtual void				IncrementChangeCount();
	
	virtual void				Dump( size_t inIndent = 0 );
	
protected:
	virtual ~CPart();

	virtual void				LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual void				SavePropertiesToElement( tinyxml2::XMLElement * inElement );
	virtual const char*			GetIdentityForDump()					{ return "Part"; };
	virtual void				DumpProperties( size_t inIndent );
	virtual std::string			GenerateDisplayName( const char* inTypeName );

	LEOInteger			mFamily;
	ObjectID			mID;
	LEOInteger			mLeft;
	LEOInteger			mTop;
	LEOInteger			mRight;
	LEOInteger			mBottom;
	CLayer	*			mOwner;		// Card/background we are on.
	CPartCreatorBase*	mPartType;	// Only used for comparing if two parts are same type.
	bool				mSelected;
};


typedef CRefCountedObjectRef<CPart>		CPartRef;


template<class T>
class CPartCreator : public CPartCreatorBase
{
public:
	CPartCreator( const std::string& inTypeString = std::string() ) : CPartCreatorBase(inTypeString) {};
	virtual CPart	*	NewPartInOwner( CLayer *inOwner )	{ CPart* thePart = new T( inOwner ); thePart->SetPartType(this); return thePart; };
};

}

#endif /* defined(__Stacksmith__CPart__) */
