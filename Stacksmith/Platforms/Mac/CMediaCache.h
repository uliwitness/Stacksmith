//
//  CMediaCache.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-03-20.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMediaCache__
#define __Stacksmith__CMediaCache__

#include "CObjectID.h"
#include "CRefCountedObject.h"
#include "tinyxml2.h"
#include <string>
#include <functional>

#if __OBJC__
#import <Cocoa/Cocoa.h>
typedef NSImage*			WILDNSImagePtr;
typedef NSData*				WILDNSDataPtr;
typedef NSString*			WILDNSStringPtr;
#else
typedef struct NSImage*		WILDNSImagePtr;
typedef struct NSData*		WILDNSDataPtr;
typedef struct NSString*	WILDNSStringPtr;
#endif

namespace Carlson
{

enum
{
	EIncludeContent = true,
	EDontIncludeContent = false
};
typedef bool	TIncludeContentFlag;


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
	CMediaEntry();
	CMediaEntry( ObjectID iconID, const std::string& iconName, const std::string& fileName, TMediaType mediaType, int hotspotLeft, int hotspotTop, bool isBuiltIn, bool inDirty = false );
	CMediaEntry( const CMediaEntry& orig );
	~CMediaEntry();
	
	void	Dump( size_t inIndentLevel = 0 )	{ const char* indentStr = CRefCountedObject::IndentString( inIndentLevel ); printf("%s{ id = %lld, name = %s, file = %s, type = %u, hotspot = %d,%d, builtIn = %s, needsToBeSaved = %s }\n", indentStr, mIconID, mIconName.c_str(), mFileName.c_str(), mMediaType, mHotspotLeft, mHotspotTop, (mIsBuiltIn ? "true" : "false"), ((mChangeCount != 0) ? "true" : "false")); };
	
	ObjectID			GetID()	const			{ return mIconID; };
	void				SetID( ObjectID inID )	{ mIconID = inID; };	// Used when creating new icons (e.g. by pasting).
	const std::string	GetName() const		{ return mIconName; };
	TMediaType			GetMediaType() const{ return mMediaType; };
	const std::string	GetFileName() const { return mFileName; };
	int					GetHotspotLeft() const	{ return mHotspotLeft; };
	int					GetHotspotTop() const	{ return mHotspotTop; };
	bool				IsBuiltIn() const		{ return mIsBuiltIn; };
	
	void				IncrementChangeCount()	{ mChangeCount++; };
	bool				GetNeedsToBeSaved()		{ return mChangeCount != 0; };
	
	bool				LoadFromElement( tinyxml2::XMLElement* currMediaElem, const std::string& inDocumentPackageURL, bool isBuiltIn );
	void				CreateMediaElementInElement( tinyxml2::XMLElement * inElement, TIncludeContentFlag inIncludeContent = EDontIncludeContent );
	bool				SaveContents();	// Saves the actual data to the file, if loaded.
	
protected:
	ObjectID		mIconID;
	std::string		mIconName;
	std::string		mFileName;
	TMediaType		mMediaType;
	int				mHotspotLeft;
	int				mHotspotTop;
	bool			mIsBuiltIn;
	size_t			mChangeCount;
	WILDNSDataPtr	mFileData;
	WILDNSImagePtr	mImage;
	
	friend class CMediaCache;
};


class CMediaCache
{
public:
	CMediaCache( const std::string& inURL = std::string() ) : mMediaIDSeed(128), mURL(inURL)	{};

	void				SetURL( const std::string& inURL )	{ mURL = inURL; };
	std::string			GetURL()							{ return mURL; };
	
	bool				GetNeedsToBeSaved();
	
	ObjectID			GetUniqueIDForMedia();

	void				LoadStandardResources();
	void				LoadMediaTableFromElementAsBuiltIn( tinyxml2::XMLElement * root, bool isBuiltIn );
	
	std::string			GetMediaURLByNameOfType( const std::string& inName, TMediaType inType, int *outHotspotLeft = NULL, int *outHotspotTop = NULL );
	ObjectID			GetMediaIDByNameOfType( const std::string& inName, TMediaType inType );
	std::string			GetMediaURLByIDOfType( ObjectID inID, TMediaType inType, int *outHotspotLeft = NULL, int *outHotspotTop = NULL );
	size_t				GetNumMediaOfType( TMediaType inType );
	ObjectID			GetIDOfMediaOfTypeAtIndex( TMediaType inType, size_t inIndex );
	std::string			GetMediaNameByIDOfType( ObjectID inID, TMediaType inType );
	bool				GetMediaIsBuiltInByIDOfType( ObjectID inID, TMediaType inType );
	std::string			AddMediaWithIDTypeNameSuffixHotSpotIsBuiltInReturningURL( ObjectID inID, TMediaType inType, const std::string& inName, const char* inSuffix, int xHotSpot = 0, int yHotSpot = 0, bool isBuiltIn = false );
	void				GetMediaImageByIDOfType( ObjectID inID, TMediaType inType, std::function<void(WILDNSImagePtr)> completionBlock );
	ObjectID			GetUniqueMediaIDIfEntryOfTypeIsNoDuplicate( CMediaEntry& newEntry );	// Gives 0 to indicate identical item already exists, newEntry.GetID() if the ID already is unique.
	void				AddMediaEntry( const CMediaEntry& inEntry )	{ mMediaList.push_back( inEntry ); };
	
	bool				SaveMediaElementsToElement( tinyxml2::XMLElement * stackfile );	// In addition to doing XML, does what SaveMediaContents() does, too.
	bool				SaveMediaContents();
	void				SaveMediaToElement( ObjectID inID, TMediaType mediaType, tinyxml2::XMLElement * inElement );
	
	void				Dump( size_t inIndent );

	static void			SetStandardResourcesPath( const std::string &inStdResPath );

protected:
	bool				LoadSystemSoundsFromFolder( WILDNSStringPtr inFolderPath );


// ivars:
	ObjectID					mMediaIDSeed;
	std::vector<CMediaEntry>	mMediaList;
	std::string					mURL;
};

}

#endif /* defined(__Stacksmith__CMediaCache__) */
