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
					mParts.push_back( thePart );
					thePart->Release();

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
					size_t			slashPos = styleSheetURL.rfind('/');
					if( slashPos == std::string::npos )
						slashPos = styleSheetURL.length();
					else
						slashPos += 1;
					styleSheetURL = styleSheetURL.substr(0, slashPos);
					styleSheetURL.append(styleSheetFilename);
					
//					std::cout << styleSheetURL << std::endl;
					
					CURLRequest		styleSheetRequest( styleSheetURL );
					CURLConnection::SendRequestWithCompletionHandler( styleSheetRequest, [this,root,document](CURLResponse inStyleSheetResponse, const char* inStyleSheetData, size_t inStyleSheetDataLength)
					{
						if( inStyleSheetData )	// Managed to load CSS file?
						{
							mStyles.LoadFromStream( std::string( inStyleSheetData, inStyleSheetDataLength ) );
							//mStyles.Dump();
						}
						
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


void	CLayer::SavePropertiesToElement( tinyxml2::XMLElement* stackfile )
{
	tinyxml2::XMLDocument* document = stackfile->GetDocument();
	tinyxml2::XMLElement*	elem = document->NewElement("bitmap");
	elem->SetText( mPictureName.c_str() );
	stackfile->InsertEndChild(elem);

	CTinyXMLUtils::AddBoolNamed( stackfile, mCantDelete, "cantDelete" );
	CTinyXMLUtils::AddBoolNamed( stackfile, mShowPict, "showPict" );
	CTinyXMLUtils::AddBoolNamed( stackfile, mDontSearch, "dontSearch" );
}


bool	CLayer::Save( const std::string& inPackagePath )
{
	if( !mLoaded )
		return true;
	
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
	
	SavePropertiesToElement( stackfile );
	
	tinyxml2::XMLNode*	lastChildBeforeStyles = stackfile->LastChild();
	// We remember lastChildBeforeStyles so we can later insert a "link" tag referencing our CSS here, if needed.
	
	CStyleSheet	theStyles;

	for( auto currPart : mParts )
	{
		elem = document.NewElement("part");
		currPart->SaveToElement( elem );
		stackfile->InsertEndChild(elem);
	}
	
	for( auto currContent : mContents )
	{
		elem = document.NewElement("content");
		currContent->SaveToElementAndStyleSheet( elem, &theStyles );
		stackfile->InsertEndChild(elem);
	}
	
	elem = document.NewElement("name");
	elem->SetText( mName.c_str() );
	stackfile->InsertEndChild(elem);

	elem = document.NewElement("script");
	elem->SetText( mScript.c_str() );
	stackfile->InsertEndChild(elem);

	SaveUserPropertiesToElementOfDocument( stackfile, &document );

	std::string	styleSheet = theStyles.GetCSS();
	if( styleSheet.length() > 0 )
	{
		std::string	destStylesPath(inPackagePath);
		if( destStylesPath.length() > 0 && destStylesPath[destStylesPath.length() -1] != '/' )
			destStylesPath.append(1,'/');
		std::stringstream	destStylesName;
		destStylesName << "stylesheet_card_" << mID << ".css";
		destStylesPath.append(destStylesName.str());
		
		elem = document.NewElement("link");
		elem->SetAttribute("rel", "stylesheet");
		elem->SetAttribute("type", "text/css");
		elem->SetAttribute("href", destStylesName.str().c_str());
		stackfile->InsertAfterChild(lastChildBeforeStyles,elem);
		
		FILE*	theFile = fopen( destStylesPath.c_str(), "w" );
		if( !theFile )
			return false;
		fwrite( styleSheet.c_str(), styleSheet.size(), 1, theFile );
		fclose( theFile );
	}

	std::string	destPath(inPackagePath);
	if( destPath.length() > 0 && destPath[destPath.length() -1] != '/' )
		destPath.append(1,'/');
	destPath.append( mFileName );
	FILE*	theFile = fopen( destPath.c_str(), "w" );
	if( !theFile )
		return false;
	CStacksmithXMLPrinter	printer( theFile );
	document.Print( &printer );
	fclose(theFile);
	
	mChangeCount = 0;
	
	return true;
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
		ObjectID		objectID = CTinyXMLUtils::GetLongLongNamed( theObject, "id" );
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
				oldPartIndex = numParts;
				break;
			}
			numParts++;
		}
	}
	
	if( (size_t)newPartIndex < mParts.size() )
	{
		mParts.erase( mParts.begin() +oldPartIndex );
		mParts.insert( mParts.begin() +newPartIndex, inPart );
	}
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
	for( CPart* currPart : mParts )
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


