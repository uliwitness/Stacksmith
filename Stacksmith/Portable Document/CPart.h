//
//  CPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

/*!
	@class CPart
	This is the class that implements objects on a card or background, like buttons and fields.
	A part usually has contents (which are separate as a background part may have differing
	contents for each card). While parts are usually placed on a card and draw something, they
	do not have to. For example timers in Stacksmith are objects on a card or background, and
	are usually invisible. However, they show up as little icons that can be placed on a card
	while editing.
*/

#ifndef __Stacksmith__CPart__
#define __Stacksmith__CPart__

#include "CConcreteObject.h"
#include "tinyxml2.h"
#include "CObjectID.h"
#include "TTool.h"


namespace Carlson {

class CLayer;
class CPart;
class CPartContents;
class CUndoStack;


/*! Indicate which of the "resize handles" (aka "grabbers") have been clicked or
	are being moved right now. */
enum
{
	ENothingHitPart			= 0,		//!< Click was not on this object.
	ELeftGrabberHitPart		= (1 << 0),	//!< One of the left resize handles was clicked. If only bit set, it was the left center.
	ETopGrabberHitPart		= (1 << 1),	//!< Top resize handle was clicked. If only bit set, it was the top center.
	ERightGrabberHitPart	= (1 << 2),	//!< Right resize handle was clicked. If only bit set, it was the right center.
	EBottomGrabberHitPart	= (1 << 3),	//!< Bottom resize handle was clicked. If only bit set, it was the bottom center.
	EContentHitPart			= (ELeftGrabberHitPart | ETopGrabberHitPart | ERightGrabberHitPart | EBottomGrabberHitPart),			//!< No grab handle was clicked, but the click was inside the part's rectangle.
	EHorizontalMoveHitPart	= (ELeftGrabberHitPart | ERightGrabberHitPart),	//< Left & right == horizontal move with shift key.
	EVerticalMoveHitPart	= (ETopGrabberHitPart | EBottomGrabberHitPart),	//< Top & bottom == vertical move with shift key.
	ECustomGrabberHitPart	= (1 << 4)
}; typedef uint32_t THitPart;


/*! Indicate to the callback block how to display this coordinate. */
typedef enum
{
	EGuidelineCallbackActionAddHorizontal,			//< Request to add a guideline at the given h coordinate.
	EGuidelineCallbackActionAddVertical,			//< Request to add a guideline at the given v coordinate.
	EGuidelineCallbackActionAddHorizontalSpacer,	//< Request to add a 'distance indicator' between the corrected coordinate and the given h coordinate.
	EGuidelineCallbackActionAddVerticalSpacer,		//< Request to add a 'distance indicator' between the corrected coordinate and the given v coordinate.
	EGuidelineCallbackActionClearAllForFilling,		//< Request to clear your list of guidelines in preparation for us calling you back with the new set. (don't redraw yet)
	EGuidelineCallbackActionClearAllDone			//< Request to clear your list of guidelines, we're done tracking. (redraw now)
} TGuidelineCallbackAction;


typedef enum
{
	EHitTestWithoutHandles = 0,		//< Only tell us whether the part's rect was hit (used when deciding which object to select, when handles are not visible yet).
	EHitTestHandlesToo				//< The object is selected, the resize grabbers are visible, and should be hit-tested, too.
} THitTestHandlesFlag;	//< Modify the hit-testing behaviour of the function. Values like EHitTestWithoutHandles.


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


enum
{
	EAllHandlesSelected = -1
};

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
	/*! If a part has associated resources, this is how we copy them when this part is copied.
		You'd likely call SaveMediaToElement() for whatever media you depend on, on your
		document's media cache. */
	virtual void				SaveAssociatedResourcesToElement( tinyxml2::XMLElement * inElement ) {};
	/*! When a part is pasted its associated media are pasted as well.
		If media uses an ID that already exists for a different item, it gets re-numbered.
		This function gets called in that case to let you fix up any IDs that may have changed.
		As the new number may collide with a later one, you get a list of all changed IDs at
		once, so subsequent ID changes don't cause your ID to be re-mapped again. */
	virtual void				UpdateMediaIDs( std::map<ObjectID,ObjectID> changedIDMappings ) {};
	
