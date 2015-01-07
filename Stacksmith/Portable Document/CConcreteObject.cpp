//
//  CConcreteObject.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CConcreteObject.h"
#include "CTinyXMLUtils.h"
#include "CDocument.h"
#include "LEOScript.h"
#include "CToken.h"	// for ToLowerString().
#include <sstream>


using namespace Carlson;


CConcreteObject::CConcreteObject()
	: CScriptableObject(), mIDForScripts(kLEOObjectIDINVALID), mScriptObject(NULL), mDocument(NULL)
{
	
}


CConcreteObject::~CConcreteObject()
{
	if( mScriptObject )
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
}


void	CConcreteObject::SetScript( std::string inScript )
{
	mScript = inScript;
	if( mScriptObject )	// Nuke old script so we recreate it next someone asks for it.
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
	IncrementChangeCount();
}


LEOContextGroup*	CConcreteObject::GetScriptContextGroupObject()
{
	return mDocument->GetScriptContextGroupObject();
}


void	CConcreteObject::SetBreakpointLines( const std::vector<size_t>& inBreakpointLines )
{
	mBreakpointLines = inBreakpointLines;
	if( mScriptObject )	// If we already have a compiled script, make sure it's updated accordingly:
	{
		LEOScriptRemoveAllBreakpoints( mScriptObject );
		for( size_t currLine : mBreakpointLines )
		{
			LEOScriptAddBreakpointAtLine( mScriptObject, currLine );
		}
	}
}


static CAddHandlerListEntry	sMasterHandlerList[] =
{
	{
		kHandlerEntryGroupHeader,
		0,
		"Card Events",
		"",
		"",
		"card"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"openCard",
		"The current card just changed, prepare this card for the user.",
		"",
		"card"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"closeCard",
		"The current card is about to change, last chance for clean-up.",
		"",
		"card"
	},
	{
		kHandlerEntryGroupHeader,
		0,
		"Stack Events",
		"",
		"",
		"card"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"closeStack",
		"The current stack is about to change, last chance for clean-up.",
		"",
		"card"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"openStack",
		"The current stack just changed, prepare this stack for the user.",
		"",
		"card"
	},
	{
		kHandlerEntryGroupHeader,
		0,
		"Mouse Events",
		"",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUp",
		"React to a click in the card window.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDown",
		"React to the mouse being held down somewhere in the card window.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDrag",
		"The mouse is being held down and moving while over an object in the card window.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpOutside",
		"A click was started somewhere in the card window but not released inside that object.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpInLink",
		"A link in a text field was clicked. ",
		"",
		"field"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleClick",
		"A double click in the card window completed.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseEnter",
		"The mouse arrow has moved onto an object in the card window.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseMove",
		"The mouse arrow has moved while over an object in the card window.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseLeave",
		"The mouse arrow has moved off an object in the card window after being inside.",
		"",
		""
	},
	{
		kHandlerEntryGroupHeader,
		0,
		"Movie Player Events",
		"",
		"",
		"moviePlayer"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"playMovie",
		"Playback of a movie player has started.",
		"",
		"moviePlayer"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"stopMovie",
		"Playback of a movie player has stopped.",
		"",
		"moviePlayer"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"timeChange",
		"The playback time of a movie player was changed (e.g. by dragging the playhead).",
		"",
		"moviePlayer"
	},
	{
		kHandlerEntryGroupHeader,
		0,
		"Field Events",
		"",
		"",
		"field"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"selectionChange",
		"The text selection in a text field has changed.",
		"",
		"field"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpInLink",
		"A link in a text field was clicked. ",
		"",
		"field"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"openField",
		"A text field has been given keyboard focus.",
		"",
		"field"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"closeField",
		"A text field is about to lose keyboard focus.",
		"",
		"field"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"keyDown",
		"A key was pressed on the keyboard.",
		"",
		"field"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"tabKey",
		"The tab key was pressed on the keyboard.",
		"",
		"field"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"arrowKey",
		"One of the arrow keys was pressed on the keyboard.",
		"",
		"field"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"functionKey",
		"One of the function keys was pressed on the keyboard.",
		"\n\non functionKey fKeyNumber,modifier1,modifier2,modifier3,modifier4\n\t\nend functionKey",
		"field"
	},
	{
		kHandlerEntryGroupHeader,
		0,
		"Web Browser Events",
		"",
		"",
		"browser"
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"loadPage",
		"The web page has finished loading.",
		"",
		"browser"
	},
	{
		kHandlerEntryGroupHeader,
		0,
		"Editor Events",
		"",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDownWhilePeeking",
		"The mouse has been clicked while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDragWhilePeeking",
		"The mouse has been held and moved while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpWhilePeeking",
		"The mouse has been clicked while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleDownWhilePeeking",
		"The mouse has been double-clicked while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleClickWhilePeeking",
		"The mouse has been double-clicked while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDownWhileEditing",
		"The mouse has been clicked while the pointer tool is active.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDragWhileEditing",
		"The mouse has been held and moved while the pointer tool is active.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpWhileEditing",
		"The mouse has been clicked while the pointer tool is active.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleDownWhileEditing",
		"The mouse has been double-clicked while the pointer tool is active.",
		"",
		""
	},
	{
		kHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleClickWhileEditing",
		"The mouse has been double-clicked while the pointer tool is active.",
		"",
		""
	},
	{
		kHandlerEntry_LAST,
		0,
		"",
		"",
		"",
		""
	}
};


