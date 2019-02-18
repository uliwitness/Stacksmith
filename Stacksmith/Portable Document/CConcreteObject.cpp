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
		EHandlerEntryGroupHeader,
		0,
		"Card Events",
		"",
		"",
		"card",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"openCard",
		"The current card just changed, prepare this card for the user.",
		"",
		"card",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"closeCard",
		"The current card is about to change, last chance for clean-up.",
		"",
		"card",
		0
	},
	{
		EHandlerEntryGroupHeader,
		0,
		"Stack Events",
		"",
		"",
		"card",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"openStack",
		"The current stack just changed, prepare this stack for the user.",
		"",
		"card",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"focusWindow",
		"This stack's window is about to receive keyboard focus. Keypresses will go to objects on this card from now on.",
		"",
		"card",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"selectWindow",
		"This stack's window is about to become active. E.g. the window is brought to front. Not sent to floating palette windows.",
		"",
		"card",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"closeStack",
		"The current stack is about to change, last chance for clean-up.",
		"",
		"card",
		0
	},
	{
		EHandlerEntryGroupHeader,
		0,
		"Mouse Events",
		"",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUp",
		"React to a click in the card window.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDown",
		"React to the mouse being held down somewhere in the card window.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDrag",
		"The mouse is being held down and moving while over an object in the card window.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpOutside",
		"A click was started somewhere in the card window but not released inside that object.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpInLink",
		"A link in a text field was clicked. ",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleClick",
		"A double click in the card window completed.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseEnter",
		"The mouse arrow has moved onto an object in the card window.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseMove",
		"The mouse arrow has moved while over an object in the card window.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseLeave",
		"The mouse arrow has moved off an object in the card window after being inside.",
		"",
		"",
		0
	},
	{
		EHandlerEntryGroupHeader,
		0,
		"Movie Player Events",
		"",
		"",
		"moviePlayer",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"playMovie",
		"Playback of a movie player has started.",
		"",
		"moviePlayer",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"stopMovie",
		"Playback of a movie player has stopped.",
		"",
		"moviePlayer",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"timeChange",
		"The playback time of a movie player was changed (e.g. by dragging the playhead).",
		"",
		"moviePlayer",
		0
	},
	{
		EHandlerEntryGroupHeader,
		0,
		"Field Events",
		"",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"selectionChange",
		"The text selection in a text field has changed.",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpInLink",
		"A link in a text field was clicked. ",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"openField",
		"A text field has been given keyboard focus.",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"closeField",
		"A text field is about to lose keyboard focus.",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"textChange",
		"The text of a field was changed, by typing, pasteing or some other means.",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"keyDown",
		"A key was pressed on the keyboard.",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"tabKey",
		"The tab key was pressed on the keyboard.",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"arrowKey",
		"One of the arrow keys was pressed on the keyboard.",
		"",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"forwardDeleteKey",
		"The Forward Delete key was pressed (This key is usually between the alphabet keys and the number block, above the arrow keys, or what happens when you hold the fn key and press the backspace key on compact keyboards).",
		"\n\non forwardDeleteKey modifier1,modifier2,modifier3,modifier4\n\t\nend forwardDeleteKey",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"backspaceKey",
		"The Backspace (often called \"delete\") key was pressed (This key is usually right above the return key).",
		"\n\non backspaceKey modifier1,modifier2,modifier3,modifier4\n\t\nend backspaceKey",
		"field",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"functionKey",
		"One of the function keys was pressed on the keyboard.",
		"\n\non functionKey fKeyNumber,modifier1,modifier2,modifier3,modifier4\n\t\nend functionKey",
		"field",
		0
	},
	{
		EHandlerEntryGroupHeader,
		0,
		"Web Browser Events",
		"",
		"",
		"browser",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"loadPage",
		"The web page has finished loading.",
		"",
		"browser",
		0
	},
	{
		EHandlerEntryGroupHeader,
		0,
		"Editor Events",
		"",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDownWhilePeeking",
		"The mouse has been clicked while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDragWhilePeeking",
		"The mouse has been held and moved while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpWhilePeeking",
		"The mouse has been clicked while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleDownWhilePeeking",
		"The mouse has been double-clicked while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleClickWhilePeeking",
		"The mouse has been double-clicked while &quot;peeking&quot; (holding Option and Command to see the object outlines on the current card).",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDownWhileEditing",
		"The mouse has been clicked while the pointer tool is active.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDragWhileEditing",
		"The mouse has been held and moved while the pointer tool is active.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseUpWhileEditing",
		"The mouse has been clicked while the pointer tool is active.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleDownWhileEditing",
		"The mouse has been double-clicked while the pointer tool is active.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"mouseDoubleClickWhileEditing",
		"The mouse has been double-clicked while the pointer tool is active.",
		"",
		"",
		0
	},
	{
		EHandlerEntryCommand,
		kLEOHandlerIDINVALID,
		"selectionChangeWhileEditing",
		"The user somehow caused a different set of objects to be selected (have the dotted outline and resize handles) than before.",
		"",
		"",
		0
	},
	{
		EHandlerEntry_LAST,
		0,
		"",
		"",
		"",
		"",
		0
	}
};


