//
//  CLayer.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CLayer.h"
#include "CURLConnection.h"
#include "CTinyXMLUtils.h"
#include "CPart.h"
#include "CPartContents.h"
#include "CStack.h"
#include "CButtonPart.h"
#include "CFieldPart.h"
#include "CRectanglePart.h"
#include "CPicturePart.h"
#include "CDocument.h"
#include <sys/stat.h>
#include <sstream>


using namespace Carlson;


CLayer::~CLayer()
{
	
}


void	CLayer::SetStack( CStack* inStack )
{
	mStack = inStack;
	if( mStack )
		mDocument = inStack->GetDocument();
}

void	CLayer::Load( std::function<void(CLayer*)> completionBlock )
{
	if( mLoaded )
	{
		completionBlock( this );
		return;
	}
	
	Retain();
	
	mLoadCompletionBlocks.push_back(completionBlock);
	
	if( !mLoading )	// If we're already loading, we've queued up our completion block which gets called when the async load has finished.
	{
		mLoading = true;
		CURLRequest		request( mURL );
		CURLConnection::SendRequestWithCompletionHandler( request, [this] (CURLResponse inResponse, const char* inData, size_t inDataLength) -> void
		{
			const char*					styleSheetFilename = NULL;
			tinyxml2::XMLDocument	*	document = new tinyxml2::XMLDocument();

			if( tinyxml2::XML_SUCCESS == document->Parse( inData, inDataLength ) )
			{
				//document->Print();

				tinyxml2::XMLElement	*	root = document->RootElement();
				
				LoadPropertiesFromElement( root );
				
				LoadUserPropertiesFromElement( root );

				// Load CSS built from font/style tables:
				tinyxml2::XMLElement	*	link = root->FirstChildElement( "link" );
				while( link )
				{
					const char*	relAttr = link->Attribute("rel");
					if( relAttr && strcmp(relAttr,"stylesheet") == 0 )
					{
						const char*	typeAttr = link->Attribute("type");
						if( typeAttr && strcmp(typeAttr,"text/css") == 0 )
						{
							styleSheetFilename = link->Attribute("href");
							if( styleSheetFilename )
								break;
						}
					}
					
					link = link->NextSiblingElement( "link" );
				}

				// Load parts:
				tinyxml2::XMLElement	*	currPartElem = root->FirstChildElement( "part" );
				while( currPartElem )
				{
					CPart	*	thePart = CPart::NewPartWithElement( currPartElem, this );
					thePart->Autorelease();
					mParts.push_back( thePart );
					thePart->Retain();	// Retain for the button families array.

					currPartElem = currPartElem->NextSiblingElement( "part" );
				}
				
				// Load AddColor info:
				LoadAddColorPartsFromElement( root );
				
				// Load script:
				mScript.erase();
				CTinyXMLUtils::GetStringNamed( root, "script", mScript );
			
				if( styleSheetFilename )
				{
					std::string		styleSheetURL( mURL );
					styleSheetURL.append(1,'/');
					styleSheetURL.append(styleSheetFilename);
					CURLRequest		styleSheetRequest( styleSheetURL );
					CURLConnection::SendRequestWithCompletionHandler( styleSheetRequest, [this,root,document](CURLResponse inStyleSheetResponse, const char* inStyleSheetData, size_t inStyleSheetDataLength)
					{
						mStyles.LoadFromStream( std::string( inStyleSheetData, inStyleSheetDataLength ) );
						//mStyles.Dump();
						
						// Load part contents:
						tinyxml2::XMLElement	*	currPartContentsElem = root->FirstChildElement( "content" );
						while( currPartContentsElem )
						{
							CPartContents	*	theContents = new CPartContents( this, currPartContentsElem );
							theContents->Autorelease();
							mContents.push_back( theContents );
							
							currPartContentsElem = currPartContentsElem->NextSiblingElement( "content" );
						}
						delete document;
						
						mChangeCount = 0;
						CallAllCompletionBlocks();
					} );
				}
				else
				{
					// Load part contents:
					tinyxml2::XMLElement	*	currPartContentsElem = root->FirstChildElement( "content" );
					while( currPartContentsElem )
					{
						CPartContents	*	theContents = new CPartContents( this, currPartContentsElem );
						theContents->Autorelease();
						mContents.push_back( theContents );
						
						currPartContentsElem = currPartContentsElem->NextSiblingElement( "content" );
					}
					delete document;
					
					mChangeCount = 0;
					CallAllCompletionBlocks();
				}
			}
			else
			{
				delete document;
				CallAllCompletionBlocks();
			}
		} );
	}
}


const char*	CLayer::GetLayerXMLType()
{
	return "layer";
}