std::vector<CAddHandlerListEntry>	CConcreteObject::GetAddHandlerList()
{
	std::vector<CAddHandlerListEntry>	handlers;
	
	for( size_t x = 0; sMasterHandlerList[x].mType != kHandlerEntry_LAST; x++ )
	{
		CAddHandlerListEntry&	currHandler = sMasterHandlerList[x];
		if( currHandler.mHandlerID == kLEOHandlerIDINVALID )	// First time iterating master table? Initialize some fields.
		{
			LEOContextGroup*	theGroup = GetScriptContextGroupObject();
			currHandler.mHandlerID = LEOContextGroupHandlerIDForHandlerName( theGroup, currHandler.mHandlerName.c_str() );
			
			if( currHandler.mHandlerTemplate.empty() )
			{
				std::stringstream	strstr;
				strstr << "\n\non " << currHandler.mHandlerName << "\n\t\nend" << currHandler.mHandlerName;
				currHandler.mHandlerTemplate = strstr.str();
			}
		}
		
		// Only show handlers that are either usable from all object types, or specific to this one:
		if( currHandler.mTiedToType.empty() || ShowHandlersForObjectType(currHandler.mTiedToType) )
		{
			// Don't add handlers we already have:
			if( currHandler.mType == kHandlerEntryCommand && (mScriptObject == NULL || LEOScriptFindCommandHandlerWithID( mScriptObject, currHandler.mHandlerID ) == NULL) )
			{
				handlers.push_back( currHandler );
			}
			else if( currHandler.mType == kHandlerEntryFunction && (mScriptObject == NULL || LEOScriptFindFunctionHandlerWithID( mScriptObject, currHandler.mHandlerID ) == NULL) )
			{
				handlers.push_back( currHandler );
			}
			else if( currHandler.mType == kHandlerEntryGroupHeader )
			{
				if( handlers.back().mType == kHandlerEntryGroupHeader )	// Previous group was empty? Remove it.
					handlers.pop_back();
				handlers.push_back( currHandler );
			}
		}
	}

	if( handlers.back().mType == kHandlerEntryGroupHeader )	// Last group was empty? Remove it.
		handlers.pop_back();
	
	return handlers;
}


