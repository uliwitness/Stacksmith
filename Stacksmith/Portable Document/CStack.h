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
#include "TTool.h"


namespace Carlson {


enum
{
	EEvenIfVisible = 0,
	EOnlyIfNotVisible
};
typedef uint8_t		TEvenIfVisible;


enum
{
	EStackStyleStandard,	//!< Standard window.
	EStackStyleDocument,	//!< Standard document window (file's icon in title bar etc.).
	EStackStyleRectangle,	//!< Window with a simple border.
	EStackStylePopup,		//!< Pop-up utility window, like popovers on Mac/iOS. May be possible to tear one off as some kind of floating palette, or OSes may just make them palettes.
	EStackStylePalette,		//!< Floating utility window with additional stuff in it.
	EStackStyle_Last
};
typedef uint16_t	TStackStyle;
	
static inline bool TStackStyleCanBeInactive( TStackStyle style )
{
	return style != EStackStylePopup && style != EStackStylePalette;
}


class CUndoStack;


class CStack : public CConcreteObject
{
public:
	CStack( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument ) : mStackID(inID), mURL(inURL), mFileName(inFileName), mCantPeek(false), mCantAbort(false), mPrivateAccess(false), mCantDelete(false), mCantModify(false), mResizable(false), mStyle(EStackStyleDocument), mUserLevel(5), mCardWidth(512), mCardHeight(342), mCardLeft(0), mLoading(false), mLoaded(false), mPeeking(false), mCardIDSeed(0), mEditingBackground(false), mCurrentTool(EBrowseTool), mChangeCount(0),mLineSize(1) { mName = inName; mDocument = inDocument; /* printf("stack %s created.\n", DebugNameForPointer(this) ); */ };
	
	virtual void	Load( std::function<void(CStack*)> inCompletionBlock );
	void			SetLoaded( bool n )	{ mLoaded = n; };	//!< Used when creating a brand new stack in RAM that's never been saved before.
	virtual bool	IsLoaded()			{ return mLoaded; };
	virtual bool	Save( const std::string& inPackagePath );
	
	ObjectID			GetID()	const override	{ return mStackID; };
	std::string			GetURL()				{ return mURL; };
	std::string			GetDocumentURL()		{ return mDocumentURL; };
	std::string			GetFileName()			{ return mFileName; };
	virtual std::string	GetTypeName() override	{ return std::string("stack"); };
	virtual bool		ShowHandlersForObjectType( std::string inTypeName ) override	{ return true; };	//!< Show all handlers in our popup, we may get them forwarded through the message path.
	virtual CScriptableObject*	GetParentObject( CScriptableObject* previousParent, LEOContext * ctx ) override;
	
	void			AddCard( CCard* inCard );	//!< Add at end.
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
	bool			DeleteCard( CCard* inCard );	//!< May implicitly delete card's background if it was the only card with that background.
	virtual void	MarkedStateChangedOfCard( CCard* inCard );
	void			SetMarkedOfAllCards( bool inState );
	
	void			AddBackground( CBackground* inBackground );	//!< Add at end.
	void			RemoveBackground( CBackground* inBg );
	size_t			GetNumBackgrounds()					{ return mBackgrounds.size(); };
	CBackground*	GetBackground( size_t inIndex )		{ if( inIndex >= mBackgrounds.size() ) return NULL; return mBackgrounds[inIndex]; };
	CBackground*	GetBackgroundByID( ObjectID inID );
	CBackground*	GetBackgroundByName( const char* inName );
	size_t			GetIndexOfBackground( CBackground* inBackground );
	void			SetIndexOfBackgroundTo( CBackground* inBg, size_t newIndex );
	CCard*			AddNewCardWithBackground( CBackground* inBg = NULL );	//!< NULL inBg means create a new background.
	
	virtual void	WakeUp()	{};	//!< The current card has started its timers etc.
	virtual void	GoToSleep()	{};	//!< The current card has stopped its timers etc.
	
	virtual void	SetCurrentCard( CCard* inCard, const std::string& inEffectType = "", TVisualEffectSpeed inSpeed = EVisualEffectSpeedNormal );
	virtual CCard*	GetCurrentCard()				{ return mCurrentCard; };
	CCard*			GetNextCard();
	CCard*			GetPreviousCard();
	virtual CLayer*	GetCurrentLayer()				{ if( mEditingBackground ) return mCurrentCard->GetBackground(); return mCurrentCard; };
	virtual CStack*	GetStack() override						{ return this; };
	LEOInteger		GetCardWidth()							{ return mCardWidth; };
	virtual void	SetCardWidth( LEOInteger n )			{ mCardWidth = n; IncrementChangeCount(); };
	LEOInteger		GetCardHeight()							{ return mCardHeight; };
	virtual void	SetCardHeight( LEOInteger n )			{ mCardHeight = n; IncrementChangeCount(); };
	virtual void	StackRectDidChangeTo( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b ) { mCardLeft = l; mCardTop = t; mCardWidth = r - l; mCardHeight = b - t; IncrementChangeCount(); };
	
