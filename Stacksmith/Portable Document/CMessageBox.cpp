//
//  CMessageBox.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMessageBox.h"
#include "Forge.h"
#include "CDocument.h"
#include "CAlert.h"


using namespace Carlson;


static CMessageBox*		sMessageBox = NULL;


void	CMessageBox::SetSharedInstance( CMessageBox* inMsg )
{
	sMessageBox = inMsg;
}


CMessageBox*	CMessageBox::GetSharedInstance()
{
	return sMessageBox;
}


bool	CMessageBox::GetTextContents( std::string& outString )
{
	outString = mScript;
	
	return true;
}


bool	CMessageBox::SetTextContents( std::string inString )
{
	mScript = inString;
	
	if( mScriptObject )
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
	
	return true;
}


void	CMessageBox::Run()
{
	CAutoreleasePool	pool;
	LEOValue		returnValue = {{0}};
	char			returnValBuf[1024] = {0};
	SendMessage( &returnValue, [](const char * errMsg, size_t, size_t, CScriptableObject *){ if( errMsg ) CAlert::RunMessageAlert( errMsg ); }, ":run" );
	if( returnValue.base.isa != NULL )
	{
		const char*	resultString = LEOGetValueAsString( &returnValue, returnValBuf, sizeof(returnValBuf), NULL );
		SetTextContents( resultString );
		LEOCleanUpValue( &returnValue, kLEOInvalidateReferences, NULL );
	}
}


LEOScript*	CMessageBox::GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler )
{
	if( !mScriptObject )
	{
		const char*		scriptStr = mScript.c_str();
		uint16_t		fileID = LEOFileIDForFileName( "message box" );	// +++ TODO: Use long name!
		LEOParseTree*	parseTree = LEOParseTreeCreateForCommandOrExpressionFromUTF8Characters( scriptStr, strlen(scriptStr), fileID );
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


LEOContextGroup*	CMessageBox::GetScriptContextGroupObject()
{
	return CStack::GetFrontStack()->GetScriptContextGroupObject();
}


CScriptableObject*	CMessageBox::GetParentObject()
{
	return CStack::GetFrontStack()->GetCurrentCard();
}