LEOScript*	CConcreteObject::GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler )
{
	if( !mScriptObject )
	{
		const char*		scriptStr = mScript.c_str();
		uint16_t		fileID = LEOFileIDForFileName( mName.c_str() );	// +++ TODO: Use long name!
		LEOParseTree*	parseTree = LEOParseTreeCreateFromUTF8Characters( scriptStr, strlen(scriptStr), fileID );
		if( LEOParserGetLastErrorMessage() == NULL )
		{
			if( mIDForScripts == kLEOObjectIDINVALID )
			{
				InitScriptableObjectValue( &mValueForScripts, this, kLEOInvalidateReferences, NULL );
				mIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( GetScriptContextGroupObject(), &mValueForScripts );
				mSeedForScripts = LEOContextGroupGetSeedForObjectID( GetScriptContextGroupObject(), mIDForScripts );
			}
			mScriptObject = LEOScriptCreateForOwner( mIDForScripts, mSeedForScripts, GetParentScript );
			LEOScriptCompileAndAddParseTree( mScriptObject, GetScriptContextGroupObject(), parseTree, fileID );
			
			for( size_t currLine : mBreakpointLines )
			{
				LEOScriptAddBreakpointAtLine( mScriptObject, currLine );
			}
			
#if REMOTE_DEBUGGER
			LEORemoteDebuggerAddFile( scriptStr, fileID, mScriptObject );
			
			// Set a breakpoint on the mouseUp handler:
			//			LEOHandlerID handlerName = LEOContextGroupHandlerIDForHandlerName( [self scriptContextGroupObject], "mouseup" );
			//			LEOHandler* theHandler = LEOScriptFindCommandHandlerWithID( mScriptObject, handlerName );
			//			if( theHandler )
			//				LEORemoteDebuggerAddBreakpoint( theHandler->instructions );
#endif
		}
		if( LEOParserGetLastErrorMessage() )
		{
			size_t	lineNum = LEOParserGetLastErrorLineNum();
			size_t	errorOffset = LEOParserGetLastErrorOffset();
			const char*	errorMessage = LEOParserGetLastErrorMessage();
			
			if( errorHandler )
				errorHandler( errorMessage, lineNum, errorOffset, this );
			
			if( mScriptObject )
			{
				LEOScriptRelease( mScriptObject );
				mScriptObject = NULL;
			}
		}
		else if( errorHandler )
			errorHandler( NULL, SIZE_T_MAX, SIZE_T_MAX, this );
	}
	
	return mScriptObject;
}


void	CConcreteObject::LoadUserPropertiesFromElement( tinyxml2::XMLElement * elem )
{
	tinyxml2::XMLElement	*	userPropsElem = elem->FirstChildElement( "userProperties" );
	tinyxml2::XMLElement	*	currUserPropNameNode = userPropsElem ? userPropsElem->FirstChildElement() : NULL;
	while( currUserPropNameNode )
	{
		std::string		propName = ToLowerString( currUserPropNameNode ? CTinyXMLUtils::EnsureNonNULLString(currUserPropNameNode->GetText()) : std::string() );
		currUserPropNameNode = currUserPropNameNode->NextSiblingElement();
		std::string		propValue = currUserPropNameNode ? CTinyXMLUtils::EnsureNonNULLString(currUserPropNameNode->GetText()) : std::string();
		currUserPropNameNode = currUserPropNameNode->NextSiblingElement();
		
		mUserProperties[propName] = propValue;
	}
}


void	CConcreteObject::SaveUserPropertiesToElementOfDocument( tinyxml2::XMLElement * elem, tinyxml2::XMLDocument * document )
{
	if( mUserProperties.size() > 0 )
	{
		tinyxml2::XMLElement	*	userPropsElem = document->NewElement("userProperties");
		for( auto userPropPair : mUserProperties )
		{
			tinyxml2::XMLElement	*	propNameElem = document->NewElement("name");
			propNameElem->SetText(userPropPair.first.c_str());
			userPropsElem->InsertEndChild(propNameElem);
			tinyxml2::XMLElement	*	propValueElem = document->NewElement("value");
			propValueElem->SetText(userPropPair.second.c_str());
			userPropsElem->InsertEndChild(propValueElem);
		}
		elem->InsertEndChild(userPropsElem);
	}
}


bool	CConcreteObject::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("userProperties", inPropertyName) == 0 )
	{
		LEOArrayEntry	*	theArray = NULL;
		char				tmpKey[512] = {0};
		size_t				x = 0;
		for( auto currProp : mUserProperties )
		{
			snprintf(tmpKey, sizeof(tmpKey) -1, "%zu", ++x );
			LEOAddCStringArrayEntryToRoot( &theArray, tmpKey, currProp.first.c_str(), inContext );
		}
		
		LEOInitArrayValue( &outValue->array, theArray, kLEOInvalidateReferences, inContext );
		return true;
	}
	
	std::string	propValue;
	if( GetUserPropertyValueForName( inPropertyName, propValue ) )
	{
		LEOInitStringValue( outValue, propValue.c_str(), propValue.length(), kLEOInvalidateReferences, inContext );
		return true;
	}
	else
		return CScriptableObject::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
}


