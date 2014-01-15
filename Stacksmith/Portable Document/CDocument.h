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
#include "CStyleSheet.h"


namespace Carlson {

typedef enum
{
	EMediaTypeUnknown = 0,
	EMediaTypeIcon,
	EMediaTypePicture,
	EMediaTypeCursor,
	EMediaTypeSound
} TMediaType;


class CMediaEntry
{
public:
	CMediaEntry() : mIconID(0LL), mMediaType(EMediaTypeUnknown), mHotspotLeft(0), mHotspotTop(0), mIsBuiltIn(false) {};
	CMediaEntry( ObjectID iconID, const std::string iconName, const std::string fileName, TMediaType mediaType, int hotspotLeft, int hotspotTop, bool isBuiltIn ) : mIconID(iconID), mIconName(iconName), mFileName(fileName), mMediaType(mediaType), mHotspotLeft(hotspotLeft), mHotspotTop(hotspotTop), mIsBuiltIn(isBuiltIn) {};
	
	void	Dump( size_t inIndentLevel = 0 )	{ const char* indentStr = CRefCountedObject::IndentString( inIndentLevel ); printf("%s{ id = %lld, name = %s, file = %s, type = %u, hotspot = %d,%d, builtIn = %s }\n", indentStr, mIconID, mIconName.c_str(), mFileName.c_str(), mMediaType, mHotspotLeft, mHotspotTop, (mIsBuiltIn ? "true" : "false")); };
	
	ObjectID			GetID()	const		{ return mIconID; };
	const std::string	GetName() const		{ return mIconName; };
	TMediaType			GetMediaType() const{ return mMediaType; };
	const std::string	GetFileName() const { return mFileName; };
	
protected:
	ObjectID	mIconID;
	std::string		mIconName;
	std::string		mFileName;
	TMediaType		mMediaType;
	int				mHotspotLeft;
	int				mHotspotTop;
	bool			mIsBuiltIn;
};


class CDocument : public CRefCountedObject
{
public:
	static void		SetStandardResourcesPath( const std::string& inStdResPath );

	CDocument() : mLoaded(false), mLoading(false), mMediaIDSeed(128), mStackIDSeed(1), mContextGroup(NULL) {};
	
	void				LoadFromURL( const std::string inURL, std::function<void(CDocument*)> inCompletionBlock );
	
	virtual CStack*		NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, CDocument * inDocument );
	
	std::string			GetURL()					{ return mURL; };
	CStack*				GetStack( size_t inIndex )	{ if( inIndex >= mStacks.size() ) return NULL; return mStacks[inIndex]; };
	CStack*				GetStackByName( const char* inName );
	ObjectID			GetUniqueIDForStack();
	ObjectID			GetUniqueIDForMedia();
	
	virtual void		SetPeeking( bool inState );
	virtual bool		GetPeeking()				{ return mPeeking; };
	
	std::string			GetMediaURLByNameOfType( const std::string& inName, TMediaType inType );
	std::string			GetMediaURLByIDOfType( ObjectID, TMediaType inType );
	
	LEOContextGroup*	GetScriptContextGroupObject();
	
	const CStyleSheet&	GetStyles()		{ return mStyles; };
	
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
	std::string										mURL;
	std::vector<CMediaEntry>						mMediaList;
	std::vector<CStackRef>							mStacks;
	CStyleSheet										mStyles;
	std::vector<std::function<void(CDocument*)>>	mLoadCompletionBlocks;
	bool											mPeeking;
	
	ObjectID										mStackIDSeed;
	ObjectID										mMediaIDSeed;
	
	LEOContextGroup*								mContextGroup;
};

typedef CRefCountedObjectRef<CDocument>		CDocumentRef;

}

#endif /* defined(__Stacksmith__CDocument__) */
