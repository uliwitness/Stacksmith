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

class CDocument : public CRefCountedObject
{
public:
	CDocument() : mLoaded(false), mLoading(false), mStackIDSeed(1), mCardIDSeed(3000), mBackgroundIDSeed(1000), mContextGroup(NULL), mUserLevel(5), mPrivateAccess(false), mCantPeek(false), mChangeCount(0) {};
	
	void				LoadFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock );
	bool				Save();
	bool				CreateAtURL( const std::string& inURL );
	
	virtual CStack*		NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument );
	
	std::string			GetURL()					{ return mURL; };
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
	
	LEOContextGroup*	GetScriptContextGroupObject();

	virtual void		IncrementChangeCount()	{ mChangeCount++; };
	virtual bool		GetNeedsToBeSaved();
	
	virtual void		Dump( size_t inNestingLevel = 0 );

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

typedef CRefCountedObjectRef<CDocument>		CDocumentRef;

}

#endif /* defined(__Stacksmith__CDocument__) */
