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


void	CConcreteObject::DumpUserProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	for( auto itty = mUserProperties.begin(); itty != mUserProperties.end(); itty++ )
	{
		printf( "%s[%s] = %s\n", indentStr, itty->first.c_str(), itty->second.c_str() );
	}
}