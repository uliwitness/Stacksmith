/*
 *  ForgeDownloadInstructionsStacksmith.m
 *  Leonie
 *
 *  Created by Uli Kusterer on 09.10.10.
 *  Copyright 2010 Uli Kusterer. All rights reserved.
 *
 */

/*!
	@header ForgeDownloadInstructionsStacksmith
	These functions implement the actual instructions the Leonie bytecode
	interpreter actually understands. Or at least those that are not portable
	between platforms.
*/

#import <Foundation/Foundation.h>
#import "Forge.h"
#import "UKHelperMacros.h"


static NSMutableArray	*	sRunningConnections = nil;


void	LEODownloadInstruction( LEOContext* inContext );


@interface WILDURLConnectionDelegate : NSObject <NSURLConnectionDelegate,NSURLConnectionDataDelegate>
{
	union LEOValue			mDestination;
	LEOScript			*	mOwningScript;
	NSString			*	mProgressMessage;
	NSString			*	mCompletionMessage;
	LEOContext				mContext;
	LEOValueArray			mDownloadArrayValue;	// Value for "the download" parameter, which is an array whose properties users can query.
	LEOValuePtr				mHeadersArrayValue;		// Sub-value of mDownloadArrayValue.
	NSInteger				mMaxBytes;
	NSMutableData		*	mDownloadedData;
}

@end


@implementation WILDURLConnectionDelegate

-(id)	initWithScript: (LEOScript*)inScript contextGroup: (LEOContextGroup*)inGroup
			progressMessage: (NSString*)inProgressMsg completionMessage: (NSString*)inCompletionMsg
			urlString: (NSString*)inURLString
{
	if(( self = [super init] ))
	{
		mMaxBytes = -1;
		LEOInitContext( &mContext, inGroup );
		mOwningScript = LEOScriptRetain( inScript );
		mProgressMessage = [inProgressMsg retain];
		mCompletionMessage = [inCompletionMsg retain];
		LEOInitArrayValue( &mDownloadArrayValue, NULL, kLEOInvalidateReferences, &mContext );
		LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "totalSize", -1, &mContext );
		LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "size", 0, &mContext );
		LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "statusCode", 0, &mContext );
		LEOAddCStringArrayEntryToRoot( &mDownloadArrayValue.array, "statusMessage", "", &mContext );
		LEOAddCStringArrayEntryToRoot( &mDownloadArrayValue.array, "url", [inURLString UTF8String], &mContext );
		LEOAddCStringArrayEntryToRoot( &mDownloadArrayValue.array, "address", [inURLString UTF8String], &mContext );
		mHeadersArrayValue = LEOAddArrayEntryToRoot( &mDownloadArrayValue.array, "headers", NULL, &mContext );
		LEOInitArrayValue( &mHeadersArrayValue->array, NULL, kLEOInvalidateReferences, &mContext );
	}
	
	return self;
}

-(void)	dealloc
{
	LEOCleanUpValue( &mDestination, kLEOInvalidateReferences, &mContext );
	if( mOwningScript )
		LEOScriptRelease(mOwningScript);
	DESTROY_DEALLOC(mProgressMessage);
	DESTROY_DEALLOC(mCompletionMessage);
	LEOCleanUpContext( &mContext );
	LEOCleanUpValue( &mDownloadArrayValue, kLEOInvalidateReferences, &mContext );
	mHeadersArrayValue = NULL;	// Was just disposed cuz it points into mDownloadArrayValue.
	
	[super dealloc];
}


-(void)	sendDownloadMessage: (NSString*)msgName forConnection: (NSURLConnection*)inConnection
{
	#if REMOTE_DEBUGGER
	mContext.preInstructionProc = LEORemoteDebuggerPreInstructionProc;
	mContext.promptProc = LEORemoteDebuggerPrompt;
	#endif
	
	LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "totalSize", mMaxBytes, &mContext );
	LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "size", mDownloadedData.length, &mContext );

	LEOPushEmptyValueOnStack( &mContext );	// Reserve space for return value.
	LEOPushValueOnStack( &mContext, (LEOValuePtr) &mDownloadArrayValue );
	LEOPushIntegerOnStack( &mContext, 1 );
	
	LEOHandlerID	handlerID = LEOContextGroupHandlerIDForHandlerName( mContext.group, [msgName UTF8String] );
	LEOHandler*		theHandler = LEOScriptFindCommandHandlerWithID( mOwningScript, handlerID );

	if( theHandler )
	{
		LEOContextPushHandlerScriptReturnAddressAndBasePtr( &mContext, theHandler, mOwningScript, NULL, NULL );	// NULL return address is same as exit to top. basePtr is set to NULL as well on exit.
		LEORunInContext( theHandler->instructions, &mContext );
	}
	if( mContext.errMsg[0] != 0 )
	{
		[inConnection cancel];
		[sRunningConnections removeObject: inConnection];
	}
}


-(void)	connection: (NSURLConnection *)connection didFailWithError: (NSError *)error
{
	[self sendDownloadMessage: mCompletionMessage forConnection: connection];
	[sRunningConnections removeObject: connection];
}


