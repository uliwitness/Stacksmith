//
//  CMediaCache.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-03-20.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMediaCache.h"
#include "CTinyXMLUtils.h"
#include "CURLConnection.h"


using namespace Carlson;


static std::string		sStandardResourcesPath;


/*static*/ void		CMediaCache::SetStandardResourcesPath( const std::string &inStdResPath )
{
	sStandardResourcesPath = inStdResPath;
}


bool	CMediaCache::SaveMediaElementsToElement( tinyxml2::XMLElement *stackfile )
{
	for( auto currEntry : mMediaList )
	{
		if( currEntry.IsBuiltIn() )
			continue;
		
		currEntry.CreateMediaElementInElement( stackfile );
		
		if( currEntry.GetNeedsToBeSaved() && !currEntry.SaveContents() )
			return false;
	}
	
	return true;
}


bool	CMediaCache::SaveMediaContents()
{
	for( auto currEntry : mMediaList )
	{
		if( currEntry.IsBuiltIn() )
			continue;
		
		if( currEntry.GetNeedsToBeSaved() && !currEntry.SaveContents() )
			return false;
	}
	
	return true;
}


void	CMediaCache::SaveMediaToElement( ObjectID inID, TMediaType inType, tinyxml2::XMLElement * inElement )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
		{
			currMedia->CreateMediaElementInElement( inElement, EIncludeContent );
			break;
		}
	}
	
	mChangeCount = 0;
}


ObjectID	CMediaCache::GetUniqueIDForMedia()
{
	bool	notUnique = true;
	
	while( notUnique )
	{
		notUnique = false;
		
		for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia ++ )
		{
			if( (*currMedia).GetID() == mMediaIDSeed )
			{
				notUnique = true;
				mMediaIDSeed++;
				break;
			}
		}
	}
	
	return mMediaIDSeed;
}


size_t		CMediaCache::GetNumMediaTypes( bool includeBuiltIn )
{
	size_t	numMediaTypes = 0;
	bool	haveMediaOfType[EMediaType_Last] = {0};
	
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( !includeBuiltIn && currMedia->IsBuiltIn() )
			continue;
		if( haveMediaOfType[currMedia->GetMediaType()] != true )
		{
			haveMediaOfType[currMedia->GetMediaType()] = true;
			numMediaTypes++;
		}
	}
	
	return numMediaTypes;
}


TMediaType	CMediaCache::GetMediaTypeAtIndex( size_t idx, bool includeBuiltIn )
{
	size_t	numMediaTypes = 0;
	bool	haveMediaOfType[EMediaType_Last] = {0};
	
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( !includeBuiltIn && currMedia->IsBuiltIn() )
			continue;
		if( haveMediaOfType[currMedia->GetMediaType()] != true )
		{
			haveMediaOfType[currMedia->GetMediaType()] = true;
			numMediaTypes++;
		}
	}
	
	size_t	currIdx = 0;
	for( size_t x = 0; x < EMediaType_Last; x++ )
	{
		if( haveMediaOfType[x] )
		{
			if( currIdx == idx )
				return (TMediaType)x;
			
			currIdx++;
		}
	}
	
	return EMediaTypeUnknown;
}


const char*	CMediaCache::GetNameOfType( TMediaType inType )
{
	static const char*	sTypeNames[EMediaType_Last] = {
#define _X(n)		#n,
		MEDIA_TYPES
#undef _X
	};
	
	return sTypeNames[inType];
}


std::string	CMediaCache::GetMediaURLByNameOfType( const std::string& inName, TMediaType inType, int *outHotspotLeft, int *outHotspotTop )
{
	const char*	str = inName.c_str();
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inType == currMedia->GetMediaType() && (strcasecmp( str, currMedia->GetName().c_str() ) == 0) )
		{
			if (outHotspotLeft) *outHotspotLeft = currMedia->GetHotspotLeft();
			if (outHotspotTop) *outHotspotTop = currMedia->GetHotspotTop();
			return currMedia->GetFileName();
		}
	}
	
	return std::string();
}


ObjectID	CMediaCache::GetMediaIDByNameOfType( const std::string& inName, TMediaType inType )
{
	const char*	str = inName.c_str();
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inType == currMedia->GetMediaType() && (strcasecmp( str, currMedia->GetName().c_str() ) == 0) )
		{
			return currMedia->GetID();
		}
	}
	
	return 0;
}


