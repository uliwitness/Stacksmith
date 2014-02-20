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


enum
{
	EBrowseTool = 0,
	EPointerTool,
	ETool_Last
};
typedef uint16_t	TTool;


enum
{
	EStackStyleStandard,	// Standard document window.
	EStackStyleRectangle,	// Window with a simple border.
	EStackStylePopup,		// Pop-up utility window, like popovers on Mac/iOS. May be possible to tear one off as some kind of floating palette, or OSes may just make them palettes.
	EStackStylePalette,		// Floating utility window with additional stuff in it.
	EStackStyle_Last
};
typedef uint16_t	TStackStyle;


class CStack : public CConcreteObject
{
public:
	CStack( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument ) : mStackID(inID), mURL(inURL), mFileName(inFileName), mPeeking(false), mEditingBackground(false), mCantPeek(false), mCantAbort(false), mResizable(false), mCantDelete(false), mCantModify(false), mCurrentTool(EBrowseTool), mStyle(EStackStyleStandard), mUserLevel(5), mCardWidth(512), mCardHeight(342), mChangeCount(0) { mName = inName; mDocument = inDocument; };
	
	void			Load( std::function<void(CStack*)> inCompletionBlock );
	void			SetLoaded( bool n )	{ mLoaded = n; };	// Used when creating a brand new stack in RAM that's never been saved before.
	void			Save( const std::string& inPackagePath );
	
	ObjectID		GetID()			{ return mStackID; };
	std::string		GetURL()		{ return mURL; };
	std::string		GetFileName()	{ return mFileName; };
	
	void			AddCard( CCard* inCard );	// Add at end.
	void			InsertCardAfterCard( CCard* inNewCard, CCard *precedingCard = NULL );	// If precedingCard == NULL insert at start.
	void			RemoveCard( CCard* inCard );
	size_t			GetNumCards()						{ return mCards.size(); };
	CCard*			GetCard( size_t inIndex )			{ if( inIndex >= mCards.size() ) return NULL; return mCards[inIndex]; };
	CCard*			GetCardByID( ObjectID inID );
	CCard*			GetCardByName( const char* inName );
	size_t			GetIndexOfCard( CCard* inCard );
	void			SetIndexOfCardTo( CCard* inCd, size_t newIndex );
	CCard*			GetCardWithBackground( CBackground* inBg, CCard *startAtCard = NULL, bool searchForward = true );
	size_t			GetNumCardsWithBackground( CBackground* inBg );
	CCard*			GetCardAtIndexWithBackground( size_t cardIdx, CBackground* inBg );
	CCard*			AddNewCard();
	virtual void	MarkedStateChangedOfCard( CCard* inCard );
	
	void			AddBackground( CBackground* inBackground );	// Add at end.
	size_t			GetNumBackgrounds()					{ return mBackgrounds.size(); };
	CBackground*	GetBackground( size_t inIndex )		{ if( inIndex >= mBackgrounds.size() ) return NULL; return mBackgrounds[inIndex]; };
	CBackground*	GetBackgroundByID( ObjectID inID );
	CBackground*	GetBackgroundByName( const char* inName );
	size_t			GetIndexOfBackground( CBackground* inBackground );
	void			SetIndexOfBackgroundTo( CBackground* inBg, size_t newIndex );
	CCard*			AddNewCardWithBackground( CBackground* inBg = NULL );	// NULL inBg means create a new background.
	
	virtual void	WakeUp()	{};	// The current card has started its timers etc.
	virtual void	GoToSleep()	{};	// The current card has stopped its timers etc.
	
	virtual void	SetCurrentCard( CCard* inCard )	{ mCurrentCard = inCard; };
	virtual CCard*	GetCurrentCard()				{ return mCurrentCard; };
	CCard*			GetNextCard();
	CCard*			GetPreviousCard();
	virtual CLayer*	GetCurrentLayer()				{ if( mEditingBackground ) return mCurrentCard->GetBackground(); return mCurrentCard; };
	virtual CStack*	GetStack()						{ return this; };
	size_t			GetCardWidth()					{ return mCardWidth; };
	virtual void	SetCardWidth( int n )			{ mCardWidth = n; };
	size_t			GetCardHeight()					{ return mCardHeight; };
	virtual void	SetCardHeight( int n )			{ mCardHeight = n; IncrementChangeCount(); };
	
	virtual void	SetPeeking( bool inState );
	virtual bool	GetPeeking()							{ return mPeeking; };
	virtual void	SetEditingBackground( bool inState )	{ mEditingBackground = inState; };
	virtual bool	GetEditingBackground()					{ return mEditingBackground; };
	
	virtual void	SetTool( TTool inTool );
	virtual TTool	GetTool()								{ return mCurrentTool; };

	virtual void	SetName( const std::string& inName );
	virtual void	SetStyle( TStackStyle inStyle )			{ mStyle = inStyle; IncrementChangeCount(); };
	TStackStyle		GetStyle()								{ return mStyle; };
	virtual bool	IsResizable()							{ return mResizable; };
	virtual void	SetResizable( bool n )					{ mResizable = n; IncrementChangeCount(); };
	
	virtual bool	GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool	SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	virtual bool	ShowScriptEditorForObject( CConcreteObject* inObject ) { return false; };
	virtual bool	ShowPropertyEditorForObject( CConcreteObject* inObject ) { return false; };
	
	virtual void	GetMousePosition( LEONumber *x, LEONumber *y )	{ *x = 0; *y = 0; };
	virtual void	RectChangedOfPart( CPart* inChangedPart )	{};

	virtual void	IncrementChangeCount()	{ mChangeCount++; };
	virtual bool	GetNeedsToBeSaved();
	
	virtual void	Dump( size_t inIndent = 0 );
	
// statics:
	static CStack*		GetFrontStack()						{ return sFrontStack; };
	static void			SetFrontStack( CStack* inStack )	{ sFrontStack = inStack; };

	static const char*	GetToolName( TTool inTool );
	static TTool		GetToolFromName( const char* inName );
	static TStackStyle	GetStackStyleFromString( const char* inStyleStr );

protected:
	void			CallAllCompletionBlocks();
	
	~CStack();

protected:
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
	std::vector<CCardRef>		mCards;				// List of all cards in this stack.
	std::vector<CBackgroundRef>	mBackgrounds;		// List of all backgrounds in this stack.
	std::set<CCardRef>			mMarkedCards;		// List of all cards whose 'marked' property is true in this stack.
	TStackStyle					mStyle;				// Window style.
	
	bool						mLoading;			// Currently loading, not yet ready for use.
	bool						mLoaded;			// Finished loading, ready for use.
	bool						mPeeking;			// Are we currently showing the "peek" outline.
	ObjectID					mCardIDSeed;		// ID number for next new card/background (unless already taken, then we'll add to it until we hit a free one).
	CCardRef					mCurrentCard;		// The card that is currently being shown in this stack's window.
	std::vector<std::function<void(CStack*)>>	mLoadCompletionBlocks;
	bool						mEditingBackground;	// Are we editing the background, or are we showing the full mixed card/bg layers?
	TTool						mCurrentTool;		// The tool that applies when clicking in this stack's window.
	size_t						mChangeCount;
	
	static CStack*				sFrontStack;		// The stack whose window is currently frontmost and will e.g. receive messages from the message box.
};

typedef CRefCountedObjectRef<CStack>	CStackRef;

}

#endif /* defined(__Stacksmith__CStack__) */