	void			ForEachSelectedPart(std::function<void(CPart*)> callback);
	
	virtual void	SetPeeking( bool inState );
	virtual bool	GetPeeking()							{ return mPeeking; };
	virtual void	SetEditingBackground( bool inState )	{ mEditingBackground = inState; };
	virtual bool	GetEditingBackground()					{ return mEditingBackground; };
	
	virtual void	SetTool( TTool inTool );
	virtual TTool	GetTool()								{ return mCurrentTool; };
	virtual void		SetLineSize( LEONumber lineWidth )	{ mLineSize = lineWidth; };
	virtual LEONumber	GetLineSize()						{ return mLineSize; };
	
	virtual void	DeselectAllObjectsOnCard();
	virtual void	SelectAllObjectsOnCard();
	virtual void	DeselectAllObjectsOnBackground();
	virtual void	SelectAllObjectsOnBackground();
	virtual CPart*	NewPart( size_t inIndex );
	
	virtual void	BringSelectedItemToFront();
	virtual void	BringSelectedItemForward();
	virtual void	SendSelectedItemBackward();
	virtual void	SendSelectedItemToBack();

	virtual void	SetName( const std::string& inName ) override;
	virtual void	SetDocumentURL( const std::string& inURL )	{ mDocumentURL = inURL; }
	virtual void	SetStyle( TStackStyle inStyle )			{ mStyle = inStyle; IncrementChangeCount(); };
	TStackStyle		GetStyle()								{ return mStyle; };
	virtual bool	IsResizable()							{ return mResizable; };
	virtual void	SetResizable( bool n )					{ mResizable = n; IncrementChangeCount(); };
	virtual bool	GetCantDelete()							{ return mCantDelete; };
	virtual void	SetCantDelete( bool n )					{ mCantDelete = n; };
	virtual bool	GetCantModify()							{ return mCantModify; };
	virtual void	SetCantModify( bool n )					{ mCantModify = n; };
	virtual LEOInteger	GetLeft()							{ return mCardLeft; }
	virtual LEOInteger	GetTop()							{ return mCardTop; }
	virtual LEOInteger	GetRight()							{ return mCardWidth; }
	virtual LEOInteger	GetBottom()							{ return mCardHeight; }
	virtual void		SetRect( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b )	{}
	virtual bool	GetEffectiveCantModify();
	
	virtual bool	GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue ) override;
	virtual bool	SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd ) override;
	virtual bool	ShowScriptEditorForObject( CConcreteObject* inObject ) { return false; };
	virtual bool	ShowPropertyEditorForObject( CConcreteObject* inObject ) { return false; };
	virtual bool	ShowContextualMenuForObject( CConcreteObject* inObject ) { return false; };
	
	virtual std::string		GetObjectDescriptorString() override	{ return std::string("stack \"") + mURL + "\""; };
	
	virtual void	GetMousePosition( LEONumber *x, LEONumber *y );
	virtual void	RectChangedOfPart( CPart* inChangedPart )	{};
	virtual void	SelectedPartChanged()						{};

	virtual void	IncrementChangeCount() override;
	virtual void	LayerIncrementedChangeCount( CLayer* inLayer );
	virtual bool	GetNeedsToBeSaved() override;
	
	virtual bool	GetShouldForwardToMainStack()				{ return( mStyle == EStackStylePopup || mStyle == EStackStylePalette ); };
	
	virtual CUndoStack*	GetUndoStack();
	
	virtual void	ClearAllGuidelines( bool inTrackingDone = false )	{ mHorizontalGuidelines.clear(); mVerticalGuidelines.clear(); };
	virtual void	AddGuideline( long long inGuidelineCoord, bool inHorzNotVert )	{ if( inHorzNotVert ) mHorizontalGuidelines.push_back(inGuidelineCoord); else mVerticalGuidelines.push_back(inGuidelineCoord); };
	virtual size_t	GetNumGuidelines()		{ return mHorizontalGuidelines.size() + mVerticalGuidelines.size(); };
	virtual void	GetGuidelineAtIndex( size_t idx, long long *outCoord, bool *outHorzNotVert )	{ size_t hcount = mHorizontalGuidelines.size(); if( idx >= hcount ) { *outCoord = mVerticalGuidelines[idx-hcount]; *outHorzNotVert = false; } else { *outCoord = mHorizontalGuidelines[idx]; *outHorzNotVert = true; } };
	
	// Visibility feedback from the UI: (This is not whether the stack's window is obscured, but whether it's actually ordered out or closed)
	virtual bool	IsVisible()								{ return mVisible; }
	virtual void	SetVisible( bool n );
	
	virtual void		SetThemeName( std::string inThemeName )	{ mThemeName = inThemeName; IncrementChangeCount(); }
	virtual std::string	GetThemeName()							{ return mThemeName; }
	
	// Allow code to trigger showing the UI:
	virtual void	Show( TEvenIfVisible inEvenIfVisible )		{ mVisible = true; }
	virtual void	Hide()										{ mVisible = false; }
	
	std::string		GetThumbnailName()						{ return mThumbnailName; }	//!< Empty string if we have no thumbnail.
	void			SetThumbnailName( std::string inName )	{ mThumbnailName = inName; }
	virtual void	SaveThumbnail();
	virtual void	SaveThumbnailIfFirstCardOpen()			{}

	virtual void	NumberOrOrderOfPartsChanged()			{}

	virtual void	Dump( size_t inIndent = 0 ) override;
	