std::string	CMediaCache::GetMediaURLByIDOfType( ObjectID inID, TMediaType inType, int *outHotspotLeft, int *outHotspotTop )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
		{
			if (outHotspotLeft) *outHotspotLeft = currMedia->GetHotspotLeft();
			if (outHotspotTop) *outHotspotTop = currMedia->GetHotspotTop();
			return currMedia->GetFileName();
		}
	}
	
	return std::string();
}


bool	CMediaCache::DeleteMediaWithIDOfType( ObjectID inID, TMediaType inType )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
		{
			mMediaList.erase( currMedia );
			mChangeCount++;
			return true;
		}
	}
	
	return false;
}


size_t		CMediaCache::GetNumMediaOfType( TMediaType inType )
{
	if( inType == EMediaTypeUnknown )
		return mMediaList.size();
	
	size_t	numMedia = 0;
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( currMedia->GetMediaType() == inType )
			numMedia++;
	}
	
	return numMedia;
}


ObjectID	CMediaCache::GetIDOfMediaOfTypeAtIndex( TMediaType inType, size_t inIndex )
{
	if( inType == EMediaTypeUnknown )
		return mMediaList[inIndex].GetID();
	
	size_t	x = 0;
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( currMedia->GetMediaType() == inType )
		{
			if( x == inIndex )
				return currMedia->GetID();
			else
				x++;
		}
	}
	
	return 0;
}


std::string		CMediaCache::GetMediaNameByIDOfType( ObjectID inID, TMediaType inType )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
			return currMedia->GetName();
	}
	
	return std::string();
}


bool	CMediaCache::GetMediaIsBuiltInByIDOfType( ObjectID inID, TMediaType inType )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
			return currMedia->IsBuiltIn();
	}
	
	return false;
}


ObjectID	CMediaCache::GetUniqueMediaIDIfEntryOfTypeIsNoDuplicate( CMediaEntry& newEntry )
{
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( newEntry.GetID() == currMedia->GetID() && newEntry.GetMediaType() == currMedia->GetMediaType() )
		{
			if( currMedia->GetName().compare( newEntry.GetName() ) == 0
				&& currMedia->GetHotspotLeft() == newEntry.GetHotspotLeft()
				&& currMedia->GetHotspotTop() == newEntry.GetHotspotTop()
				&& [newEntry.mFileData isEqualTo: currMedia->mFileData] )
				return 0;
			else
				return GetUniqueIDForMedia();
		}
	}
	
	return newEntry.GetID();
}


void	CMediaCache::GetMediaImageByIDOfType( ObjectID inID, TMediaType inType, CImageGetterCallback completionBlock )
{
	NSCAssert( inType == EMediaTypeIcon || inType == EMediaTypePattern || inType == EMediaTypePicture || inType == EMediaTypeCursor, @"Requested image for non-image resource." );
	
	for( auto currMedia = mMediaList.begin(); currMedia != mMediaList.end(); currMedia++ )
	{
		if( inID == currMedia->GetID() && inType == currMedia->GetMediaType() )
		{
			if( currMedia->mPendingClients.size() > 0 )
			{
				currMedia->mPendingClients.push_back( completionBlock );
				break;
			}
			
			if( currMedia->mFileData == nil )
			{
				currMedia->mPendingClients.push_back( completionBlock );
				CURLRequest		request( currMedia->GetFileName() );
				CURLConnection::SendRequestWithCompletionHandler( request, [completionBlock,currMedia,inType](CURLResponse response, const char * data, size_t dataLen)
				{
					if( !currMedia->mFileData && dataLen > 0 )
					{
						currMedia->mFileData = [[NSData alloc] initWithBytes: data length: dataLen];
						assert( currMedia->mFileData != nil );
					}
					if( !currMedia->mImage && currMedia->mFileData )
						currMedia->mImage = [[NSImage alloc] initWithData: currMedia->mFileData];
					[currMedia->mImage setName: [NSString stringWithUTF8String: currMedia->GetFileName().c_str()].lastPathComponent];
					
					if( inType == EMediaTypeCursor && currMedia->mImage )
					{
						// Generate several pixel representations so we can use PDFs as cursors and they don't get rendered at the smallest pixellated scale:
						NSImage	*oldImage = currMedia->mImage;
						currMedia->mImage = [[NSImage alloc] initWithSize: [oldImage size]];
						
						for (int scale = 1; scale <= 4; scale++)
						{
							NSAffineTransform *xform = [[NSAffineTransform alloc] init];
							[xform scaleBy:scale];
							id hints = @{ NSImageHintCTM: xform };
							CGImageRef rasterCGImage = [oldImage CGImageForProposedRect:NULL context:nil hints:hints];
							NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:rasterCGImage];
							[rep setSize: [oldImage size]];
							[currMedia->mImage addRepresentation:rep];
						}
					}
					
					for( const CImageGetterCallback& currBlock : currMedia->mPendingClients )
					{
						currBlock( currMedia->mImage, currMedia->mHotspotLeft, currMedia->mHotspotTop );
					}
					currMedia->mPendingClients.erase( currMedia->mPendingClients.begin(), currMedia->mPendingClients.end() );
				});
				break;
			}
			else if( currMedia->mImage == nil )
			{
				currMedia->mImage = [[NSImage alloc] initWithData: currMedia->mFileData];
				[currMedia->mImage setName: [NSString stringWithUTF8String: currMedia->GetFileName().c_str()].lastPathComponent];
			}
			
			if( currMedia->mImage )
			{
				completionBlock( currMedia->mImage, currMedia->mHotspotLeft, currMedia->mHotspotTop );
				break;
			}
		}
	}
}


