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


bool	CMessageBox::SetTextContents( const std::string& inString )
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
	char				returnValBuf[1024] = {0};
	LEOContext	*		ctx = NULL;
	SendMessage( &ctx, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMustBeHandled, ":run" );
	if( ctx && ctx->stackEndPtr != ctx->stack && ctx->stack[0].base.isa != NULL )
	{
		if( !LEOGetValueIsUnset( &ctx->stack[0], NULL ) )
		{
			const char*	resultString = LEOGetValueAsString( &ctx->stack[0], returnValBuf, sizeof(returnValBuf), ctx );
			if( (ctx->flags & kLEOContextKeepRunning) == 0 )
				SetResultText( ctx->errMsg );
			else
				SetResultText( resultString );
		}
	}
	if( ctx )
		LEOContextRelease(ctx);
}


void	CMessageBox::ContextCompleted( LEOContext *ctx )
{
    if( ctx && ctx->stackEndPtr != ctx->stack && ctx->stack[0].base.isa != NULL )
    {
        //LEODebugPrintContext(ctx);
        char		returnValBuf[1024] = {0};
        if( (ctx->flags & kLEOContextKeepRunning) == 0 )
            SetResultText( ctx->errMsg );
        else if( !LEOGetValueIsUnset( &ctx->stack[0], NULL ) )
        {
            const char*	resultString = LEOGetValueAsString( &ctx->stack[0], returnValBuf, sizeof(returnValBuf), ctx );
            SetResultText( resultString );
        }
    }
    
    CScriptableObject::ContextCompleted( ctx );
}


LEOScript*	CMessageBox::GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler )
{
	if( !mScriptObject )
	{
		const char*		scriptStr = mScript.c_str();
		uint16_t		fileID = LEOFileIDForFileName( "message box" );
		LEOParseTree*	parseTree = LEOParseTreeCreateForCommandOrExpressionFromUTF8Characters( scriptStr, strlen(scriptStr), fileID );
		if( LEOParserGetLastErrorMessage() == NULL )
		{
			LEOContextGroup*	contextGroup = GetScriptContextGroupObject();
			if( contextGroup != mLastContextGroup )
			{
				if( mLastContextGroup )
				{
					LEOContextGroupRecycleObjectID( mLastContextGroup, mIDForScripts );
					LEOContextGroupRelease(mLastContextGroup);
				}
				mLastContextGroup = LEOContextGroupRetain( contextGroup );
				InitScriptableObjectValue( &mValueForScripts, this, kLEOInvalidateReferences, NULL );
				mIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( mLastContextGroup, &mValueForScripts );
				mSeedForScripts = LEOContextGroupGetSeedForObjectID( mLastContextGroup, mIDForScripts );
			}
			mScriptObject = LEOScriptCreateForOwner( mIDForScripts, mSeedForScripts, GetParentScript );
			LEOScriptCompileAndAddParseTree( mScriptObject, mLastContextGroup, parseTree, fileID );
			
			LEOCleanUpParseTree( parseTree );
			
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
	CStack*	theStack = CStack::GetMainStack();
	if( !theStack )
		theStack = CStack::GetActiveStack();
	if( !theStack )
		theStack = CDocumentManager::GetSharedDocumentManager()->GetHomeDocument()->GetStack(0);
	return theStack->GetScriptContextGroupObject();
}


CScriptableObject*	CMessageBox::GetParentObject( CScriptableObject* previousParent, LEOContext * ctx )
{
	CScriptableObject * frontObj = GetNextFrontScript( ctx );
	if( frontObj ) // We're doing frontscripts?
		return frontObj; // Return next frontscript, not our parent.
	
	CStack*	theStack = CStack::GetActiveStack();
	if( !theStack )
		theStack = CDocumentManager::GetSharedDocumentManager()->GetHomeDocument()->GetStack(0);
	CCard* theCard = theStack->GetCurrentCard();
	if( !theCard )
	{
		theCard = theStack->GetCard(0);
		theStack->GoThereInNewWindow( EOpenInNewWindow, nullptr, nullptr, [](){}, "", EVisualEffectSpeedNormal );
	}
	return theCard;
}

