/*
 *  WILDDownloadInstructions.m
 *  Stacksmith
 *
 *  Created by Uli Kusterer on 09.10.10.
 *  Copyright 2010 Uli Kusterer. All rights reserved.
 *
 */

/*!
	@header WILDDownloadInstructions
	The 'download' command is built into Forge at the moment (as it requires
	support for parsing nested callback handlers). However, the act of downloading
	itself is most easily implemented with platform-specific commands (the only
	other option would be using raw socket calls).
	
	This header implements the platform-specific instructions that the 'download'
	command generates, both for the actual command, and for the 'the downloads'
	global property that indicates which downloads are in progress at the moment.
	
	To make the Forge parser use these instructions and properties, register
	them using
	<pre>LEOAddInstructionsToInstructionArray( gDownloadInstructions, LEO_NUMBER_OF_DOWNLOAD_INSTRUCTIONS, &kFirstDownloadInstruction );
	LEOAddGlobalPropertiesAndOffsetInstructions( gDownloadGlobalProperties, kFirstDownloadInstruction );</pre>
*/

#import <Foundation/Foundation.h>
#import "Forge.h"
#import "UKHelperMacros.h"
#import "CScriptableObjectValue.h"
#include <objc/runtime.h>


using namespace Carlson;


// Array in which we keep track of all running connections, so we can return
//	this information in 'the downloads'.
static NSMutableArray	*	sRunningConnections = nil;

static void	*				kURLSessionAssociatedObjectKey = &kURLSessionAssociatedObjectKey;


void	LEODownloadInstruction( LEOContext* inContext );
void	LEOPushDownloadsInstruction( LEOContext* inContext );


// Delegate class that remembers the context/context group, destination value,
//	callback handler names and actual downloaded data so we can notify the script
//	of download progress and actually make the downloaded data available to it.
@interface WILDURLConnectionDelegate : NSObject <NSURLSessionDelegate,NSURLSessionDataDelegate>
{
	union LEOValue			mDestination;
	LEOScript			*	mOwningScript;
	NSString			*	mProgressMessage;
	NSString			*	mCompletionMessage;
	LEOContext			*	mContext;
	LEOValueArray			mDownloadArrayValue;	// Value for "the download" parameter, which is an array whose properties users can query.
	LEOValuePtr				mHeadersArrayValue;		// Sub-value of mDownloadArrayValue.
	NSMutableData		*	mDownloadedData;
}

@end


@implementation WILDURLConnectionDelegate

-(id)	initWithScript: (LEOScript*)inScript contextGroup: (LEOContextGroup*)inGroup
			progressMessage: (NSString*)inProgressMsg completionMessage: (NSString*)inCompletionMsg
			urlString: (NSString*)inURLString scriptUserData: (CScriptContextUserData*)inUserData
{
	if(( self = [super init] ))
	{
		CScriptContextUserData	*	ud = new CScriptContextUserData( inUserData->GetStack(), inUserData->GetDocument(), inUserData->GetTarget(), inUserData->GetOwner() );
		mContext = LEOContextCreate( inGroup, ud, CScriptContextUserData::CleanUp );
		mOwningScript = LEOScriptRetain( inScript );
		mProgressMessage = [inProgressMsg copy];
		mCompletionMessage = [inCompletionMsg copy];
		LEOInitArrayValue( &mDownloadArrayValue, NULL, kLEOInvalidateReferences, mContext );
		LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "totalSize", -1, kLEOUnitBytes, mContext );
		LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "size", 0, kLEOUnitBytes, mContext );
		LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "statusCode", 0, kLEOUnitNone, mContext );
		LEOAddCStringArrayEntryToRoot( &mDownloadArrayValue.array, "statusMessage", "", mContext );
		LEOAddCStringArrayEntryToRoot( &mDownloadArrayValue.array, "url", [inURLString UTF8String], mContext );
		LEOAddCStringArrayEntryToRoot( &mDownloadArrayValue.array, "address", [inURLString UTF8String], mContext );
		mHeadersArrayValue = LEOAddArrayEntryToRoot( &mDownloadArrayValue.array, "headers", NULL, mContext );
		LEOInitArrayValue( &mHeadersArrayValue->array, NULL, kLEOInvalidateReferences, mContext );
	}
	
	return self;
}

-(void)	dealloc
{
	DESTROY_DEALLOC(mDownloadedData);
	LEOCleanUpValue( &mDestination, kLEOInvalidateReferences, mContext );
	if( mOwningScript )
		LEOScriptRelease(mOwningScript);
	DESTROY_DEALLOC(mProgressMessage);
	DESTROY_DEALLOC(mCompletionMessage);
	LEOCleanUpValue( &mDownloadArrayValue, kLEOInvalidateReferences, mContext );
	mHeadersArrayValue = NULL;	// Was just disposed cuz it points into mDownloadArrayValue.
	LEOContextRelease( mContext );
	mContext = NULL;
	
	[super dealloc];
}