void	CLayer::DeleteSelectedItem()
{
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		if( (*currPart)->IsSelected() )
		{
			(*currPart)->GoToSleep();
			currPart = mParts.erase(currPart);
			if( currPart == mParts.end() )
				break;
		}
	}
}


void	CLayer::DeselectAllItems()
{
	for( auto currPart = mParts.begin(); currPart != mParts.end(); currPart++ )
	{
		if( (*currPart)->IsSelected() )
		{
			(*currPart)->SetSelected(false);
		}
	}
}


bool	CLayer::CanDeleteSelectedItem()
{
	for( auto currPart : mParts )
	{
		if( currPart->IsSelected() )
			return true;
	}
	return false;
}


std::string	CLayer::CopySelectedItem()
{
	tinyxml2::XMLDocument	document;
	CStyleSheet				styleSheet;
	tinyxml2::XMLElement *	partsElement = document.NewElement("parts");
	document.InsertEndChild( partsElement );
	tinyxml2::XMLElement *	cardElement = document.NewElement("card");
	tinyxml2::XMLElement *	backgroundElement = document.NewElement("background");
	tinyxml2::XMLElement *	resourcesElement = document.NewElement("resources");
	
	for( CPart* currPart : mParts )
	{
		if( currPart->IsSelected() )
		{
			tinyxml2::XMLElement *	partElement = document.NewElement("part");
			partsElement->InsertEndChild( partElement );
			currPart->SaveToElement( partElement );
			CPartContents*	cardContents = GetPartContentsByID( currPart->GetID(), false );
			if( cardContents )
			{
				tinyxml2::XMLElement *	contentsElement = document.NewElement("contents");
				cardElement->InsertEndChild( contentsElement );
				cardContents->SaveToElementAndStyleSheet( contentsElement, &styleSheet );
			}
			CPartContents*	bgContents = GetPartContentsByID( currPart->GetID(), true );
			if( bgContents )
			{
				tinyxml2::XMLElement *	contentsElement = document.NewElement("contents");
				backgroundElement->InsertEndChild( contentsElement );
				bgContents->SaveToElementAndStyleSheet( contentsElement, &styleSheet );
			}
			
			currPart->SaveAssociatedResourcesToElement( resourcesElement );
		}
	}
	
	tinyxml2::XMLElement *	stylesElement = document.NewElement("style");
	stylesElement->SetText( styleSheet.GetCSS().c_str() );
	partsElement->InsertEndChild( stylesElement );
	partsElement->InsertEndChild( cardElement );
	partsElement->InsertEndChild( backgroundElement );
	partsElement->InsertEndChild( resourcesElement );
	
	CStacksmithXMLPrinter	printer;
	document.Print( &printer );
	return std::string(printer.CStr());
}


bool	CLayer::CanCopySelectedItem()
{
	for( auto currPart : mParts )
	{
		if( currPart->IsSelected() )
			return true;
	}
	return false;
}


void	CLayer::LoadPastedPartBackgroundContents( CPart* newPart, tinyxml2::XMLElement* currBgContents, bool haveCardContents, CStyleSheet * inStyleSheet )
{
	if( newPart->GetSharedText() )
	{
		CPartContents*	pc = new CPartContents( this, currBgContents, inStyleSheet );
		pc->SetID( newPart->GetID() );
		mContents.push_back( pc );
		pc->Release();
	}
}


void	CLayer::LoadPastedPartCardContents( CPart* newPart, tinyxml2::XMLElement* currCardContents, bool haveBgContents, CStyleSheet * inStyleSheet )
{
	if( !newPart->GetSharedText() )
	{
		CPartContents*	pc = new CPartContents( this, currCardContents, inStyleSheet );
		pc->SetID( newPart->GetID() );
		mContents.push_back( pc );
		pc->Release();
	}
}