	virtual CPart*				Retain() override;
	virtual void				Release() override;

	virtual std::string			GetObjectDescriptorString() override;

	
	virtual ObjectID			GetID()	const override	{ return mID; };
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
	virtual std::string			GetTypeName() override					{ return GetPartType()->GetPartTypeName(); };
	virtual LEOInteger			GetIndex( CPartCreatorBase* inType = NULL );
	virtual void				SetIndex( LEOInteger inIndex, CPartCreatorBase* inType = NULL );
	
	virtual void				ToolChangedFrom( TTool inOldTool )	{};
	virtual bool				CanBeEditedWithTool( TTool inTool )	{ return inTool == EPointerTool; };
	
	virtual bool				GetTextContents( std::string& outString ) override;
	virtual bool				SetTextContents( const std::string& inString) override;

	virtual bool				GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue ) override;
	virtual bool				SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd ) override;

	virtual void				SetPartLayoutFlags( TPartLayoutFlags inFlags );
	virtual TPartLayoutFlags	GetPartLayoutFlags()						{ return mPartLayoutFlags; };
	
	virtual void				WakeUp()		{};
	virtual void				GoToSleep()		{};
	virtual void				SetPeeking( bool inState )				{};
	virtual CScriptableObject*	GetParentObject( CScriptableObject* previousParent ) override;
	virtual CStack*				GetStack() override;
	virtual CPartContents*		GetContentsOnCurrentCard();
	virtual CUndoStack*			GetUndoStack();
	
	virtual bool				GetSharedText()					{ return true; };	//!< By default, background part contents are the same on all cards of that background.
	virtual void				SetSharedText( bool n )			{};
	virtual void				SetSelected( bool inSelected, LEOInteger handleIndex = EAllHandlesSelected );
	virtual bool				IsSelected()					{ return mSelected; };
	virtual LEOInteger			GetSelectedHandle()				{ return mSelectedHandle; };
	virtual void				SetHighlight( bool inHighlighted )	{};
	virtual void				PrepareMouseUp()				{};	//!< Sent when a mouse click was inside, right before we send mouseUp.
	bool						GetShouldSendMouseEventsRightNow();
	virtual void				WillBeDeleted()					{};
	virtual bool				DeleteObject() override;
	
	virtual CLayer*				GetOwner()						{ return mOwner; };
	
	virtual THitPart			HitTestForEditing( LEONumber x, LEONumber y, THitTestHandlesFlag handlesToo, LEOInteger *outCustomHandleIndex );	//!< Stack-relative coordinates relative to top left, descending down and right.
	virtual bool				GetRectForHandle( THitPart inDesiredPart, LEONumber *outLeft, LEONumber *outTop, LEONumber *outRight, LEONumber *outBottom );
	virtual LEONumber			GetHandleSize( bool *outAllowSideHandles, bool *outAllowCornerHandles );
	virtual LEOInteger			GetNumCustomHandlesForTool( TTool inTool )			{ return -1; };	//!< -1 means no custom handles, use the standard 8. 0 means no handles *at all*.
	virtual void				SetPositionOfCustomHandleAtIndex( LEOInteger idx, LEONumber x, LEONumber y )	{};
	virtual void				GetPositionOfCustomHandleAtIndex( LEOInteger idx, LEONumber *outX, LEONumber *outY )	{};
	virtual void				GetRectForCustomHandle( LEOInteger idx, LEONumber *outLeft, LEONumber *outTop, LEONumber *outRight, LEONumber *outBottom );

	virtual void				Grab( THitPart inHitPart, LEOInteger customGrabPartIndex, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock );
	virtual std::string			GetDisplayName() override	{ return GenerateDisplayName( GetIdentityForDump() ); };
	
	virtual void				IncrementChangeCount() override;
	
	virtual void				Dump( size_t inIndent = 0 ) override;
	
protected:
	virtual ~CPart();

	virtual void				SetRectFromUndo( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b );
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
	CLayer	*			mOwner;				//!< Card/background we are on.
	CPartCreatorBase*	mPartType;			//!< Only used for comparing if two parts are same type.
	bool				mSelected;
	LEOInteger			mSelectedHandle;	//!< EAllHandlesSelected is valid here..
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
