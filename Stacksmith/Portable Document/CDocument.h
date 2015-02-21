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


namespace Carlson {

typedef CRefCountedObjectRef<CDocument>		CDocumentRef;

class CDocumentManager	// Subclass this and instantiate it at startup. First subclass instantiated wins & becomes the shared singleton.
{
public:
	CDocumentManager();
	virtual ~CDocumentManager()	{};
	
	virtual void	OpenDocumentFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock ) = 0;
	
	virtual void	AddDocument( CDocumentRef inDocument )	{ mOpenDocuments.push_back(inDocument); };
	virtual void	CloseDocument( CDocumentRef inDocument );
	virtual void	SetPeeking( bool inState );
	virtual void	SaveAll();
	virtual bool	HaveDocuments()							{ return mOpenDocuments.size() > 0; };
	virtual void	Quit()									= 0;
	
	virtual void	SetFrontDocument( CDocument* inDocument );
	CDocument*		GetFrontDocument()							{ return mFrontDocument; };
	
	static CDocumentManager*	GetSharedDocumentManager();

protected:
	std::vector<CDocumentRef>	mOpenDocuments;
	CDocument*					mFrontDocument;
	
	static CDocumentManager*	sSharedDocumentManager;
};


class CDocument : public CRefCountedObject
{
public:
	CDocument() : mLoaded(false), mLoading(false), mStackIDSeed(1), mCardIDSeed(3000), mBackgroundIDSeed(1000), mContextGroup(NULL), mUserLevel(5), mPrivateAccess(false), mCantPeek(false), mChangeCount(0), mWriteProtected(false) {};
	
	void				LoadFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock );
	bool				Save();
	bool				CreateAtURL( const std::string& inURL );
	
	virtual CStack*		NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument );
	
	std::string			GetURL()							{ return mURL; };
	void				SetURL( const std::string& inURL )	{ mURL = inURL; };
	CStack*				GetStack( size_t inIndex )	{ if( inIndex >= mStacks.size() ) return NULL; return mStacks[inIndex]; };
	CStack*				GetStackWithID( ObjectID inID );
	size_t				GetNumStacks()				{ return mStacks.size(); };
	CStack*				GetStackByName( const char* inName );
	CStack*				AddNewStack();
	bool				DeleteStack( CStack* inStack );
	CMediaCache&		GetMediaCache()				{ return mMediaCache; };
	
	ObjectID			GetUniqueIDForStack();
	ObjectID			GetUniqueIDForCard();
	ObjectID			GetUniqueIDForBackground();
	
	virtual void		SetPeeking( bool inState );
	virtual bool		GetPeeking()				{ return mPeeking; };
	
	virtual bool		IsWriteProtected()			{ return mWriteProtected; };
	virtual void		SetWriteProtected( bool n )	{ mWriteProtected = n; };
	
	virtual void		ShowStackCanvasWindow()	{};
	
	LEOContextGroup*	GetScriptContextGroupObject();

	virtual void		IncrementChangeCount()	{ mChangeCount++; };
	virtual bool		GetNeedsToBeSaved();
	virtual void		CheckIfWeShouldCloseCauseLastStackClosed();
	
	virtual void		Dump( size_t inNestingLevel = 0 );
	static std::string	PathFromFileURL( const std::string& inURL );


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
	bool											mPeeking;
	
	ObjectID										mStackIDSeed;
	ObjectID										mCardIDSeed;
	ObjectID										mBackgroundIDSeed;
	size_t											mChangeCount;
	
	CMediaCache										mMediaCache;
	
	LEOContextGroup*								mContextGroup;
};

}

#endif /* defined(__Stacksmith__CDocument__) */