void	CLayer::LoadPastedPartContents( CPart* newPart, ObjectID oldID, tinyxml2::XMLElement* *currCardContents, tinyxml2::XMLElement* *currBgContents, CStyleSheet * inStyleSheet )
{
	// We get the next part contents in the list on the clipboard. So if this doesn't
	//	match our ID, and don't consume the contents.
	
	ObjectID	theID = CTinyXMLUtils::GetLongLongNamed( *currCardContents, "id" );
	bool		haveCardContents = (theID == oldID);
	theID = CTinyXMLUtils::GetLongLongNamed( *currBgContents, "id" );
	bool		haveBgContents = (theID == oldID);
	if( haveCardContents && (*currCardContents) != NULL )
	{
		LoadPastedPartCardContents( newPart, *currCardContents, haveBgContents, inStyleSheet );
		
		*currCardContents = (*currCardContents)->NextSiblingElement("contents");
	}
	
	if( haveBgContents && (*currBgContents) != NULL )
	{
		LoadPastedPartBackgroundContents( newPart, *currBgContents, haveCardContents, inStyleSheet );
		
		*currBgContents = (*currBgContents)->NextSiblingElement("contents");
	}
}


std::vector<CPartRef>	CLayer::PasteObject( const std::string& inXMLStr )
{
	//Dump();
	
	std::vector<CPartRef>	newParts;
	tinyxml2::XMLDocument	document;
	if( tinyxml2::XML_SUCCESS == document.Parse( inXMLStr.c_str(), inXMLStr.size() ) )
	{
		tinyxml2::XMLElement*	rootElement = document.FirstChildElement();
		if( strcasecmp( rootElement->Value(), "parts" ) == 0 )
		{
			tinyxml2::XMLElement*	styles = document.FirstChildElement( "style" );
			CStyleSheet				styleSheet;
			if( styles )
				styleSheet.LoadFromStream( styles->GetText() );
			
			tinyxml2::XMLElement*	currPart = rootElement->FirstChildElement( "part" );
			tinyxml2::XMLElement*	cardContents = rootElement->FirstChildElement( "card" );
			tinyxml2::XMLElement*	bgContents = rootElement->FirstChildElement( "background" );
			tinyxml2::XMLElement*	currCardContents = cardContents->FirstChildElement("contents");
			tinyxml2::XMLElement*	currBgContents = bgContents->FirstChildElement("contents");
			while( currPart )
			{
				ObjectID	oldID = CTinyXMLUtils::GetLongLongNamed( currPart, "id" );
				ObjectID	newID = oldID;
				if( GetPartWithID( newID ) != NULL )
				{
					newID = GetUniqueIDForPart();
					currPart->DeleteChild( currPart->FirstChildElement("id") );
					CTinyXMLUtils::AddLongLongNamed( currPart, newID, "id" );
				}
				
				CPart	*	newPart = CPart::NewPartWithElement( currPart, this );
				mParts.push_back( newPart );
				newPart->Release();
				
				LoadPastedPartContents( newPart, oldID, &currCardContents, &currBgContents, &styleSheet );
				
				// +++ Paste any icons this part references!
				
				IncrementChangeCount();
				
				newParts.push_back(newPart);
				
				currPart = currPart->NextSiblingElement( "part" );
			}
		}
		
		std::map<ObjectID,ObjectID>	changedMediaIDs;
		tinyxml2::XMLElement*		resourcesElement = rootElement->FirstChildElement( "resources" );
		tinyxml2::XMLElement*		currMedia = resourcesElement->FirstChildElement( "media" );
		while( currMedia )
		{
			CMediaEntry		newEntry;
			newEntry.LoadFromElement( currMedia, mStack->GetDocument()->GetURL(), false );
			
			ObjectID	newID = mStack->GetDocument()->GetMediaCache().GetUniqueMediaIDIfEntryOfTypeIsNoDuplicate( newEntry );
			if( newID != 0 )	// 0 == already exists, no need to paste.
			{
				if( newID != newEntry.GetID() )
				{
					changedMediaIDs[newEntry.GetID()] = newID;	// +++ Keep track of type.
					newEntry.SetID(newID);
				}
				newEntry.IncrementChangeCount();
				mStack->GetDocument()->GetMediaCache().AddMediaEntry( newEntry );
				mStack->GetDocument()->IncrementChangeCount();
			}
			
			currMedia = currMedia->NextSiblingElement( "media" );
		}
		
		if( changedMediaIDs.size() > 0 )	// Had to assign a unique ID to a pasted icon?
		{
			for( CPart* currPart : newParts )
			{
				// Tell each part to update its stuff:
				currPart->UpdateMediaIDs( changedMediaIDs );	// +++ Pass along type.
			}
		}
		for( CPart* currPart : newParts )
		{
			currPart->WakeUp();
		}
	}
	
	//Dump();
	
	return newParts;
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


void	CLayer::SetName( const std::string &inName )
{
	CConcreteObject::SetName( inName );
	
	mStack->IncrementChangeCount();	// List of cards/backgrounds contains the names so we can go to a card by name without having to load them all. Make sure that gets updated.
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "The ID of an object can't be changed." );
		return true;
	}
	else
		return CConcreteObject::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
}