void	CLayer::SavePropertiesToElementOfDocument( tinyxml2::XMLElement* stackfile, tinyxml2::XMLDocument* document )
{
	tinyxml2::XMLElement*	elem = document->NewElement("bitmap");
	elem->SetText( mPictureName.c_str() );
	stackfile->InsertEndChild(elem);

	elem = document->NewElement("cantDelete");
	elem->SetBoolFirstChild( mCantDelete );
	stackfile->InsertEndChild(elem);

	elem = document->NewElement("showPict");
	elem->SetBoolFirstChild( mShowPict );
	stackfile->InsertEndChild(elem);

	elem = document->NewElement("dontSearch");
	elem->SetBoolFirstChild( mDontSearch );
	stackfile->InsertEndChild(elem);
}


void	CLayer::Save( const std::string& inPackagePath )
{
	if( !mLoaded )
		return;
	
	tinyxml2::XMLDocument		document;
	tinyxml2::XMLDeclaration*	declaration = document.NewDeclaration();
	declaration->SetValue("xml version=\"1.0\" encoding=\"utf-8\"");
	document.InsertEndChild( declaration );
	
	std::string		dtdContents("DOCTYPE ");
	dtdContents.append(GetLayerXMLType());
	dtdContents.append(" PUBLIC \"-//Apple, Inc.//DTD ");
	dtdContents.append(GetLayerXMLType());
	dtdContents.append(" V 2.0//EN\" \"\"");
	tinyxml2::XMLUnknown*	dtd = document.NewUnknown(dtdContents.c_str());
	document.InsertEndChild( dtd );
	
	tinyxml2::XMLElement*		elem = NULL;
	tinyxml2::XMLElement*		stackfile = document.NewElement(GetLayerXMLType());
	document.InsertEndChild( stackfile );

	CTinyXMLUtils::AddLongLongNamed( stackfile, mID, "id" );
	
	SavePropertiesToElementOfDocument( stackfile, &document );
	
	tinyxml2::XMLNode*	lastChildBeforeStyles = stackfile->LastChild();
	// We remember lastChildBeforeStyles so we can later insert a "link" tag referencing our CSS here, if needed.
	
	CStyleSheet	theStyles;

	for( auto currPart : mParts )
	{
		elem = document.NewElement("part");
		currPart->SaveToElementOfDocument( elem, &document );
		stackfile->InsertEndChild(elem);
	}
	
	for( auto currContent : mContents )
	{
		elem = document.NewElement("content");
		currContent->SaveToElementOfDocumentStyleSheet( elem, &document, &theStyles );
		stackfile->InsertEndChild(elem);
	}
	
	elem = document.NewElement("name");
	elem->SetText( mName.c_str() );
	stackfile->InsertEndChild(elem);

	elem = document.NewElement("script");
	elem->SetForceCompactMode(true);
	elem->SetText( mScript.c_str() );
	stackfile->InsertEndChild(elem);

	SaveUserPropertiesToElementOfDocument( stackfile, &document );

	std::string	styleSheet = theStyles.GetCSS();
	if( styleSheet.length() > 0 )
	{
		std::string	destStylesPath(inPackagePath);
		std::stringstream	destStylesName;
		destStylesName << "stylesheet_card_" << mID << ".css";
		destStylesPath.append(destStylesName.str());
		
		elem = document.NewElement("link");
		elem->SetAttribute("rel", "stylesheet");
		elem->SetAttribute("type", "text/css");
		elem->SetAttribute("name", destStylesName.str().c_str());
		stackfile->InsertAfterChild(lastChildBeforeStyles,elem);
		
		FILE*	theFile = fopen( destStylesPath.c_str(), "w" );
		fwrite( styleSheet.c_str(), styleSheet.size(), 1, theFile );
		fclose( theFile );
	}

	std::string	destPath(inPackagePath);
	destPath.append( mFileName );
	document.SaveFile( destPath.c_str(), false );
	
	mChangeCount = 0;
}


CPartContents*	CLayer::GetPartContentsByID( ObjectID inID, bool isForBackgroundPart )
{
	for( auto itty = mContents.begin(); itty != mContents.end(); itty++ )
	{
		if( (**itty).GetID() == inID && (**itty).IsOnBackground() == isForBackgroundPart )
			return *itty;
	}
	
	return NULL;
}


void	CLayer::AddPartContents( CPartContents* inContents )
{
	mContents.push_back( inContents );
	IncrementChangeCount();
}


void	CLayer::CallAllCompletionBlocks()	// Can override this in cards to also load the background if needed and only *then* call completion blocks.
{
	mLoaded = true;
	mLoading = false;
	
	// Call all completion blocks:
	for( auto itty = mLoadCompletionBlocks.begin(); itty != mLoadCompletionBlocks.end(); itty++ )
		(*itty)(this);
	mLoadCompletionBlocks.clear();
			
	Release();
}


