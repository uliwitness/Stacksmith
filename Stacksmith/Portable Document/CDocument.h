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
	EMediaTypeIcon,
	EMediaTypePicture,
	EMediaTypeCursor,
	EMediaTypeSound
} TMediaType;


class CMediaEntry
{
public:
	CMediaEntry() : mIconID(0LL), mMediaType(EMediaTypeUnknown), mHotspotLeft(0), mHotspotTop(0), mIsBuiltIn(false) {};
	CMediaEntry( WILDObjectID iconID, const std::string iconName, const std::string fileName, TMediaType mediaType, int hotspotLeft, int hotspotTop, bool isBuiltIn ) : mIconID(iconID), mIconName(iconName), mFileName(fileName), mMediaType(mediaType), mHotspotLeft(hotspotLeft), mHotspotTop(hotspotTop), mIsBuiltIn(isBuiltIn) {};
	
	void	Dump( size_t inIndentLevel = 0 )	{ const char* indentStr = CRefCountedObject::IndentString( inIndentLevel ); printf("%s{ id = %lld, name = %s, file = %s, type = %u, hotspot = %d,%d, builtIn = %s }\n", indentStr, mIconID, mIconName.c_str(), mFileName.c_str(), mMediaType, mHotspotLeft, mHotspotTop, (mIsBuiltIn ? "true" : "false")); };
	
	WILDObjectID		GetID()	const		{ return mIconID; };
	const std::string	GetName() const		{ return mIconName; };
	TMediaType			GetMediaType() const{ return mMediaType; };
	const std::string	GetFileName() const { return mFileName; };
	
protected:
	WILDObjectID	mIconID;
	std::string		mIconName;
	std::string		mFileName;
	TMediaType		mMediaType;
	int				mHotspotLeft;
	int				mHotspotTop;
	bool			mIsBuiltIn;
};


class CTextStyleEntry
{
public:
	CTextStyleEntry() : mFontSize(12), mTextStyle(EPartTextStylePlain) {};
	CTextStyleEntry( std::string inFontName, int inFontSize, TPartTextStyle inTextStyle ) : mFontName(inFontName), mFontSize(inFontSize), mTextStyle(inTextStyle) {};

	void	Dump( size_t inIndentLevel = 0 )	{ const char* indentStr = CRefCountedObject::IndentString( inIndentLevel ); printf("%s{ font = %s, size = %d, style = %u }\n", indentStr, mFontName.c_str(), mFontSize, mTextStyle); };

protected:
	std::string		mFontName;
	int				mFontSize;
	TPartTextStyle	mTextStyle;
};


class CDocument
{
public:
	static void		SetStandardResourcesPath( const std::string& inStdResPath );

	CDocument() : mLoaded(false), mLoading(false), mMediaIDSeed(128), mStackIDSeed(1), mContextGroup(NULL) {};
	virtual ~CDocument();
	
	void				LoadFromURL( const std::string inURL, std::function<void(CDocument*)> inCompletionBlock );
	
	virtual CStack*		NewStackWithURLIDNameForDocument( const std::string& inURL, WILDObjectID inID, const std::string& inName, CDocument * inDocument );
	
	std::string			GetURL()					{ return mURL; };
	CStack*				GetStack( size_t inIndex )	{ if( inIndex >= mStacks.size() ) return NULL; return mStacks[inIndex]; };
	CStack*				GetStackByName( const char* inName );
	WILDObjectID		GetUniqueIDForStack();
	WILDObjectID		GetUniqueIDForMedia();
	
	std::string			GetMediaURLByNameOfType( const std::string& inName, TMediaType inType );
	
	LEOContextGroup*	GetScriptContextGroupObject();
	
	virtual void		Dump();

protected:
	void				LoadMediaTableFromElementAsBuiltIn( tinyxml2::XMLElement * root, bool isBuiltIn );

	bool											mLoaded;
	bool											mLoading;
	std::string										mCreatedByVersion;
	std::string										mLastCompactedVersion;
	std::string										mFirstEditedVersion;
	std::string										mLastEditedVersion;
	std::string										mURL;
	std::map<int,std::string>						mFontIDTable;
	std::map<int,CTextStyleEntry>					mTextStyles;
	std::vector<CMediaEntry>						mMediaList;
	std::vector<CStackRef>							mStacks;
	std::vector<std::function<void(CDocument*)>>	mLoadCompletionBlocks;
	
	WILDObjectID									mStackIDSeed;
	WILDObjectID									mMediaIDSeed;
	
	LEOContextGroup*								mContextGroup;
};

}

#endif /* defined(__Stacksmith__CDocument__) */
