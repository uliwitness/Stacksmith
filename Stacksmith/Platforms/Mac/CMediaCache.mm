//
//  CMediaCache.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-03-20.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMediaCache.h"
#include "CTinyXMLUtils.h"


using namespace Carlson;


static std::string		sStandardResourcesPath;


/*static*/ void		CMediaCache::SetStandardResourcesPath( const std::string &inStdResPath )
{
	sStandardResourcesPath = inStdResPath;
}


void	CMediaCache::SaveMediaElementsToElement( tinyxml2::XMLElement *stackfile )
{
	for( auto currEntry : mMediaList )
	{
		if( currEntry.IsBuiltIn() )
			continue;
		
		currEntry.CreateMediaElementInElement( stackfile );
	}
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
			fileName.append( "/unknown_" );
			break;
	}
	char	numStr[100] = {0};
	snprintf(numStr, sizeof(numStr)-1, "%lld", inID );
	fileName.append(numStr);
	fileName.append(1, '.');
	fileName.append(inSuffix);
	mMediaList.push_back( CMediaEntry( inID, inName, fileName, inType, xHotSpot, yHotSpot, isBuiltIn, true ) );
	
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
	}
}


void	CMediaCache::LoadMediaTableFromElementAsBuiltIn( tinyxml2::XMLElement * root, bool isBuiltIn )
{
	tinyxml2::XMLElement	*	currMediaElem = root->FirstChildElement( "media" );
	while( currMediaElem )
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
				fileName = mURL + "/" + fileName;
			}
			
			mMediaList.push_back( CMediaEntry( iconID, iconName, fileName, mediaType, hotspotLeft, hotspotTop, isBuiltIn ) );
		}
		
		currMediaElem = currMediaElem->NextSiblingElement( "media" );
	}

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
			break;
	}
	
	CTinyXMLUtils::SetLongLongAttributeNamed( mediaElement, GetID(), "id" );
	
	tinyxml2::XMLElement*	nameElem = stackfile->GetDocument()->NewElement("name");
	nameElem->SetText(GetName().c_str());
	mediaElement->InsertEndChild( nameElem );

	tinyxml2::XMLElement*	fileElem = stackfile->GetDocument()->NewElement("file");
	fileElem->SetText(GetFileName().c_str());
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
		tinyxml2::XMLElement*	contentElem = stackfile->GetDocument()->NewElement("content");
		contentElem->SetAttribute( "name", GetName().c_str() );
		tinyxml2::XMLText*	cdata = stackfile->GetDocument()->NewText( [[mFileData base64EncodedStringWithOptions: NSDataBase64Encoding76CharacterLineLength | NSDataBase64EncodingEndLineWithLineFeed] UTF8String] );
		contentElem->InsertEndChild( cdata );
		mediaElement->InsertEndChild( contentElem );
	}
	
	stackfile->InsertEndChild( mediaElement );
}


void	CMediaCache::Dump( size_t inIndent )
{
	for( auto itty = mMediaList.begin(); itty != mMediaList.end(); itty++ )
		itty->Dump( inIndent );
}
