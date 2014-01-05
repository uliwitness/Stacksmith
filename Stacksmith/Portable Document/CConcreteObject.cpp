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
}


LEOContextGroup*	CConcreteObject::GetScriptContextGroupObject()
{
	return mDocument->GetScriptContextGroupObject();
}


struct LEOScript*	CConcreteObject::GetScriptObject( std::function<void(const char*,size_t,size_t,CConcreteObject*)> errorHandler )
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
		else
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
		std::string		propName = currUserPropNameNode ? CTinyXMLUtils::EnsureNonNULLString(currUserPropNameNode->GetText()) : std::string();
		currUserPropNameNode = currUserPropNameNode->NextSiblingElement();
		std::string		propValue = currUserPropNameNode ? CTinyXMLUtils::EnsureNonNULLString(currUserPropNameNode->GetText()) : std::string();
		currUserPropNameNode = currUserPropNameNode->NextSiblingElement();
		
		mUserProperties[propName] = propValue;
	}
}


void	CConcreteObject::DumpUserProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	for( auto itty = mUserProperties.begin(); itty != mUserProperties.end(); itty++ )
	{
		printf( "%s[%s] = %s\n", indentStr, itty->first.c_str(), itty->second.c_str() );
	}
}