std::vector<CAddHandlerListEntry>	CConcreteObject::GetAddHandlerList()
{
	bool	hadScript = (mScriptObject != NULL );
	if( !hadScript )
		GetScriptObject( [](const char*,size_t,size_t,CScriptableObject*){} );
	LEOContextGroup*	theGroup = GetScriptContextGroupObject();
	
	std::vector<CAddHandlerListEntry>	handlers;
	
	CAddHandlerListEntry	userHandlerGroupHeader;
	userHandlerGroupHeader.mType = EHandlerEntryGroupHeader;
	userHandlerGroupHeader.mHandlerName = "User-defined Handlers";
	
	// List all handlers for which this script contains documentation:
	for( CAddHandlerListEntry& currHandlerNote : mHandlerNotes )
	{
		if( currHandlerNote.mHandlerID == kLEOHandlerIDINVALID )
		{
			currHandlerNote.mHandlerID = LEOContextGroupHandlerIDForHandlerName( theGroup, currHandlerNote.mHandlerName.c_str() );
		}
		handlers.push_back(currHandlerNote);
	}
	
	// List all system-defined handlers that make sense for this object:
	for( size_t x = 0; sMasterHandlerList[x].mType != EHandlerEntry_LAST; x++ )
	{
		CAddHandlerListEntry&	currHandler = sMasterHandlerList[x];
		if( currHandler.mHandlerID == kLEOHandlerIDINVALID )	// First time iterating master table? Initialize some fields.
		{
			currHandler.mHandlerID = LEOContextGroupHandlerIDForHandlerName( theGroup, currHandler.mHandlerName.c_str() );
			
			if( currHandler.mHandlerTemplate.empty() )
			{
				std::stringstream	strstr;
				strstr << "on " << currHandler.mHandlerName << "\n\t\nend " << currHandler.mHandlerName;
				currHandler.mHandlerTemplate = strstr.str();
			}
		}
		
		// Only show handlers that are either usable from all object types, or specific to this one:
		if( currHandler.mTiedToType.empty() || ShowHandlersForObjectType(currHandler.mTiedToType) )
		{
			// Mark up handlers we already have:
			if( currHandler.mType == EHandlerEntryCommand )
			{
				bool	alreadyInScript = (mScriptObject != NULL && LEOScriptFindCommandHandlerWithID( mScriptObject, currHandler.mHandlerID ) != NULL);
				handlers.push_back( currHandler );
				handlers.back().mFlags |= alreadyInScript ? EHandlerListEntryAlreadyPresentFlag : 0;
			}
			else if( currHandler.mType == EHandlerEntryFunction )
			{
				bool	alreadyInScript = (mScriptObject != NULL && LEOScriptFindFunctionHandlerWithID( mScriptObject, currHandler.mHandlerID ) != NULL);
				handlers.push_back( currHandler );
				handlers.back().mFlags |= alreadyInScript ? EHandlerListEntryAlreadyPresentFlag : 0;
			}
			else if( currHandler.mType == EHandlerEntryGroupHeader )
			{
				if( !handlers.empty() && handlers.back().mType == EHandlerEntryGroupHeader )	// Previous group was empty? Remove it.
				{
					handlers.pop_back();
				}
				handlers.push_back( currHandler );
			}
		}
	}
	
	CAddHandlerListEntry	uPropHandler;
	uPropHandler.mType = EHandlerEntryGroupHeader;
	uPropHandler.mHandlerName = "User Properties";
	handlers.push_back(uPropHandler);
	
	uPropHandler.mType = EHandlerEntryCommand;
	for( std::pair<std::string,std::string> currProp : mUserProperties )
	{
		uPropHandler.mHandlerName = currProp.first;
		uPropHandler.mHandlerName.append("PropertyChange");
		uPropHandler.mHandlerID = LEOContextGroupHandlerIDForHandlerName( theGroup, uPropHandler.mHandlerName.c_str() );
		uPropHandler.mHandlerDescription = "Called whenever the property \"";
		uPropHandler.mHandlerDescription.append(currProp.first);
		uPropHandler.mHandlerDescription.append("\" is changed so you can react to that change.");
		uPropHandler.mHandlerTemplate = "on ";
		uPropHandler.mHandlerTemplate.append(uPropHandler.mHandlerName);
		uPropHandler.mHandlerTemplate.append("\n\t\nend ");
		uPropHandler.mHandlerTemplate.append(uPropHandler.mHandlerName);
		bool	alreadyInScript = (mScriptObject != NULL && LEOScriptFindCommandHandlerWithID( mScriptObject, uPropHandler.mHandlerID ) != NULL);
		handlers.push_back(uPropHandler);
		handlers.back().mFlags |= alreadyInScript ? EHandlerListEntryAlreadyPresentFlag : 0;
	}
	
	while( handlers.back().mType == EHandlerEntryGroupHeader )	// Last group was empty? Remove it.
	{
		handlers.pop_back();
	}
	
	if( !hadScript && mScriptObject )	// Get rid of script we compiled, so user sees parse errors when it's next parsed.
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
	
	return handlers;
}