-(void)	connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)response
{
	mMaxBytes = [response expectedContentLength];
	if( [response respondsToSelector: @selector(allHeaderFields)] )
	{
		NSDictionary	*	headers = [(NSHTTPURLResponse*)response allHeaderFields];
		
		if( mMaxBytes < 0 )
		{
			NSString		*	theLengthString = [headers objectForKey: @"Content-Length"];
			if( theLengthString )
				mMaxBytes = [theLengthString integerValue];
		}
		
		for( NSString* currKey in headers )
		{
			const char*		currKeyCStr = [currKey UTF8String];
			id				valueObj = [headers objectForKey: currKey];
			const char*		valueCStr = [valueObj UTF8String];
			LEOAddCStringArrayEntryToRoot( &mHeadersArrayValue->array.array, currKeyCStr, valueCStr, &mContext );
		}
	}
	if( [response respondsToSelector: @selector(statusCode)] )
	{
		NSInteger	statusCode = [(id)response statusCode];
		LEOAddIntegerArrayEntryToRoot( &mDownloadArrayValue.array, "statusCode", statusCode, &mContext );
		const char*	errMsg = [[NSHTTPURLResponse localizedStringForStatusCode: statusCode] UTF8String];
		LEOAddCStringArrayEntryToRoot( &mDownloadArrayValue.array, "statusMessage", errMsg, &mContext );
	}
	
	[self sendDownloadMessage: mProgressMessage forConnection: connection];
}


-(void)	connection: (NSURLConnection *)connection didReceiveData: (NSData *)data
{
	if( !mDownloadedData )
		mDownloadedData = [data mutableCopy];
	else
		[mDownloadedData appendData: data];
	LEOSetValueAsString( &mDestination, [mDownloadedData bytes], mDownloadedData.length, &mContext );
	
	[self sendDownloadMessage: mProgressMessage forConnection: connection];
}


-(void)	connectionDidFinishLoading: (NSURLConnection *)connection
{
	[self sendDownloadMessage: mCompletionMessage forConnection: connection];
	[sRunningConnections removeObject: connection];
}

/*!
	Download a file from the web into a container, optionally executing code.
	We push 4 parameters on the stack before we call this instruction:
	
	url			- A string with the URL to download from.
	destination	- A container to download to. Must be something in global scope
				  e.g. a global field or the like.
	progress	- The message to send while downloading so progress can be
				  indicated. If this is "" no message is sent.
	completion	- The message to send once the download has completed or errored
				  out. If this is "" no message is sent.
*/

void	LEODownloadInstruction( LEOContext* inContext )
{
	// 1: URL
	char			urlBuf[1024] = { 0 };
	const char*		urlString = NULL;
	
	union LEOValue*	urlValue = inContext->stackEndPtr -4;
	if( urlValue == NULL || urlValue->base.isa == NULL )
	{
		LEOContextStopWithError( inContext, "Internal error: Invalid url value." );
		return;
	}
	urlString = LEOGetValueAsString( urlValue, urlBuf, sizeof(urlBuf), inContext );
	NSString			*	urlObjcString = [NSString stringWithCString: urlString encoding: NSUTF8StringEncoding];
	
	// 3: Progress message name
	char			progressBuf[1024] = { 0 };
	const char*		progressMsgString = NULL;
	
	union LEOValue*	progressMsgValue = inContext->stackEndPtr -2;
	if( progressMsgValue == NULL || progressMsgValue->base.isa == NULL )
	{
		LEOContextStopWithError( inContext, "Internal error: Invalid progress message value." );
		return;
	}
	progressMsgString = LEOGetValueAsString( progressMsgValue, progressBuf, sizeof(progressBuf), inContext );
	NSString			*	progressMsgObjcString = [NSString stringWithCString: progressMsgString encoding: NSUTF8StringEncoding];

	// 4: Completion message name:
	char			completionBuf[1024] = { 0 };
	const char*		completionMsgString = NULL;
	
	union LEOValue*	completionMsgValue = inContext->stackEndPtr -1;
	if( completionMsgValue == NULL || completionMsgValue->base.isa == NULL )
	{
		LEOContextStopWithError( inContext, "Internal error: Invalid completion message value." );
		return;
	}
	completionMsgString = LEOGetValueAsString( completionMsgValue, completionBuf, sizeof(completionBuf), inContext );
	NSString			*	completionMsgObjcString = [NSString stringWithCString: completionMsgString encoding: NSUTF8StringEncoding];
	
	// Create URL request object & delegate:
	LEOScript			*	theScript = LEOContextPeekCurrentScript( inContext );
	WILDURLConnectionDelegate*	theDelegate = [[[WILDURLConnectionDelegate alloc] initWithScript: theScript contextGroup: inContext->group progressMessage: progressMsgObjcString completionMessage: completionMsgObjcString urlString: urlObjcString] autorelease];
	
	// Now copy param 2, destination container value, to the delegate:
	union LEOValue*	containerValue = inContext->stackEndPtr -3;
	if( containerValue == NULL || containerValue->base.isa == NULL )
	{
		LEOContextStopWithError( inContext, "Internal error: Invalid dest value." );
		return;
	}
	LEOInitCopy( containerValue, &theDelegate->mDestination, kLEOInvalidateReferences, &theDelegate->mContext );
	
	// Start the download and finish this instruction:
	NSURLRequest		*	theRequest = [NSURLRequest requestWithURL: [NSURL URLWithString: urlObjcString]];
	NSURLConnection		*	conn = [NSURLConnection connectionWithRequest: theRequest delegate: theDelegate];
	if( !sRunningConnections )
		sRunningConnections = [[NSMutableArray alloc] init];
	[sRunningConnections addObject: conn];
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -4 );
	
	inContext->currentInstruction++;
}


@end



LEOINSTR_START(Download,LEO_NUMBER_OF_DOWNLOAD_INSTRUCTIONS)
LEOINSTR_LAST(LEODownloadInstruction)