std::string		CMediaCache::AddMediaWithIDTypeNameSuffixHotSpotIsBuiltInReturningURL( ObjectID inID, TMediaType inType, const std::string& inName, const char* inSuffix, int xHotSpot, int yHotSpot, bool isBuiltIn )
{
	std::string		fileName( mURL );
	switch( inType )
	{
		case EMediaTypeIcon:
			fileName.append( "/icon_" );
			break;
		case EMediaTypePicture:
			fileName.append( "/picture_" );
			break;
		case EMediaTypeCursor:
			fileName.append( "/cursor_" );
			break;
		case EMediaTypeSound:
			fileName.append( "/sound_" );
			break;
		case EMediaTypePattern:
			fileName.append( "/pattern_" );
			break;
		case EMediaTypeMovie:
			fileName.append( "/movie_" );
			break;
		case EMediaTypeUnknown:
		case EMediaType_Last:
			fileName.append( "/unknown_" );
			break;
	}
	char	numStr[100] = {0};
	snprintf(numStr, sizeof(numStr)-1, "%lld", inID );
	fileName.append(numStr);
	fileName.append(1, '.');
	fileName.append(inSuffix);
	mMediaList.push_back( CMediaEntry( inID, inName, fileName, inType, xHotSpot, yHotSpot, isBuiltIn, true ) );
	
	mChangeCount++;
	
	return fileName;
}


bool	CMediaCache::GetNeedsToBeSaved()
{
	for( CMediaEntry& currMedia : mMediaList )
	{
		if( currMedia.GetNeedsToBeSaved() )
			return true;
	}
	
	return false;
}


void	CMediaCache::LoadStandardResources()
{
	if( sStandardResourcesPath.length() > 0 )
	{
		tinyxml2::XMLDocument		standardResDocument;
		
		if( tinyxml2::XML_SUCCESS == standardResDocument.LoadFile( sStandardResourcesPath.c_str() ) )
		{
			tinyxml2::XMLElement	*	standardResRoot = standardResDocument.RootElement();
			LoadMediaTableFromElementAsBuiltIn( standardResRoot, true );	// Load media built into the app.
		}
		
		// Add system sounds to our list of built-in sounds:
		LoadSystemSoundsFromFolder( @"/System/Library/Sounds" );
		LoadSystemSoundsFromFolder( [@"~/Library/Sounds" stringByExpandingTildeInPath] );
	}
}


bool	CMediaCache::LoadSystemSoundsFromFolder( WILDNSStringPtr inFolderPath )
{
	// Add system sounds to our list of built-in sounds:
	NSError		*	err = nil;
	NSArray		*	subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: inFolderPath error: &err];
	
	if( !subpaths )
	{
		NSLog( @"Error loading system sounds: %@", err );
		return false;
	}
	
	for( NSString* currSubPath in subpaths )
	{
		NSString*	currPath = [inFolderPath stringByAppendingPathComponent: currSubPath];
		CMediaEntry	newEntry( GetUniqueIDForMedia(), [currSubPath stringByDeletingPathExtension].UTF8String, currPath.UTF8String, EMediaTypeSound, 0, 0, true );
		mMediaList.push_back( newEntry );
	}
	
	return true;
}


