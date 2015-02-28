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


enum
{
	EHitTestWithoutHandles = 0,
	EHitTestHandlesToo
};
typedef uint8_t	THitTestHandlesFlag;


// 0 is top/left alignment, i.e. the default that you'd expect from HyperCard:
enum
{
	// First 2 bits are horizontal resize flags:
	EPartLayoutAlignHorizontalMask	=	0x03,
	EPartLayoutAlignLeft	= 0,
	EPartLayoutAlignHBoth	= 1,
	EPartLayoutAlignRight	= 2,
	EPartLayoutAlignHCenter	= 3,	// Center, left & both are mutually exclusive, so this is left + both.
	// Second 2 bits are vertical resize flags:
	EPartLayoutAlignVerticalMask	=	0x0C,
	EPartLayoutAlignTop		= 0,
	EPartLayoutAlignVBoth	= 4,
	EPartLayoutAlignBottom	= 8,
	EPartLayoutAlignVCenter	= 12,	// Center, top & both are mutually exclusive, so this is top + both.
};
typedef unsigned	TPartLayoutFlags;

#define PART_H_LAYOUT_MODE(n)	((n) & EPartLayoutAlignHorizontalMask)	// Gives EPartLayoutAlignLeft, EPartLayoutAlignHBoth, EPartLayoutAlignRight or EPartLayoutAlignHCenter.
#define PART_V_LAYOUT_MODE(n)	((n) & EPartLayoutAlignVerticalMask)	// Gives EPartLayoutAlignTop, EPartLayoutAlignVBoth, EPartLayoutAlignBottom or EPartLayoutAlignVCenter.


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
	virtual void				SaveAssociatedResourcesToElement( tinyxml2::XMLElement * inElement );
	virtual void				UpdateMediaIDs( std::map<ObjectID,ObjectID> changedIDMappings );
	
	virtual CPart*				Retain();
	virtual void				Release();
	
	virtual ObjectID			GetID()	const		{ return mID; };
	virtual void				SetID( ObjectID i )	{ mID = i; };
	LEOInteger					GetFamily()								{ return mFamily; };
	virtual void				SetFamily( LEOInteger inFamily )		{ mFamily = inFamily; };
	virtual void				SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom );
	LEOInteger					GetLeft();
	LEOInteger					GetTop();
	LEOInteger					GetRight();
	LEOInteger					GetBottom();
	virtual void				SetPartType( CPartCreatorBase* inType )	{ mPartType = inType; };	// Remembers the type, can't possibly change the type of this class.
	virtual CPartCreatorBase*	GetPartType()							{ return mPartType; };
	virtual std::string			GetTypeName()							{ return GetPartType()->GetPartTypeName(); };
	virtual LEOInteger			GetIndex( CPartCreatorBase* inType = NULL );
	virtual void				SetIndex( LEOInteger inIndex, CPartCreatorBase* inType = NULL );
	
	virtual bool				GetTextContents( std::string& outString );
	virtual bool				SetTextContents( const std::string& inString);

	virtual bool				GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool				SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );

	virtual void				SetPartLayoutFlags( TPartLayoutFlags inFlags );
	virtual TPartLayoutFlags	GetPartLayoutFlags()						{ return mPartLayoutFlags; };
	
	virtual void				WakeUp()		{};
	virtual void				GoToSleep()		{};
	virtual void				SetPeeking( bool inState )				{};
	virtual CScriptableObject*	GetParentObject();
	virtual CStack*				GetStack();
	virtual CPartContents*		GetContentsOnCurrentCard();
	
	virtual bool				GetSharedText()					{ return true; };	// By default, background part contents are the same on all cards of that background.
	virtual void				SetSharedText( bool n )			{};
	virtual void				SetSelected( bool inSelected );
	virtual bool				IsSelected()					{ return mSelected; };
	virtual void				SetHighlight( bool inHighlighted )	{};
	virtual void				PrepareMouseUp()				{};	// Sent when a mouse click was inside, right before we send mouseUp.
	bool						GetShouldSendMouseEventsRightNow();
	
	virtual CLayer*				GetOwner()						{ return mOwner; };
	
	virtual THitPart			HitTestForEditing( LEONumber x, LEONumber y, THitTestHandlesFlag handlesToo );	// Stack-relative coordinates relative to top left, descending down and right.
	virtual bool				GetRectForHandle( THitPart inDesiredPart, LEONumber *outLeft, LEONumber *outTop, LEONumber *outRight, LEONumber *outBottom );
	virtual LEONumber			GetHandleSize( bool *outAllowSideHandles, bool *outAllowCornerHandles );

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
	TPartLayoutFlags	mPartLayoutFlags;
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