LEOScript*	CConcreteObject::GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler )
{
	if( !mScriptObject )
	{
		const char*		scriptStr = mScript.c_str();
		uint16_t		fileID = LEOFileIDForFileName( GetDisplayName().c_str() );
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
			LEOCleanUpParseTree( parseTree );
			
			mHandlerNotes.erase( mHandlerNotes.begin(),mHandlerNotes.end());
			const char*	outHandlerName = NULL;
			const char*	outNote = NULL;
			size_t		x = 0;
			while( true )
			{
				LEOParserGetHandlerNoteAtIndex( x++, &outHandlerName, &outNote );
				if( !outHandlerName )
					break;
				CAddHandlerListEntry	handlerDocs;
				handlerDocs.mType = EHandlerEntry_LAST;
				handlerDocs.mHandlerName = outHandlerName;
				handlerDocs.mHandlerDescription = outNote;
				handlerDocs.mHandlerID = kLEOHandlerIDINVALID;
				handlerDocs.mFlags = EHandlerListEntryAlreadyPresentFlag;
				mHandlerNotes.push_back( handlerDocs );
			}
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
	else if( strcasecmp("script", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, mScript.c_str(), mScript.size(), kLEOInvalidateReferences, inContext );
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
			{
				inContext->flags |= kLEOContextKeepRunning;
				return true;
			}
			AddUserPropertyNamed( currPropName );
			if( theValue == &tmpStorage )
				LEOCleanUpValue( theValue, kLEOInvalidateReferences, inContext );
		}
		return true;
	}
	else if( strcasecmp("script", inPropertyName) == 0 )
	{
		char		scriptBuf[1024];
		const char*	scriptStr = LEOGetValueAsString( inValue, scriptBuf, sizeof(scriptBuf), inContext );
		SetScript( scriptStr );
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
	for( size_t x = 0; x < inIndex && foundProp != mUserProperties.end(); x++ )
		foundProp++;
	return foundProp->first;
}


bool	CConcreteObject::SetUserPropertyNameAtIndex( const char* inNewName, size_t inIndex )
{
	CMap<std::string>::iterator foundProp = mUserProperties.begin();
	for( size_t x = 0; x < inIndex && foundProp != mUserProperties.end(); x++ )
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
	
	char	msgName[1024] = {};
	snprintf( msgName, sizeof(msgName) -1, "%sPropertyChange", inPropName );
	SendMessage( NULL, [](const char *, size_t, size_t, CScriptableObject *, bool){}, EMayGoUnhandled, msgName );
	
//	DumpUserProperties(0);
	
	return true;
}


void	CConcreteObject::InitValue( LEOValuePtr outObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	if( mIDForScripts == kLEOObjectIDINVALID )
	{
		CScriptableObject::InitScriptableObjectValue( &mValueForScripts, this, kLEOInvalidateReferences, inContext );
		mIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( GetScriptContextGroupObject(), &mValueForScripts );
		mSeedForScripts = LEOContextGroupGetSeedForObjectID( GetScriptContextGroupObject(), mIDForScripts );
	}
	LEOInitReferenceValue( outObject, (LEOValuePtr) &mValueForScripts, keepReferences, kLEOChunkTypeINVALID, 0, 0, inContext );
}


void	CConcreteObject::InitObjectDescriptorValue( LEOValuePtr outObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	if( mObjectDescriptorIDForScripts == kLEOObjectIDINVALID )
	{
		CScriptableObject::InitObjectDescriptorValue( &mObjectDescriptorValueForScripts, this, kLEOInvalidateReferences, inContext );
		mObjectDescriptorIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( GetScriptContextGroupObject(), &mObjectDescriptorValueForScripts );
		mObjectDescriptorSeedForScripts = LEOContextGroupGetSeedForObjectID( GetScriptContextGroupObject(), mObjectDescriptorIDForScripts );
	}
	LEOInitReferenceValue( outObject, (LEOValuePtr) &mObjectDescriptorValueForScripts, keepReferences, kLEOChunkTypeINVALID, 0, 0, inContext );
}



void	CConcreteObject::DumpUserProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	for( auto itty = mUserProperties.begin(); itty != mUserProperties.end(); itty++ )
	{
		printf( "%s[%s] = %s\n", indentStr, itty->first.c_str(), itty->second.c_str() );
	}
}