void	CMediaCache::LoadMediaTableFromElementAsBuiltIn( tinyxml2::XMLElement * root, bool isBuiltIn )
{
	tinyxml2::XMLElement	*	currMediaElem = root->FirstChildElement( "media" );
	while( currMediaElem )
	{
		CMediaEntry	newEntry;
		if( newEntry.LoadFromElement( currMediaElem, mURL, isBuiltIn ) )
			mMediaList.push_back( newEntry );
		
		currMediaElem = currMediaElem->NextSiblingElement( "media" );
	}
}


void	CMediaCache::Dump( size_t inIndent )
{
	for( auto itty = mMediaList.begin(); itty != mMediaList.end(); itty++ )
		itty->Dump( inIndent );
}


CMediaEntry::CMediaEntry() : mIconID(0LL), mMediaType(EMediaTypeUnknown), mHotspotLeft(0), mHotspotTop(0), mIsBuiltIn(false), mChangeCount(0), mFileData(NULL), mImage(NULL), mLoading(false)
{

}


CMediaEntry::CMediaEntry( ObjectID iconID, const std::string& iconName, const std::string& fileName, TMediaType mediaType, int hotspotLeft, int hotspotTop, bool isBuiltIn, bool inDirty ) : mIconID(iconID), mIconName(iconName), mFileName(fileName), mMediaType(mediaType), mHotspotLeft(hotspotLeft), mHotspotTop(hotspotTop), mIsBuiltIn(isBuiltIn), mChangeCount(inDirty?1:0), mFileData(NULL), mImage(NULL), mLoading(false)
{

}


CMediaEntry::CMediaEntry( const CMediaEntry& orig )
{
	mIconID = orig.mIconID;
	mMediaType = orig.mMediaType;
	mHotspotLeft = orig.mHotspotLeft;
	mHotspotTop = orig.mHotspotTop;
	mIsBuiltIn = orig.mIsBuiltIn;
	mChangeCount = orig.mChangeCount;
	mFileName = orig.mFileName;
	mIconName = orig.mIconName;
	mFileData = [orig.mFileData retain];
	mImage = [orig.mImage retain];
	mLoading = false;
}


CMediaEntry&	CMediaEntry::operator =( const CMediaEntry& orig )
{
	mIconID = orig.mIconID;
	mMediaType = orig.mMediaType;
	mHotspotLeft = orig.mHotspotLeft;
	mHotspotTop = orig.mHotspotTop;
	mIsBuiltIn = orig.mIsBuiltIn;
	mChangeCount = orig.mChangeCount;
	mFileName = orig.mFileName;
	mIconName = orig.mIconName;
	mFileData = [orig.mFileData retain];
	mImage = [orig.mImage retain];
	mLoading = false;
	
	return *this;
}


CMediaEntry::~CMediaEntry()
{
	if( mFileData )
		[mFileData release];
	if( mImage )
		[mImage release];
}


bool	CMediaEntry::SaveContents()
{
	if( mFileName.find("file:///") != 0 )
		return false;
		
	if( mFileData )
	{
		NSURL*	fileURL = [NSURL URLWithString: [NSString stringWithUTF8String: GetFileName().c_str()]];
		return [mFileData writeToURL: fileURL atomically: YES];
	}
	
	return true;
}