void	CLayer::LoadPropertiesFromElement( tinyxml2::XMLElement* root )
{
	// We get id and name from the TOC.xml via the constructor
	mShowPict = CTinyXMLUtils::GetBoolNamed( root, "showPict", true );
	mCantDelete = CTinyXMLUtils::GetBoolNamed( root, "cantDelete", false );
	mDontSearch = CTinyXMLUtils::GetBoolNamed( root, "dontSearch", false );
	mPictureName = "";
	CTinyXMLUtils::GetStringNamed( root, "bitmap", mPictureName );
}


CPart*	CLayer::GetPartWithID( ObjectID inID )
{
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		if( (*currPart)->GetID() == inID )
			return *currPart;
	}
	
	return NULL;
}


size_t	CLayer::GetPartCountOfType( CPartCreatorBase* inType )
{
	if( inType == NULL )
		return mParts.size();
	
	size_t	numParts = 0;
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		if( (*currPart)->GetPartType() == inType )
			numParts++;
	}
	
	return numParts;
}


CPart*	CLayer::GetPartOfType( size_t inIndex, CPartCreatorBase* inType )
{
	if( inType == NULL )
	{
		if( inIndex >= mParts.size() )
			return NULL;
		return mParts[inIndex];
	}
	
	size_t	currIndex = 0;
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		if( (*currPart)->GetPartType() == inType )
		{
			if( currIndex == inIndex )
				return *currPart;
			currIndex++;
		}
	}
	
	return NULL;
}


CPart*	CLayer::GetPartWithNameOfType( const std::string& inName, CPartCreatorBase* inType )
{
	size_t	currIndex = 0;
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		if( inType == NULL || (*currPart)->GetPartType() == inType )
		{
			if( strcasecmp(inName.c_str(), (*currPart)->GetName().c_str()) == 0 )
				return *currPart;
			currIndex++;
		}
	}
	
	return NULL;
}


void	CLayer::LoadAddColorPartsFromElement( tinyxml2::XMLElement* root )
{
	tinyxml2::XMLElement	* theObject = root->FirstChildElement( "addcolorobject" );
	
	for( ; theObject != NULL; theObject = theObject->NextSiblingElement("addcolorobject") )
	{
		ObjectID	objectID = CTinyXMLUtils::GetLongLongNamed( theObject, "id" );
		int				objectBevel = CTinyXMLUtils::GetIntNamed( theObject, "bevel" );
		std::string		objectType;
		CTinyXMLUtils::GetStringNamed( theObject, "type", objectType );
		std::string		objectName;
		CTinyXMLUtils::GetStringNamed( theObject, "name", objectName );
		bool			objectTransparent = CTinyXMLUtils::GetBoolNamed( theObject, "transparent", false);
		bool			objectVisible = CTinyXMLUtils::GetBoolNamed( theObject, "visible", false);
		
		int				left = 0, top = 0, right = 100, bottom = 100;
		CTinyXMLUtils::GetRectNamed( theObject, "rect", &left, &top, &right, &bottom );
		int				red = 0, green = 0, blue = 0, alpha = 0;
		CTinyXMLUtils::GetColorNamed( theObject, "color", &red, &green, &blue, &alpha );
		
		if( objectType.compare("button") == 0 )
		{
			CButtonPart*	thePart = dynamic_cast<CButtonPart*>(GetPartWithID( objectID ));
			if( thePart )
			{
				thePart->SetFillColor( red, green, blue, alpha );
				thePart->SetBevelWidth( objectBevel );
				mAddColorParts.push_back( thePart );
			}
		}
		else if( objectType.compare("field") == 0 )
		{
			CFieldPart*	thePart = dynamic_cast<CFieldPart*>( GetPartWithID( objectID ) );
			if( thePart )
			{
				thePart->SetFillColor( red, green, blue, alpha );
				thePart->SetBevelWidth( objectBevel );
				mAddColorParts.push_back( thePart );
			}
		}
		else if( objectType.compare("rectangle") == 0 )
		{
			CRectanglePart*	thePart = new CRectanglePart( this );
			thePart->SetRect( left, top, right, bottom );
			thePart->SetFillColor( red, green, blue, alpha );
			thePart->SetBevelWidth( objectBevel );
			thePart->SetVisible( objectVisible );
			mAddColorParts.push_back( thePart );
		}
		else if( objectType.compare("picture") == 0 )
		{
			CPicturePart*	thePart = new CPicturePart( this );
			thePart->SetRect( left, top, right, bottom );
			thePart->SetMediaPath( objectName );
			thePart->SetTransparent( objectTransparent );
			thePart->SetVisible( objectVisible );
			mAddColorParts.push_back( thePart );
		}
	}
}


void	CLayer::WakeUp()
{
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		(*currPart)->WakeUp();
	}
}