bool	CConcreteObject::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	char		tmpKey[512] = {0};
	if( strcasecmp("userProperties", inPropertyName) == 0 )
	{
		size_t	numProps = LEOGetKeyCount( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		LEOValue	tmpStorage = {{0}};
		for( size_t x = 1; x <= numProps; x++ )
		{
			snprintf(tmpKey, sizeof(tmpKey)-1, "%zu", x );
			LEOValuePtr theValue = LEOGetValueForKey( inValue, tmpKey, &tmpStorage, kLEOInvalidateReferences, inContext );
			const char*	currPropName = LEOGetValueAsString( theValue, tmpKey, sizeof(tmpKey), inContext );
			if( (inContext->flags & kLEOContextKeepRunning) == 0 )
				return true;
			AddUserPropertyNamed( currPropName );
			if( theValue == &tmpStorage )
				LEOCleanUpValue( theValue, kLEOInvalidateReferences, inContext );
		}
		return true;
	}
	
	const char*	currPropVal = LEOGetValueAsString( inValue, tmpKey, sizeof(tmpKey), inContext );
	if( !SetUserPropertyValueForName( currPropVal, inPropertyName ) )
		return CScriptableObject::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	else
		return true;
}


bool	CConcreteObject::AddUserPropertyNamed( const char* userPropName )
{
	CMap<std::string>::iterator foundProp = mUserProperties.find(userPropName);
	if( foundProp == mUserProperties.end() )
	{
		mUserProperties[userPropName] = "";
		IncrementChangeCount();
	}
	
//	DumpUserProperties(0);
	
	return true;
}


bool	CConcreteObject::DeleteUserPropertyNamed( const char* userPropName )
{
	auto	foundProp = mUserProperties.find( userPropName );
	if( foundProp != mUserProperties.end() )
	{
		mUserProperties.erase( foundProp );
		IncrementChangeCount();
	}
	return true;
}


size_t	CConcreteObject::GetNumUserProperties()
{
	return mUserProperties.size();
}


std::string	CConcreteObject::GetUserPropertyNameAtIndex( size_t inIndex )
{
	CMap<std::string>::iterator foundProp = mUserProperties.begin();
	for( size_t x = 0; x <= inIndex && foundProp != mUserProperties.end(); x++ )
		foundProp++;
	return foundProp->first;
}


bool	CConcreteObject::SetUserPropertyNameAtIndex( const char* inNewName, size_t inIndex )
{
	CMap<std::string>::iterator foundProp = mUserProperties.begin();
	for( size_t x = 0; x <= inIndex && foundProp != mUserProperties.end(); x++ )
		foundProp++;
	
	if( foundProp != mUserProperties.end() )
	{
		mUserProperties[inNewName] = foundProp->second;
		mUserProperties.erase( foundProp );
	}
	else
		mUserProperties[inNewName] = "";
	IncrementChangeCount();
	
//	DumpUserProperties(0);
	
	return true;
}


bool	CConcreteObject::GetUserPropertyValueForName( const char* inPropName, std::string& outValue )
{
	CMap<std::string>::iterator foundProp = mUserProperties.find(inPropName);
	if( foundProp == mUserProperties.end() )
		return false;
	
	outValue = foundProp->second;
	
//	DumpUserProperties(0);
	
	return true;
}


bool	CConcreteObject::SetUserPropertyValueForName( const std::string& inValue, const char* inPropName )
{
	CMap<std::string>::iterator foundProp = mUserProperties.find(inPropName);
	if( foundProp == mUserProperties.end() )
		return false;
	
	foundProp->second = inValue;
	IncrementChangeCount();
	
//	DumpUserProperties(0);
	
	return true;
}


void	CConcreteObject::InitValue( LEOValuePtr outObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	if( mIDForScripts == kLEOObjectIDINVALID )
	{
		InitScriptableObjectValue( &mValueForScripts, this, kLEOInvalidateReferences, inContext );
		mIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( GetScriptContextGroupObject(), &mValueForScripts );
		mSeedForScripts = LEOContextGroupGetSeedForObjectID( GetScriptContextGroupObject(), mIDForScripts );
	}
	LEOInitReferenceValue( outObject, (LEOValuePtr) &mValueForScripts, keepReferences, kLEOChunkTypeINVALID, 0, 0, inContext );
}



void	CConcreteObject::DumpUserProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	for( auto itty = mUserProperties.begin(); itty != mUserProperties.end(); itty++ )
	{
		printf( "%s[%s] = %s\n", indentStr, itty->first.c_str(), itty->second.c_str() );
	}
}