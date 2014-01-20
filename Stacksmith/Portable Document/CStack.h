//
//  CStack.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CStack__
#define __Stacksmith__CStack__

#include <vector>
#include <set>
#include <string>
#include "CConcreteObject.h"
#include "CObjectID.h"
#include "CCard.h"
#include "CBackground.h"


namespace Carlson {


class CStack : public CConcreteObject
{
public:
	static CStack*	GetFrontStack()						{ return sFrontStack; };
	static void		SetFrontStack( CStack* inStack )	{ sFrontStack = inStack; };

	CStack( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument ) : mStackID(inID), mURL(inURL), mFileName(inFileName) { mName = inName; mDocument = inDocument; };
	
	void			Load( std::function<void(CStack*)> inCompletionBlock );
	void			Save();
	
	ObjectID		GetID()			{ return mStackID; };
	std::string		GetURL()		{ return mURL; };
	std::string		GetFileName()	{ return mFileName; };
	
	void			AddCard( CCard* inCard );
	void			RemoveCard( CCard* inCard );
	size_t			GetNumCards()						{ return mCards.size(); };
	CCard*			GetCard( size_t inIndex )			{ if( inIndex >= mCards.size() ) return NULL; return mCards[inIndex]; };
	CCard*			GetCardByID( ObjectID inID );
	CCard*			GetCardByName( const char* inName );
	size_t			GetIndexOfCard( CCard* inBackground );
	
	size_t			GetNumBackgrounds()					{ return mBackgrounds.size(); };
	CBackground*	GetBackground( size_t inIndex )		{ if( inIndex >= mBackgrounds.size() ) return NULL; return mBackgrounds[inIndex]; };
	CBackground*	GetBackgroundByID( ObjectID inID );
	CBackground*	GetBackgroundByName( const char* inName );
	size_t			GetIndexOfBackground( CBackground* inBackground );
	
	virtual void	WakeUp()	{};	// The current card has started its timers etc.
	virtual void	GoToSleep()	{};	// The current card has stopped its timers etc.
	
	virtual void	SetCurrentCard( CCard* inCard )	{ mCurrentCard = inCard; };
	virtual CCard*	GetCurrentCard()				{ return mCurrentCard; };
	virtual CStack*	GetStack()						{ return this; };
	size_t			GetCardWidth()					{ return mCardWidth; };
	size_t			GetCardHeight()					{ return mCardHeight; };
	
	virtual void	SetPeeking( bool inState );
	
	virtual void	Dump( size_t inIndent = 0 );
	
protected:
	~CStack();

protected:
	bool						mLoading;			// Currently loading, not yet ready for use.
	bool						mLoaded;			// Finished loading, ready for use.
	std::string					mURL;				// URL of the file backing this stack on disk.
	std::string					mFileName;			// Partial path relative to containing .xstk package to our file (i.e. the one at mURL).
	ObjectID					mStackID;			// Unique ID number of this stack in the document.
	int							mUserLevel;			// Maximum user level for this stack.
	int							mCardWidth;			// Size of cards in this stack.
	int							mCardHeight;		// Size of cards in this stack.
	bool						mCantPeek;			// Do we prevent "peeking" of button rects using Cmd-Option?
	bool						mCantAbort;			// Do we prohibit Cmd-. from canceling scripts?
	bool						mPrivateAccess;		// Do we require a password before opening this stack?
	bool						mCantDelete;		// Are scripts allowed to delete this stack?
	bool						mCantModify;		// Is this stack write-protected?
	bool						mResizable;			// Can the stack's window be resized by the user?
	ObjectID					mCardIDSeed;		// ID number for next new card/background (unless already taken, then we'll add to it until we hit a free one).
	std::vector<CCardRef>		mCards;				// List of all cards in this stack.
	std::vector<CBackgroundRef>	mBackgrounds;		// List of all backgrounds in this stack.
	std::set<CCardRef>			mMarkedCards;		// List of all cards in this stack.
	CCardRef					mCurrentCard;		// The card that is currently being shown in this stack's window.
	
	static CStack*				sFrontStack;		// The stack whose window is currently frontmost and will e.g. receive messages from the message box.
};

typedef CRefCountedObjectRef<CStack>	CStackRef;

}

#endif /* defined(__Stacksmith__CStack__) */
