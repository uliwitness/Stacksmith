//
//  CDocument.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CDocument__
#define __Stacksmith__CDocument__

#include "LEOContextGroup.h"
#include "CStack.h"
#include "CVisiblePart.h"
#include "CMediaCache.h"
#include "CMenu.h"


namespace Carlson {

typedef CRefCountedObjectRef<CDocument>		CDocumentRef;

class CDocumentManager	// Subclass this and instantiate it at startup. First subclass instantiated wins & becomes the shared singleton.
{
public:
	CDocumentManager();
	virtual ~CDocumentManager()	{};
	
	virtual void	OpenDocumentFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock, const std::string& inEffectType, TVisualEffectSpeed inSpeed, LEOContextGroup* inGroup ) = 0;
	
	virtual void		AddDocument( CDocumentRef inDocument )	{ mOpenDocuments.push_back(inDocument); };
	virtual void		CloseDocument( CDocumentRef inDocument );
	virtual void		SetPeeking( bool inState );
	virtual void		SaveAll();
	virtual bool		HaveDocuments()							{ return mOpenDocuments.size() > 0; };
	virtual size_t		GetNumDocuments()						{ return mOpenDocuments.size(); }
	virtual CDocument*	GetDocument( size_t inIndex )			{ return mOpenDocuments[inIndex]; }
	virtual CDocument*	GetDocumentWithName( const std::string& inName );
	virtual void		Quit() = 0;
	
	virtual void	SetFrontDocument( CDocument* inDocument );
	CDocument*		GetFrontDocument()							{ return mFrontDocument; };
	
	static CDocumentManager*	GetSharedDocumentManager();

protected:
	std::vector<CDocumentRef>	mOpenDocuments;
	CDocument*					mFrontDocument;
	
	static CDocumentManager*	sSharedDocumentManager;
};


class CDocument : public CConcreteObject
{
public:
	CDocument( LEOContextGroup* inGroup = nullptr ) : mLoaded(false), mLoading(false), mStackIDSeed(1), mCardIDSeed(3000), mBackgroundIDSeed(1000), mMenuIDSeed(100), mContextGroup(inGroup), mUserLevel(5), mPrivateAccess(false), mCantPeek(false), mChangeCount(0), mWriteProtected(false) { if( mContextGroup ) LEOContextGroupRetain( mContextGroup ); };
	
	void				LoadFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock );
	bool				Save();
	bool				CreateAtURL( const std::string& inURL, const std::string inNameForUser = "" );
	void				SaveThumbnailsForOpenStacks();
	
	virtual CDocument*	GetDocument() override				{ return this; }
	
	virtual CStack*		NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument );
	
	std::string			GetURL()							{ return mURL; };
	void				SetURL( const std::string& inURL )	{ mURL = inURL; };
	virtual CStack*		GetStack() override					{ return nullptr; }
	CStack*				GetStack( size_t inIndex )	{ if( inIndex >= mStacks.size() ) return NULL; return mStacks[inIndex]; };
	CStack*				GetStackWithID( ObjectID inID );
	size_t				GetNumStacks()				{ return mStacks.size(); };
	CStack*				GetStackByName( const char* inName );
	CStack*				AddNewStack( std::string inNameForUser = "" );
	bool				DeleteStack( CStack* inStack );
	CMediaCache&		GetMediaCache()				{ return mMediaCache; };
	
	size_t				GetNumMenus()				{ return mMenus.size(); }
	CMenu*				GetMenu( size_t inIndex )	{ return mMenus[inIndex]; }
	CMenu*				GetMenuWithID( ObjectID inID );
	CMenu*				GetMenuWithName( const std::string& inName );
	virtual CMenu*		NewMenuWithElement( tinyxml2::XMLElement* inMenuXML );
	
	ObjectID			GetUniqueIDForStack();
	ObjectID			GetUniqueIDForCard();
	ObjectID			GetUniqueIDForBackground();
	ObjectID			GetUniqueIDForMenu();
	
	virtual void		SetPeeking( bool inState );
	virtual bool		GetPeeking()				{ return mPeeking; };
	
	virtual bool		IsWriteProtected()			{ return mWriteProtected; };
	virtual void		SetWriteProtected( bool n )	{ mWriteProtected = n; };
	
	virtual bool		GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue ) override;
	virtual bool		SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd ) override;

	virtual void		ShowStackCanvasWindow()	{};
	
	virtual LEOContextGroup*	GetScriptContextGroupObject() override;

	virtual void		IncrementChangeCount() override;
	virtual void		MenuIncrementedChangeCount( CMenu* inMenu )	{ IncrementChangeCount(); };
	virtual void		StackIncrementedChangeCount( CStack* inStack )	{}
	virtual void		LayerIncrementedChangeCount( CLayer* inLayer )	{}
	virtual bool		GetNeedsToBeSaved() override;
	virtual void		CheckIfWeShouldCloseCauseLastStackClosed();
	
	virtual void		Dump( size_t inNestingLevel = 0 ) override;
	static std::string	PathFromFileURL( const std::string& inURL );
	
	// "New Part" menu item list querying:
	static void			LoadNewPartMenuItemsFromFilePath( const char* inPath );
	static size_t		GetNewPartMenuItemCount();
	static std::string	GetNewPartMenuItemAtIndex( size_t inIndex );
	static std::string	GetNewPartTypeAtIndex( size_t inIndex );

protected:
	virtual ~CDocument();

	void				CallAllCompletionBlocks();

	bool											mLoaded;
	bool											mLoading;
	std::string										mCreatedByVersion;
	std::string										mLastCompactedVersion;
	std::string										mFirstEditedVersion;
	std::string										mLastEditedVersion;
	int												mUserLevel;
	bool											mPrivateAccess;
	bool											mCantPeek;
	bool											mWriteProtected;	// Disk locked or no write permissions?
	std::string										mURL;
	std::vector<CStackRef>							mStacks;
	std::vector<std::function<void(CDocument*)>>	mLoadCompletionBlocks;
	std::vector<CMenuRef>							mMenus;
	bool											mPeeking;
	
	ObjectID										mStackIDSeed;
	ObjectID										mCardIDSeed;
	ObjectID										mBackgroundIDSeed;
	ObjectID										mMenuIDSeed;
	size_t											mChangeCount;
	
	CMediaCache										mMediaCache;
	
	LEOContextGroup*								mContextGroup;
};

}

#endif /* defined(__Stacksmith__CDocument__) */