const char*	CLayer::GetIdentityForDump()
{
	return "Layer";
}


// Maximum distance between two objects for us to even consider aligning them
//	when snapping/showing guidelines. This applies to any direction, i.e. if a
//	button is at 49 pixels horz. from ours, we consider aligning them horz. or vert.
#define	MAX_CONSIDERATION_DISTANCE			50LL

// If a particular coordinate of our object is at most this far from a parallel
//	line on another object, we snap and show the guideline:
#define MAX_SNAPPING_DISTANCE				8LL

// When snapping to the card egde, we snap only if user gets a bit closer or
//	moves beyond the card edge:
#define MAX_INNER_EDGE_SNAPPING_DISTANCE	2LL

// Margin from the window edge that we snap to apart from 0:
#define IDEAL_EDGE_DISTANCE					20LL

// Distance at which we snap to other parts apart from 0:
#define IDEAL_PART_DISTANCE					9LL


void	CLayer::IncrementChangeCount()
{
	mChangeCount++;
}


void	CLayer::CorrectRectOfPart( CPart* inMovedPart, THitPart partsToCorrect, long long *ioLeft, long long *ioTop, long long *ioRight, long long *ioBottom, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock )
{
	CorrectRectOfPart( inMovedPart, mParts, partsToCorrect, ioLeft, ioTop, ioRight, ioBottom, addGuidelineBlock );
}