void	CMediaEntry::CreateMediaElementInElement( tinyxml2::XMLElement* stackfile, TIncludeContentFlag inIncludeContent )
{
	tinyxml2::XMLElement*	mediaElement = stackfile->GetDocument()->NewElement("media");
	const char*				mediaTypeStr = NULL;
	switch( GetMediaType() )
	{
		case EMediaTypeCursor:
			mediaTypeStr = "cursor";
			break;
		case EMediaTypeIcon:
			mediaTypeStr = "icon";
			break;
		case EMediaTypeSound:
			mediaTypeStr = "sound";
			break;
		case EMediaTypePicture:
			mediaTypeStr = "picture";
			break;
		case EMediaTypePattern:
			mediaTypeStr = "pattern";
			break;
		case EMediaTypeMovie:
			mediaTypeStr = "movie";
			break;
		case EMediaTypeUnknown:
		case EMediaType_Last:
			break;
	}
	
	CTinyXMLUtils::AddLongLongNamed( mediaElement, GetID(), "id" );
	
	tinyxml2::XMLElement*	nameElem = stackfile->GetDocument()->NewElement("name");
	nameElem->SetText(GetName().c_str());
	mediaElement->InsertEndChild( nameElem );

	tinyxml2::XMLElement*	fileElem = stackfile->GetDocument()->NewElement("file");
	size_t		foundPos = GetFileName().rfind( '/' );
	if( foundPos == std::string::npos )
		foundPos = 0;
	else
		foundPos++;
	std::string	fileLeafName = GetFileName().substr(foundPos);
	fileElem->SetText(fileLeafName.c_str());
	mediaElement->InsertEndChild( fileElem );

	tinyxml2::XMLElement*	typeElem = stackfile->GetDocument()->NewElement("type");
	typeElem->SetText(mediaTypeStr);
	mediaElement->InsertEndChild( typeElem );
	
	if( GetMediaType() == EMediaTypeCursor )
	{
		CTinyXMLUtils::AddPointNamed( mediaElement, GetHotspotLeft(), GetHotspotTop(), "hotspot" );
	}
	
	if( inIncludeContent == EIncludeContent )
	{
        // +++ Copying from the background seems to crash because mFileData isn't loaded yet.
		tinyxml2::XMLElement*	contentElem = stackfile->GetDocument()->NewElement("content");
		tinyxml2::XMLText	*	cdata = stackfile->GetDocument()->NewText( [[mFileData base64EncodedStringWithOptions: NSDataBase64Encoding76CharacterLineLength | NSDataBase64EncodingEndLineWithLineFeed] UTF8String] );
		contentElem->InsertEndChild( cdata );
		mediaElement->InsertEndChild( contentElem );
	}
	
	stackfile->InsertEndChild( mediaElement );
}


bool	CMediaEntry::LoadFromElement( tinyxml2::XMLElement* currMediaElem, const std::string& inDocumentPackageURL, bool isBuiltIn )
{
	ObjectID	iconID = CTinyXMLUtils::GetLongLongNamed( currMediaElem, "id", 0 );
	std::string	iconName;
	CTinyXMLUtils::GetStringNamed( currMediaElem, "name", iconName );
	std::string	fileName;
	CTinyXMLUtils::GetStringNamed( currMediaElem, "file", fileName );
	if( fileName.find( "../" ) != 0 && fileName.find( "/../" ) == std::string::npos )	// Don't let paths escape the file package.
	{
		std::string	typeName;
		TMediaType	mediaType = EMediaTypeUnknown;
		CTinyXMLUtils::GetStringNamed( currMediaElem, "type", typeName );
		if( typeName.compare( "icon" ) == 0 )
			mediaType = EMediaTypeIcon;
		else if( typeName.compare( "picture" ) == 0 )
			mediaType = EMediaTypePicture;
		else if( typeName.compare( "cursor" ) == 0 )
			mediaType = EMediaTypeCursor;
		else if( typeName.compare( "sound" ) == 0 )
			mediaType = EMediaTypeSound;
		else if( typeName.compare( "pattern" ) == 0 )
			mediaType = EMediaTypePattern;
		else if( typeName.compare( "movie" ) == 0 )
			mediaType = EMediaTypeMovie;
		tinyxml2::XMLElement	*	hotspotElem = currMediaElem->FirstChildElement( "hotspot" );
		int		hotspotLeft = CTinyXMLUtils::GetIntNamed( hotspotElem, "left", 0 );
		int		hotspotTop = CTinyXMLUtils::GetIntNamed( hotspotElem, "top", 0 );
		
		if( isBuiltIn )
		{
			size_t	slashPos = sStandardResourcesPath.rfind('/');
			std::string	builtInResPath = sStandardResourcesPath.substr(0,slashPos);
			fileName = std::string("file://") + builtInResPath + "/" + fileName;
		}
		else
		{
			fileName = inDocumentPackageURL + "/" + fileName;
		}

		tinyxml2::XMLElement	*	contentElem = currMediaElem->FirstChildElement( "content" );
		if( contentElem )
		{
			mFileData = [[NSData alloc] initWithBase64EncodedData: [NSData dataWithBytes: contentElem->GetText() length: strlen(contentElem->GetText())] options: NSDataBase64DecodingIgnoreUnknownCharacters];
			assert(mFileData != nil);
		}
		mIconID = iconID;
		mIconName = iconName;
		mFileName = fileName;
		mMediaType = mediaType;
		mHotspotLeft = hotspotLeft;
		mHotspotTop = hotspotTop;
		mIsBuiltIn = isBuiltIn;
		
		return true;
	}
	
	return false;
}
