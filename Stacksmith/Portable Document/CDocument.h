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


namespace Carlson {

typedef enum
{
	EMediaTypeUnknown = 0,
	EMediaTypeIcon,			// Preferred image type to use for images in new stacks.
	EMediaTypePicture,		// Compatibility image type used for PICT resources.
	EMediaTypeCursor,		// Compatibility image type used for CURS resources.
	EMediaTypeSound,		// Preferred media type for sounds in new stacks.
	EMediaTypePattern,		// Compatibility image type used for the 40 patterns in a HyperCard stack.
	EMediaTypeMovie			// Preferred media type to use for movies embedded in new stacks.
} TMediaType;


class CMediaEntry
{
public:
	CMediaEntry() : mIconID(0LL), mMediaType(EMediaTypeUnknown), mHotspotLeft(0), mHotspotTop(0), mIsBuiltIn(false), mChangeCount(0) {};
	CMediaEntry( ObjectID iconID, const std::string& iconName, const std::string& fileName, TMediaType mediaType, int hotspotLeft, int hotspotTop, bool isBuiltIn ) : mIconID(iconID), mIconName(iconName), mFileName(fileName), mMediaType(mediaType), mHotspotLeft(hotspotLeft), mHotspotTop(hotspotTop), mIsBuiltIn(isBuiltIn), mChangeCount(0) {};
	
	void	Dump( size_t inIndentLevel = 0 )	{ const char* indentStr = CRefCountedObject::IndentString( inIndentLevel ); printf("%s{ id = %lld, name = %s, file = %s, type = %u, hotspot = %d,%d, builtIn = %s, needsToBeSaved = %s }\n", indentStr, mIconID, mIconName.c_str(), mFileName.c_str(), mMediaType, mHotspotLeft, mHotspotTop, (mIsBuiltIn ? "true" : "false"), ((mChangeCount != 0) ? "true" : "false")); };
	
	ObjectID			GetID()	const		{ return mIconID; };
	const std::string	GetName() const		{ return mIconName; };
	TMediaType			GetMediaType() const{ return mMediaType; };
	const std::string	GetFileName() const { return mFileName; };
	int					GetHotspotLeft() const	{ return mHotspotLeft; };
	int					GetHotspotTop() const	{ return mHotspotTop; };
	bool				IsBuiltIn() const		{ return mIsBuiltIn; };
	
	void				IncrementChangeCount()	{ mChangeCount++; };
	bool				GetNeedsToBeSaved()		{ return mChangeCount != 0; };
	
protected:
	ObjectID		mIconID;
	std::string		mIconName;
	std::string		mFileName;
	TMediaType		mMediaType;
	int				mHotspotLeft;
	int				mHotspotTop;
	bool			mIsBuiltIn;
	size_t			mChangeCount;
};


class CDocument : public CRefCountedObject
{
public:
	static void		SetStandardResourcesPath( const std::string& inStdResPath );

	CDocument() : mLoaded(false), mLoading(false), mMediaIDSeed(128), mStackIDSeed(1), mCardIDSeed(3000), mBackgroundIDSeed(1000), mContextGroup(NULL), mUserLevel(5), mPrivateAccess(false), mCantPeek(false), mChangeCount(0) {};
	
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
	
	ObjectID			GetUniqueIDForStack();
	ObjectID			GetUniqueIDForCard();
	ObjectID			GetUniqueIDForBackground();
	ObjectID			GetUniqueIDForMedia();
	
	virtual void		SetPeeking( bool inState );
	virtual bool		GetPeeking()				{ return mPeeking; };
	
	std::string			GetMediaURLByNameOfType( const std::string& inName, TMediaType inType, int *outHotspotLeft = NULL, int *outHotspotTop = NULL );
	std::string			GetMediaURLByIDOfType( ObjectID inID, TMediaType inType, int *outHotspotLeft = NULL, int *outHotspotTop = NULL );
	size_t				GetNumMediaOfType( TMediaType inType );
	ObjectID			GetIDOfMediaOfTypeAtIndex( TMediaType inType, size_t inIndex );
	std::string			GetMediaNameByIDOfType( ObjectID inID, TMediaType inType );
	bool				GetMediaIsBuiltInByIDOfType( ObjectID inID, TMediaType inType );
	std::string			AddMediaWithIDTypeNameSuffixHotSpotIsBuiltInReturningURL( ObjectID inID, TMediaType inType, const std::string& inName, const char* inSuffix, int xHotSpot = 0, int yHotSpot = 0, bool isBuiltIn = false );
	
	LEOContextGroup*	GetScriptContextGroupObject();

	virtual void		IncrementChangeCount()	{ mChangeCount++; };
	virtual bool		GetNeedsToBeSaved();
	
	virtual void		Dump( size_t inNestingLevel = 0 );

protected:
	virtual ~CDocument();

	void				CallAllCompletionBlocks();

	void				LoadMediaTableFromElementAsBuiltIn( tinyxml2::XMLElement * root, bool isBuiltIn );

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
	std::vector<CMediaEntry>						mMediaList;
	std::vector<CStackRef>							mStacks;
	std::vector<std::function<void(CDocument*)>>	mLoadCompletionBlocks;
	bool											mPeeking;
	
	ObjectID										mStackIDSeed;
	ObjectID										mCardIDSeed;
	ObjectID										mBackgroundIDSeed;
	ObjectID										mMediaIDSeed;
	size_t											mChangeCount;
	
	LEOContextGroup*								mContextGroup;
};

typedef CRefCountedObjectRef<CDocument>		CDocumentRef;

}

#endif /* defined(__Stacksmith__CDocument__) */