-(void)	sendDownloadMessage: (NSString*)msgName forConnection: (NSURLSessionTask*)inConnection
{
	#if REMOTE_DEBUGGER
	mContext->preInstructionProc = CScriptableObject::PreInstructionProc;
	mContext->promptProc = LEORemoteDebuggerPrompt;
	#elif COMMAND_LINE_DEBUGGER
	mContext->preInstructionProc =  LEODebuggerPreInstructionProc;
	mContext->promptProc = LEODebuggerPrompt;
	#endif
	
	LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "totalSize", inConnection.countOfBytesExpectedToReceive, kLEOUnitBytes, mContext );
	LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "size", inConnection.countOfBytesReceived, kLEOUnitBytes, mContext );

	LEOPushEmptyValueOnStack( mContext );	// Reserve space for return value.
	LEOPushValueOnStack( mContext, (LEOValuePtr) &mDownloadArrayValue );
	LEOPushIntegerOnStack( mContext, 1, kLEOUnitNone );
	
	LEOHandlerID	handlerID = LEOContextGroupHandlerIDForHandlerName( mContext->group, [msgName UTF8String] );
	LEOHandler*		theHandler = LEOScriptFindCommandHandlerWithID( mOwningScript, handlerID );

	if( mContext->group->messageSent )
		mContext->group->messageSent( handlerID, mContext, mContext->group );
	if( theHandler )
	{
		LEOContextPushHandlerScriptReturnAddressAndBasePtr( mContext, theHandler, mOwningScript, NULL, NULL );	// NULL return address is same as exit to top. basePtr is set to NULL as well on exit.
		LEORunInContext( theHandler->instructions, mContext );
	}
	if( mContext->errMsg[0] != 0 )
	{
		[inConnection cancel];
		[sRunningConnections removeObject: inConnection];
	}
}


-(void)	URLSession: (NSURLSession *)session dataTask: (NSURLSessionDataTask *)dataTask
                                 didReceiveResponse: (NSURLResponse *)response
                                  completionHandler: (void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
	long long	maxBytes = [response expectedContentLength];
	if( [response respondsToSelector: @selector(allHeaderFields)] )
	{
		NSDictionary	*	headers = [(NSHTTPURLResponse*)response allHeaderFields];
		
		if( maxBytes < 0 )
		{
			NSString		*	theLengthString = [headers objectForKey: @"Content-Length"];
			if( theLengthString )
				maxBytes = [theLengthString longLongValue];
		}
		
		for( NSString* currKey in headers )
		{
			const char*		currKeyCStr = [currKey UTF8String];
			id				valueObj = [headers objectForKey: currKey];
			const char*		valueCStr = [valueObj UTF8String];
			LEOAddCStringArrayEntryToRoot( &mHeadersArrayValue->array.array, currKeyCStr, valueCStr, mContext );
		}
	}
	if( [response respondsToSelector: @selector(statusCode)] )
	{
		NSInteger	statusCode = [(id)response statusCode];
		LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "statusCode", statusCode, kLEOUnitNone, mContext );
		const char*	errMsg = [[NSHTTPURLResponse localizedStringForStatusCode: statusCode] UTF8String];
		LEOAddCStringArrayEntryToRoot( &mDownloadArrayValue.array, "statusMessage", errMsg, mContext );
	}
	
	[self sendDownloadMessage: mProgressMessage forConnection: dataTask];
	
	completionHandler( NSURLSessionResponseAllow );
}


-(void)	URLSession: (NSURLSession *)session dataTask: (NSURLSessionDataTask *)dataTask didReceiveData: (NSData *)data
{
	if( !mDownloadedData )
	{
		mDownloadedData = [NSMutableData new];
	}
	[mDownloadedData appendData: data];
	LEOSetValueAsString( &mDestination, (const char*)[mDownloadedData bytes], mDownloadedData.length, mContext );
	
	[self sendDownloadMessage: mProgressMessage forConnection: dataTask];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                           didCompleteWithError:(nullable NSError *)error
{
	if( error )
	{
		LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "statusCode", error.code, kLEOUnitBytes, mContext );
		LEOAddCStringArrayEntryToRoot( &mDownloadArrayValue.array, "statusMessage", error.localizedDescription.UTF8String, mContext );
	}
	objc_setAssociatedObject( self, kURLSessionAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN );
	[self sendDownloadMessage: mCompletionMessage forConnection: task];
	[sRunningConnections removeObject: task];
	[session finishTasksAndInvalidate];
}


/*!
	Instruction function used by the Leonie bytecode interpreter to download a
	file from the web into a container, optionally executing code.
	We push 4 parameters on the stack before we call this instruction:
	
	url			- A string with the URL to download from.
	
	destination	- A container to download to. Must be something in global scope
				  e.g. a global field or the like.
				  
	progress	- The message to send while downloading so progress can be
				  indicated. If this is "" no message is sent.
				  
	completion	- The message to send once the download has completed or errored
				  out. If this is "" no message is sent.
	
	(DOWNLOAD_INSTR)
*/