void	CLayer::CorrectRectOfPart( CPart* inMovedPart, std::vector<CPartRef> inEligibleParts, THitPart partsToCorrect, long long *ioLeft, long long *ioTop, long long *ioRight, long long *ioBottom, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock )
{
	long long		minXDist = LLONG_MAX,
					minYDist = LLONG_MAX;
	long			leftGuide = 0, topGuide = 0;
	long long		xNudge = 0, yNudge = 0;

	// See if we're near the card edge at the recommended Aqua border distance and snap to that:
	if( (*ioRight) > (((long long)mStack->GetCardWidth()) -IDEAL_EDGE_DISTANCE -MAX_INNER_EDGE_SNAPPING_DISTANCE) && (partsToCorrect & ERightGrabberHitPart) )
	{
		xNudge = ((long long)mStack->GetCardWidth() -IDEAL_EDGE_DISTANCE) -*ioRight;
		minXDist = llabs( xNudge );
		leftGuide = mStack->GetCardWidth() -IDEAL_EDGE_DISTANCE;
	}

	if( (*ioLeft) < (MAX_INNER_EDGE_SNAPPING_DISTANCE +IDEAL_EDGE_DISTANCE) && (partsToCorrect & ELeftGrabberHitPart) )
	{
		xNudge = IDEAL_EDGE_DISTANCE -*ioLeft;
		minXDist = llabs( xNudge );
		leftGuide = IDEAL_EDGE_DISTANCE;
	}

	if( (*ioBottom) > (((long long)mStack->GetCardHeight()) -MAX_INNER_EDGE_SNAPPING_DISTANCE -IDEAL_EDGE_DISTANCE) && (partsToCorrect & EBottomGrabberHitPart) )
	{
		yNudge = ((long long)mStack->GetCardHeight() -IDEAL_EDGE_DISTANCE) -*ioBottom;
		minYDist = llabs( yNudge );
		topGuide = mStack->GetCardHeight() -IDEAL_EDGE_DISTANCE;
	}
	
	if( (*ioTop) < (MAX_INNER_EDGE_SNAPPING_DISTANCE +IDEAL_EDGE_DISTANCE) && (partsToCorrect & ETopGrabberHitPart) )
	{
		yNudge = IDEAL_EDGE_DISTANCE -*ioTop;
		minYDist = llabs( yNudge );
		topGuide = IDEAL_EDGE_DISTANCE;
	}
	
	// See if we're at a card edge and snap to that:
	if( (*ioRight) > (((long long)mStack->GetCardWidth()) -MAX_INNER_EDGE_SNAPPING_DISTANCE) && (partsToCorrect & ERightGrabberHitPart) )
	{
		xNudge = ((long long)mStack->GetCardWidth()) -*ioRight;
		minXDist = llabs( xNudge );
		leftGuide = mStack->GetCardWidth();
	}

	if( (*ioLeft) < MAX_INNER_EDGE_SNAPPING_DISTANCE && (partsToCorrect & ELeftGrabberHitPart) )
	{
		xNudge = -*ioLeft;
		minXDist = llabs( xNudge );
		leftGuide = 0;
	}

	if( (*ioBottom) > (((long long)mStack->GetCardHeight()) -MAX_INNER_EDGE_SNAPPING_DISTANCE) && (partsToCorrect & EBottomGrabberHitPart) )
	{
		yNudge = ((long long)mStack->GetCardHeight()) -*ioBottom;
		minYDist = llabs( yNudge );
		topGuide = mStack->GetCardHeight();
	}
	
	if( (*ioTop) < MAX_INNER_EDGE_SNAPPING_DISTANCE && (partsToCorrect & ETopGrabberHitPart) )
	{
		yNudge = -*ioTop;
		minYDist = llabs( yNudge );
		topGuide = 0;
	}

	// See if we're near any other parts and snap to those:
	for( CPart* currPart : inEligibleParts )
	{
		if( currPart != inMovedPart )
		{
			long long		currXLeftDist = llabs( currPart->GetLeft() -*ioLeft ),
							currXRightDist = llabs( currPart->GetRight() -*ioRight ),
							currYTopDist = llabs( currPart->GetTop() -*ioTop ),
							currYBottomDist = llabs( currPart->GetBottom() -*ioBottom ),
							currXLeftDist2 = llabs( currPart->GetRight() -*ioLeft ),
							currXRightDist2 = llabs( currPart->GetLeft() -*ioRight ),
							currYTopDist2 = llabs( currPart->GetBottom() -*ioTop ),
							currYBottomDist2 = llabs( currPart->GetTop() -*ioBottom ),
							currIdealXLeftDist = currPart->GetLeft() -IDEAL_PART_DISTANCE -*ioRight,
							currIdealXRightDist = currPart->GetRight() +IDEAL_PART_DISTANCE -*ioLeft,
							currIdealYTopDist = currPart->GetTop() -IDEAL_PART_DISTANCE -*ioBottom,
							currIdealYBottomDist = currPart->GetBottom() +IDEAL_PART_DISTANCE -*ioTop;
			bool			verticallyNear = currYTopDist < MAX_CONSIDERATION_DISTANCE || currYBottomDist < MAX_CONSIDERATION_DISTANCE
											|| currYTopDist2 < MAX_CONSIDERATION_DISTANCE || currYBottomDist2 < MAX_CONSIDERATION_DISTANCE;
			bool			horizontallyNear = currXLeftDist < MAX_CONSIDERATION_DISTANCE || currXRightDist < MAX_CONSIDERATION_DISTANCE
											|| currXLeftDist2 < MAX_CONSIDERATION_DISTANCE || currXRightDist2 < MAX_CONSIDERATION_DISTANCE;
			if( !horizontallyNear || !verticallyNear )
				continue;
			
			// Horizontal:
			// Align equivalent edges?
			if( currXLeftDist < minXDist && (partsToCorrect & ELeftGrabberHitPart) )
			{
				xNudge = currPart->GetLeft() -*ioLeft;
				minXDist = currXLeftDist;
				leftGuide = currPart->GetLeft();
			}
			if( currXRightDist < minXDist && (partsToCorrect & ERightGrabberHitPart) )
			{
				xNudge = currPart->GetRight() -*ioRight;
				minXDist = currXRightDist;
				leftGuide = currPart->GetRight();
			}
			// Abut right next to this part?
			if( currXLeftDist2 < minXDist && (partsToCorrect & ELeftGrabberHitPart) )
			{
				xNudge = currPart->GetRight() -*ioLeft;
				minXDist = currXLeftDist2;
				leftGuide = currPart->GetRight();
			}
			if( currXRightDist2 < minXDist && (partsToCorrect & ERightGrabberHitPart) )
			{
				xNudge = currPart->GetLeft() -*ioRight;
				minXDist = currXRightDist2;
				leftGuide = currPart->GetLeft();
			}
			// Snap at an ideal distance from that part? (Note that these don't
			//	align equivalent edges, but abut adjoining ones, hence the grabber is
			//	the opposite of the distance variable:
			if( (-currIdealXLeftDist) < minXDist && currIdealXLeftDist < 0 && (partsToCorrect & ERightGrabberHitPart) )
			{
				if( llabs( currIdealXLeftDist ) < MAX_SNAPPING_DISTANCE )
				{
					xNudge = currIdealXLeftDist;
					minXDist = currIdealXLeftDist;
					leftGuide = currPart->GetLeft() -IDEAL_PART_DISTANCE;
				}
			}
			if( currIdealXRightDist < minXDist && currIdealXRightDist >= 0 && (partsToCorrect & ELeftGrabberHitPart) )
			{
				if( llabs( currIdealXRightDist ) < MAX_SNAPPING_DISTANCE )
				{
					xNudge = currIdealXRightDist;
					minXDist = currIdealXRightDist;
					leftGuide = currPart->GetRight() +IDEAL_PART_DISTANCE;
				}
			}
			
			// Vertical:
			// Align equivalent edges?
			if( currYTopDist < minYDist && (partsToCorrect & ETopGrabberHitPart) )
			{
				yNudge = currPart->GetTop() -*ioTop;
				minYDist = currYTopDist;
				topGuide = currPart->GetTop();
			}
			if( currYBottomDist < minYDist && (partsToCorrect & EBottomGrabberHitPart) )
			{
				yNudge = currPart->GetBottom() -*ioBottom;
				minYDist = currYBottomDist;
				topGuide = currPart->GetBottom();
			}
			// Abut right above/below this part?
			if( currYTopDist2 < minYDist && (partsToCorrect & ETopGrabberHitPart) )
			{
				yNudge = currPart->GetBottom() -*ioTop;
				minYDist = currYTopDist2;
				topGuide = currPart->GetBottom();
			}
			if( currYBottomDist2 < minYDist && (partsToCorrect & EBottomGrabberHitPart) )
			{
				yNudge = currPart->GetTop() -*ioBottom;
				minYDist = currYBottomDist2;
				topGuide = currPart->GetTop();
			}
			// Snap at an ideal distance from that part? (Note that these don't
			//	align equivalent edges, but abut adjoining ones, hence the grabber is
			//	the opposite of the distance variable:
			if( (-currIdealYTopDist) < minYDist && currIdealYTopDist < 0 && (partsToCorrect & EBottomGrabberHitPart) )
			{
				if( llabs( currIdealYTopDist ) < MAX_SNAPPING_DISTANCE )
				{
					yNudge = currIdealYTopDist;
					minYDist = currIdealYTopDist;
					topGuide = currPart->GetTop() -IDEAL_PART_DISTANCE;
				}
			}
			if( currIdealYBottomDist < minYDist && currIdealYBottomDist >= 0 && (partsToCorrect & ETopGrabberHitPart) )
			{
				if( llabs( currIdealYBottomDist ) < MAX_SNAPPING_DISTANCE )
				{
					yNudge = currIdealYBottomDist;
					minYDist = currIdealYBottomDist;
					topGuide = currPart->GetBottom() +IDEAL_PART_DISTANCE;
				}
			}
		}
	}
	
	// Correct the rect coordinates we're supposed to modify of the rect we were given:
	if( minXDist < MAX_SNAPPING_DISTANCE )
	{
		if( partsToCorrect & ELeftGrabberHitPart )
			*ioLeft += xNudge;
		if( partsToCorrect & ERightGrabberHitPart )
			*ioRight += xNudge;
	}
	if( minYDist < MAX_SNAPPING_DISTANCE )
	{
		if( partsToCorrect & ETopGrabberHitPart )
			*ioTop += yNudge;
		if( partsToCorrect & EBottomGrabberHitPart )
			*ioBottom += yNudge;
	}
	
	// Call back to indicate which guidelines we want:
	addGuidelineBlock( LLONG_MAX, EGuidelineCallbackActionClearAllForFilling );
	if( minXDist < MAX_SNAPPING_DISTANCE )
		addGuidelineBlock( leftGuide, EGuidelineCallbackActionAddVertical );
	if( minYDist < MAX_SNAPPING_DISTANCE )
		addGuidelineBlock( topGuide, EGuidelineCallbackActionAddHorizontal );
}


void	CLayer::ToolChangedFrom( TTool inOldTool )
{
	DeselectAllItems();
	
	for( CPartRef currPart : mParts )
		currPart->ToolChangedFrom( inOldTool );
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