// statics:
	static CStack*		GetActiveStack()						{ return sActiveStack; }
	static void			SetActiveStack( CStack* inStack );
	static void			SetActiveStackChangedCallback( std::function<void(CStack*)> inCallback )	{ sActiveStackChangedBlock = inCallback; }
	static CStack*		GetMainStack()						{ return sMainStack; }
	static void			SetMainStack( CStack* inStack );
	static void			SetMainStackChangedCallback( std::function<void(CStack*)> inCallback )	{ sMainStackChangedBlock = inCallback; }

	static const char*	GetToolName( TTool inTool );
	static TTool		GetToolFromName( const char* inName );
	static TStackStyle	GetStackStyleFromString( const char* inStyleStr );

protected:
	void			CallAllCompletionBlocks();
	
	~CStack();

protected:
	std::string					mURL;				//!< URL of the file backing this stack on disk.
	std::string					mDocumentURL;		//!< Script-provided URL to show in title bar.
	std::string					mFileName;			//!< Partial path relative to containing .xstk package to our file (i.e. the one at mURL).
	std::string					mThumbnailName;		//!< Name of image file where we save a thumbnail of the first card in the stack.
	ObjectID					mStackID;			//!< Unique ID number of this stack in the document.
	int							mUserLevel;			//!< Maximum user level for this stack.
	LEOInteger					mCardWidth;			//!< Size of cards in this stack.
	LEOInteger					mCardHeight;		//!< Size of cards in this stack.
	LEOInteger					mCardLeft;			//!< Position of this stack's window.
	LEOInteger					mCardTop;			//!< Position of this stack's window.
	bool						mCantPeek;			//!< Do we prevent "peeking" of button rects using Cmd-Option?
	bool						mCantAbort;			//!< Do we prohibit Cmd-. from canceling scripts?
	bool						mPrivateAccess;		//!< Do we require a password before opening this stack?
	bool						mCantDelete;		//!< Are scripts allowed to delete this stack?
	bool						mCantModify;		//!< Is this stack write-protected using the cantModify property?
	bool						mResizable;			//!< Can the stack's window be resized by the user?
	std::vector<CCardRef>		mCards;				//!< List of all cards in this stack.
	std::vector<CBackgroundRef>	mBackgrounds;		//!< List of all backgrounds in this stack.
	std::set<CCardRef>			mMarkedCards;		//!< List of all cards whose 'marked' property is true in this stack.
	TStackStyle					mStyle;				//!< Window style.
	std::string					mThemeName = "default";	//!< Theme controlling the window's appearance. Not all platforms may support all themes, and some may be platform-specific. If a theme isn't known to a platform, you get the default theme, otherwise you might get an exact match or the platform's closest match.
	
	bool						mLoading;			//!< Currently loading, not yet ready for use.
	bool						mLoaded;			//!< Finished loading, ready for use.
	bool						mPeeking;			//!< Are we currently showing the "peek" outline.
	ObjectID					mCardIDSeed;		//!< ID number for next new card/background (unless already taken, then we'll add to it until we hit a free one).
	CCardRef					mCurrentCard;		//!< The card that is currently being shown in this stack's window.
	std::vector<std::function<void(CStack*)>>	mLoadCompletionBlocks;
	bool						mEditingBackground;	//!< Are we editing the background, or are we showing the full mixed card/bg layers?
	TTool						mCurrentTool;		//!< The tool that applies when clicking in this stack's window.
	LEONumber					mLineSize;			//!< The width of new lines drawn in this window. (Or base width for pressure-sensitive pointing devices).
	size_t						mChangeCount;
	bool						mVisible;			//!< Is this stack currently visible on screen?
	
	CUndoStack*					mUndoStack;			//!< Add undo blocks to this object.
	
	std::vector<long long>		mHorizontalGuidelines;	//!< Temp. guidelines shown when moving/resizing objects on the card.
	std::vector<long long>		mVerticalGuidelines;	//!< Temp. guidelines shown when moving/resizing objects on the card.
	
	static CStack*							sActiveStack;		//!< Like sMainStack, but for the frontmost popover or palette window.
	static std::function<void(CStack*)>		sActiveStackChangedBlock;
	static CStack*							sMainStack;			//!< The stack whose window is currently frontmost among all non-palette-style stacks and will e.g. receive messages from the message box.
	static std::function<void(CStack*)>		sMainStackChangedBlock;
};

typedef CRefCountedObjectRef<CStack>	CStackRef;

}

#endif /* defined(__Stacksmith__CStack__) */