void	CLayer::GoToSleep()
{
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		(*currPart)->GoToSleep();
	}
}


void    CLayer::AddPart( CPart* inPart )
{
    mParts.push_back( inPart );
}


LEOInteger	CLayer::GetIndexOfPart( CPart* inPart, CPartCreatorBase* inType )
{
	LEOInteger	numParts = 0;
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		if( (*currPart)->GetPartType() == inType || inType == NULL )
		{
			if( (*currPart) == inPart )
				return numParts;
			numParts++;
		}
	}
	
	return -1;
}


void	CLayer::SetIndexOfPart( CPart* inPart, LEOInteger inIndex, CPartCreatorBase* inType )
{
	CPartRef	keepPart = inPart;	// Make sure it doesn't get released while we're removing/re-adding it.
	LEOInteger	oldPartIndex = -1;
	LEOInteger	newPartIndex = inIndex;
	LEOInteger	numParts = 0;
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		if( (*currPart)->GetPartType() == inType || inType == NULL )
		{
			if( (*currPart) == inPart )
			{
				if( newPartIndex > numParts )
					newPartIndex --;
				oldPartIndex = numParts;
				break;
			}
			numParts++;
		}
	}
	
	mParts.erase( mParts.begin() +oldPartIndex );
	mParts.insert( mParts.begin() +newPartIndex, inPart );
}


ObjectID	CLayer::GetUniqueIDForPart()
{
	bool	isUnique = false;
	while( !isUnique )
	{
		isUnique = true;
		for( CPart* currPart : mParts )
		{
			if( currPart->GetID() == mPartIDSeed )
			{
				isUnique = false;
				mPartIDSeed++;
				break;
			}
		}
	}
	
	return mPartIDSeed;
}


void	CLayer::UnhighlightFamilyMembersOfPart( CPart* inPart )
{
	LEOInteger		theFamily = inPart->GetFamily();
	for( auto currPart : mParts )
	{
		if( currPart->GetFamily() == theFamily
			&& (currPart != inPart) )
			currPart->SetHighlight( false );
	}
}


void	CLayer::SetPeeking( bool inState )
{
	for( auto currPart : mParts )
	{
		currPart->SetPeeking( inState );
	}
}


std::string	CLayer::GetPictureURL()
{
	if( GetPictureName().length() == 0 )
		return std::string();
	
	std::string	stackURL( GetDocument()->GetURL() );
	stackURL.append( 1, '/' );
	stackURL.append( GetPictureName() );
	return stackURL;
}


bool	CLayer::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp(inPropertyName, "name") == 0 )
	{
		LEOInitStringValue( outValue, mName.c_str(), mName.size(), kLEOInvalidateReferences, inContext );
		return true;
	}
	else if( strcasecmp(inPropertyName, "id") == 0 )
	{
		LEOInitIntegerValue( outValue, GetID(), kLEOUnitNone, kLEOInvalidateReferences, inContext );
		return true;
	}
	else
		return CConcreteObject::GetPropertyNamed(inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
}


bool	CLayer::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp(inPropertyName, "name") == 0 )
	{
		char		styleBuf[100] = {0};
		const char*	styleStr = LEOGetValueAsString( inValue, styleBuf, sizeof(styleBuf), inContext );
		SetName( styleStr );
		return true;
	}
	else if( strcasecmp(inPropertyName, "id") == 0 )
	{
		LEOContextStopWithError( inContext, SIZE_T_MAX, SIZE_T_MAX, 0, "The ID of an object can't be changed." );
		return true;
	}
	else
		return CConcreteObject::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
}


const char*	CLayer::GetIdentityForDump()
{
	return "Layer";
}


void	CLayer::DumpProperties( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%sloaded = %s\n", indentStr, mLoaded ? "true" : "false" );
}


void	CLayer::Dump( size_t inIndent )
{
	const char	*	indentStr = IndentString(inIndent);
	printf( "%s%s ID %lld \"%s\"\n%s{\n", indentStr, GetIdentityForDump(), mID, mName.c_str(), indentStr );
	DumpProperties( inIndent +1 );
	DumpUserProperties( inIndent +1 );
	printf( "%s\tscript = <<%s>>\n", indentStr, mScript.c_str() );
	printf("%s\tparts\n%s\t{\n",indentStr,indentStr);
	for( auto itty = mParts.begin(); itty != mParts.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s\tcontents\n%s\t{\n", indentStr, indentStr, indentStr );
	for( auto itty = mContents.begin(); itty != mContents.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s\taddcolor parts\n%s\t{\n", indentStr, indentStr, indentStr );
	for( auto itty = mAddColorParts.begin(); itty != mAddColorParts.end(); itty++ )
		(*itty)->Dump( inIndent +2 );
	printf( "%s\t}\n%s}\n", indentStr, indentStr );
}