void	LEODownloadInstruction( LEOContext* inContext )
{
	// 1: URL
	char			urlBuf[1024] = { 0 };
	const char*		urlString = NULL;
	
	union LEOValue*	urlValue = inContext->stackEndPtr -4;
	if( urlValue == NULL || urlValue->base.isa == NULL )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid url value." );
		return;
	}
	urlString = LEOGetValueAsString( urlValue, urlBuf, sizeof(urlBuf), inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return;
		
	NSString			*	urlObjcString = [NSString stringWithCString: urlString encoding: NSUTF8StringEncoding];
	
	// 3: Progress message name
	char			progressBuf[1024] = { 0 };
	const char*		progressMsgString = NULL;
	
	union LEOValue*	progressMsgValue = inContext->stackEndPtr -2;
	if( progressMsgValue == NULL || progressMsgValue->base.isa == NULL )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid progress message value." );
		return;
	}
	progressMsgString = LEOGetValueAsString( progressMsgValue, progressBuf, sizeof(progressBuf), inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return;
	NSString			*	progressMsgObjcString = [NSString stringWithUTF8String: progressMsgString];

	// 4: Completion message name:
	char			completionBuf[1024] = { 0 };
	const char*		completionMsgString = NULL;
	
	union LEOValue*	completionMsgValue = inContext->stackEndPtr -1;
	if( completionMsgValue == NULL || completionMsgValue->base.isa == NULL )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid completion message value." );
		return;
	}
	completionMsgString = LEOGetValueAsString( completionMsgValue, completionBuf, sizeof(completionBuf), inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return;
	NSString			*	completionMsgObjcString = [NSString stringWithUTF8String: completionMsgString];
	
	// Create URL request object & delegate:
	LEOScript			*		theScript = LEOContextPeekCurrentScript( inContext );
	WILDURLConnectionDelegate*	theDelegate = [[[WILDURLConnectionDelegate alloc] initWithScript: theScript contextGroup: inContext->group progressMessage: progressMsgObjcString completionMessage: completionMsgObjcString urlString: urlObjcString scriptUserData: (CScriptContextUserData*) inContext->userData] autorelease];
	
	// Now copy param 2, destination container value, to the delegate:
	union LEOValue*	containerValue = inContext->stackEndPtr -3;
	if( containerValue == NULL || containerValue->base.isa == NULL )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid dest value." );
		return;
	}
	LEOInitCopy( containerValue, &theDelegate->mDestination, kLEOInvalidateReferences, theDelegate->mContext );
	
	// Start the download and finish this instruction:
	NSURL				*	theURL = [NSURL URLWithString: urlObjcString];
	if( !theURL )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Invalid URL '%s' passed to 'download' command.", urlString );
		return;
	}
	
	NSURLSession		*	downloadInstructionSession = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] delegate: theDelegate delegateQueue: [NSOperationQueue mainQueue]] retain];
	
	NSURLRequest		*	theRequest = [NSURLRequest requestWithURL: theURL];
	NSURLSessionDataTask *	theTask = [downloadInstructionSession dataTaskWithRequest: theRequest];
	objc_setAssociatedObject( theTask, kURLSessionAssociatedObjectKey, downloadInstructionSession, OBJC_ASSOCIATION_RETAIN );
	
	if( !sRunningConnections )
		sRunningConnections = [[NSMutableArray alloc] init];
	[sRunningConnections addObject: theTask];
	[theTask resume];
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -4 );
	
	inContext->currentInstruction++;
}

@end


void	LEOPushDownloadsInstruction( LEOContext* inContext )
{
	struct LEOArrayEntry *downloadsArray = NULL;
	
	int	currIdx = 0;
	for( NSURLSessionDataTask* conn in sRunningConnections )
	{
		char	currIdxStr[40] = {};
		snprintf( currIdxStr, sizeof(currIdxStr)-1, "%d", ++currIdx );
		LEOAddCStringArrayEntryToRoot( &downloadsArray, currIdxStr, conn.originalRequest.URL.absoluteString.UTF8String, inContext );
	}
	
	LEOInitArrayValue( &inContext->stackEndPtr->array, downloadsArray, kLEOInvalidateReferences, inContext );
	inContext->stackEndPtr++;
	
	inContext->currentInstruction++;
}


LEOINSTR_START(Download,LEO_NUMBER_OF_DOWNLOAD_INSTRUCTIONS)
LEOINSTR(LEODownloadInstruction)
LEOINSTR_LAST(LEOPushDownloadsInstruction)


struct TGlobalPropertyEntry	gDownloadGlobalProperties[] =
{
	{ EDownloadsIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_DOWNLOADS_INSTR },
	{ ELastIdentifier_Sentinel, ELastIdentifier_Sentinel, INVALID_INSTR, INVALID_INSTR }
};


