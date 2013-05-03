//
//  WILDScriptContainer.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDScriptContainer.h"
#import "LEOScript.h"
#import "LEOInterpreter.h"
#import "LEOContextGroup.h"
#import "LEORemoteDebugger.h"
#import "LEOInstructions.h"
#import "WILDCardViewController.h"
#import "WILDObjectValue.h"
#import "WILDStack.h"
#import <Carbon/Carbon.h>


NSString*	WILDScriptExecutionEventLoopMode = @"WILDScriptExecutionEventLoopMode";


BOOL	UKScanLineEnding( NSScanner* scanny, NSMutableString* outString, NSInteger* currentLine );
void	WILDCallNonexistentHandler( LEOContext* inContext, LEOHandlerID inHandler );


void	WILDScriptContainerUserDataCleanUp( void* inUserData )
{
	[(NSObject*)inUserData release];
}


@implementation WILDScriptContextUserData

@end

@implementation WILDSymbol

@synthesize lineIndex;
@synthesize symbolName;
@synthesize symbolType;

-(id)	initWithLine: (NSInteger)lineIdx symbolName: (NSString*)inName
			symbolType: (WILDSymbolType)inType
{
	if(( self = [super init] ))
	{
		lineIndex = lineIdx;
		symbolName = [inName retain];
		symbolType = inType;
	}
	
	return self;
}

-(void)	dealloc
{
	[symbolName release];
	symbolName = nil;
	
	[super dealloc];
}

@end


BOOL	UKScanLineEnding( NSScanner* scanny, NSMutableString* outString, NSInteger* currentLine )
{
	BOOL	didSomething = NO;
	
	while( YES )
	{
		if( [scanny scanString: @"\r" intoString: nil] )
		{
			[outString appendString: @"\r"];
			(*currentLine)++;
			[scanny scanString: @"\n" intoString: nil];
			[outString appendString: @"\n"];
			didSomething = YES;
		}
		else if( [scanny scanString: @"\n" intoString: nil] )
		{
			[outString appendString: @"\n"];
			(*currentLine)++;
			didSomething = YES;
		}
		else
			break;
	}
	
	return didSomething;
}


NSString*	WILDFormatScript( NSString* scriptString, NSArray* *outSymbols )
{
	NSMutableString	*		outString = [[[NSMutableString alloc] init] autorelease];
	NSMutableArray	*		symbols = [NSMutableArray array],
					*		openBlockNames = [NSMutableArray array];
	NSInteger				indentationLevel = 0,
							currentLine = 0;
	NSScanner*				scanny = [NSScanner scannerWithString: scriptString];
	NSCharacterSet	*		wsCS = [NSCharacterSet whitespaceCharacterSet],
					*		nlCS = [NSCharacterSet newlineCharacterSet],
					*		idCS = [NSCharacterSet characterSetWithCharactersInString: @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_1234567890"],
					*		nwsCS = [NSCharacterSet characterSetWithCharactersInString: @"-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_1234567890"];
	
	[scanny setCharactersToBeSkipped: nil];
	[scanny setCaseSensitive: NO];
	
	while( YES )
	{
		if( [scanny isAtEnd] )
			break;
		
		[scanny scanCharactersFromSet: wsCS intoString: nil];
		NSInteger	lineStart = [scanny scanLocation];
		NSInteger	addToIndentationAfterThisLine = 0;
		
		if( [scanny scanString: @"on" intoString: nil] )
		{
			NSString*	theName = nil;
			[scanny scanCharactersFromSet: wsCS intoString: nil];
			if( [scanny scanCharactersFromSet: idCS intoString: &theName] )
			{
				WILDSymbol*	sym = [[WILDSymbol alloc] initWithLine: currentLine
												symbolName: theName
												symbolType: WILDSymbolTypeHandler];
				[symbols addObject: sym];
				[sym release];
				[openBlockNames addObject: theName];
				addToIndentationAfterThisLine++;
			}
			[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
		}
		else if( [scanny scanString: @"function" intoString: nil] )
		{
			NSString*	theName = nil;
			[scanny scanCharactersFromSet: wsCS intoString: nil];
			if( [scanny scanCharactersFromSet: idCS intoString: &theName] )
			{
				WILDSymbol*	sym = [[WILDSymbol alloc] initWithLine: currentLine
												symbolName: theName
												symbolType: WILDSymbolTypeFunction];
				[symbols addObject: sym];
				[sym release];
				[openBlockNames addObject: theName];
				addToIndentationAfterThisLine++;
			}
			[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
		}
		else if( [scanny scanString: @"if" intoString: nil] )
		{
			[scanny scanCharactersFromSet: wsCS intoString: nil];
			while( YES )
			{
				[scanny scanCharactersFromSet: wsCS intoString: nil];
				if( [scanny scanString: @"--" intoString: nil] )	// Comment! Ignore rest of line!
				{
					[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
					UKScanLineEnding( scanny, outString, &currentLine );
				}
				else if( [scanny scanString: @"then" intoString: nil] )
				{
					if( ![scanny scanCharactersFromSet: idCS intoString: nil] )	// This is not just a string that contains "then", like "athena", right?
					{
						[scanny scanCharactersFromSet: wsCS intoString: nil];
						if( UKScanLineEnding( scanny, nil, &currentLine ) )	// NIL because otherwise it'll prefix the line breaks to this line, which is WRONG.
						{
							[openBlockNames addObject: @"if"];
							addToIndentationAfterThisLine++;
						}
						else	// One-line if, it seems:
						{
							// TODO: Need to remember lastIfLine here so we can have else after one-line-if:
							[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
						}
						break;
					}
				}
				else
				{
					if( [nwsCS characterIsMember: [scriptString characterAtIndex: [scanny scanLocation]]] )
						[scanny setScanLocation: [scanny scanLocation] +1];	// Skip one character, so we can get partial matches of comments.
					// This causes us to parse athena as a "then", so our "then" parsing above takes this into account.
					[scanny scanUpToCharactersFromSet: nwsCS intoString: nil];
				}
			}
		}
		else if( [scanny scanString: @"download" intoString: nil] )
		{
			[scanny scanCharactersFromSet: wsCS intoString: nil];
			while( YES )
			{
				[scanny scanCharactersFromSet: wsCS intoString: nil];
				if( [scanny scanString: @"--" intoString: nil] )	// Comment! Ignore rest of line!
				{
					[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
					UKScanLineEnding( scanny, outString, &currentLine );
				}
				else if( [scanny scanString: @"for" intoString: nil] )
				{
					if( ![scanny scanCharactersFromSet: idCS intoString: nil] )	// This is not just a string that contains "for", like "fort", right?
					{
						[scanny scanCharactersFromSet: wsCS intoString: nil];
						if( [scanny scanString: @"each" intoString: nil] )
						[scanny scanCharactersFromSet: wsCS intoString: nil];
						if( [scanny scanString: @"chunk" intoString: nil] )
						[scanny scanCharactersFromSet: wsCS intoString: nil];
						if( UKScanLineEnding( scanny, nil, &currentLine ) )	// NIL because otherwise it'll prefix the line breaks to this line, which is WRONG.
						{
							[openBlockNames addObject: @"download"];
							addToIndentationAfterThisLine++;
						}
						else	// One-line for each chunk, it seems:
						{
							// TODO: Need to remember lastDownloadLine here so we can have else after one-line-if:
							[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
						}
						break;
					}
				}
				else if( [scanny scanString: @"when" intoString: nil] )
				{
					if( ![scanny scanCharactersFromSet: idCS intoString: nil] )	// This is not just a string that contains "for", like "fort", right?
					{
						[scanny scanCharactersFromSet: wsCS intoString: nil];
						if( [scanny scanString: @"done" intoString: nil] )
						[scanny scanCharactersFromSet: wsCS intoString: nil];
						if( UKScanLineEnding( scanny, nil, &currentLine ) )	// NIL because otherwise it'll prefix the line breaks to this line, which is WRONG.
						{
							[openBlockNames addObject: @"download"];
							addToIndentationAfterThisLine++;
						}
						else	// One-line for each chunk, it seems:
						{
							// TODO: Need to remember lastDownloadLine here so we can have else after one-line-if:
							[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
						}
						break;
					}
				}
				else
				{
					if( [nwsCS characterIsMember: [scriptString characterAtIndex: [scanny scanLocation]]] )
						[scanny setScanLocation: [scanny scanLocation] +1];	// Skip one character, so we can get partial matches of comments.
					// This causes us to parse fort as a "for", so our "for" parsing above takes this into account.
					[scanny scanUpToCharactersFromSet: nwsCS intoString: nil];
				}
			}
		}
		else if( [scanny scanString: @"repeat" intoString: nil] )
		{
			[scanny scanCharactersFromSet: wsCS intoString: nil];
			[openBlockNames addObject: @"repeat"];
			[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
			addToIndentationAfterThisLine++;
		}
		else if( [scanny scanString: @"end" intoString: nil] )
		{
			NSString*	theName = nil;
			[scanny scanCharactersFromSet: wsCS intoString: nil];
			if( [scanny scanCharactersFromSet: idCS intoString: &theName] )
			{
				if( [[openBlockNames lastObject] caseInsensitiveCompare: theName] == NSOrderedSame )
				{
					[openBlockNames removeLastObject];
					indentationLevel--;
				}
			}
			[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
		}
		else if( [scanny scanString: @"else" intoString: nil] )
		{
			if( [[openBlockNames lastObject] caseInsensitiveCompare: @"if"] == NSOrderedSame )
			{
				indentationLevel--;
				addToIndentationAfterThisLine++;
			}
			[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
		}
		else if( [scanny scanString: @"when" intoString: nil] )
		{
			if( [[openBlockNames lastObject] caseInsensitiveCompare: @"download"] == NSOrderedSame )
			{
				indentationLevel--;
				addToIndentationAfterThisLine++;
			}
			[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
		}
		else
			[scanny scanUpToCharactersFromSet: nlCS intoString: nil];
		
		NSInteger	currPos = [scanny scanLocation];
		NSString*	thisLine = [scriptString substringWithRange: NSMakeRange( lineStart, currPos -lineStart )];
		for( NSInteger x = 0; x < indentationLevel; x++ )
			[outString appendString: @"\t"];
		[outString appendString: thisLine];
		
		indentationLevel += addToIndentationAfterThisLine;
		
		if( [scanny isAtEnd] )
			break;
		
		UKScanLineEnding( scanny, outString, &currentLine );
	}
	
	if( outSymbols )
		*outSymbols = symbols;
	
	return outString;
}


void	WILDPreInstructionProc( LEOContext * inContext )
{
#if 0
	NSEvent	*	evt = [[NSApplication sharedApplication] nextEventMatchingMask: NSKeyDownMask untilDate: [NSDate date] inMode: WILDScriptExecutionEventLoopMode dequeue: YES];
	if( evt )
	{
		NSString		*	theKeys = [evt charactersIgnoringModifiers];
		if( (evt.modifierFlags & NSCommandKeyMask) && theKeys.length > 0 && [theKeys characterAtIndex: 0] == '.' )
		{
			inContext->keepRunning = false;
			return;
		}
	}
#else
	KeyMap		keyStates;
	KeyMap		desiredKeyStates = { {0x00000000}, {0x00808000}, {0x00000000}, {0x00000000} };
	GetKeys( keyStates );
	if( keyStates[0].bigEndianValue == desiredKeyStates[0].bigEndianValue
		&& keyStates[1].bigEndianValue == desiredKeyStates[1].bigEndianValue
		&& keyStates[2].bigEndianValue == desiredKeyStates[2].bigEndianValue
		&& keyStates[3].bigEndianValue == desiredKeyStates[3].bigEndianValue )
	{
		inContext->keepRunning = false;
		return;
	}
#endif
	
	LEORemoteDebuggerPreInstructionProc( inContext );
}


void	WILDCallNonexistentHandler( LEOContext* inContext, LEOHandlerID inHandler )
{
	BOOL			handled = NO;
	LEOHandlerID	arrowKeyHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "arrowkey" );
	LEOHandlerID	keyDownHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "keydown" );
	LEOHandlerID	functionKeyHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "functionkey" );
	LEOHandlerID	openCardHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "opencard" );
	LEOHandlerID	closeCardHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "closecard" );
	LEOHandlerID	openStackHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "openstack" );
	LEOHandlerID	closeStackHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "closestack" );
	LEOHandlerID	mouseEnterHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mouseenter" );
	LEOHandlerID	mouseDownHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mousedown" );
	LEOHandlerID	mouseUpHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mouseup" );
	LEOHandlerID	mouseUpOutsideHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mouseupoutside" );
	LEOHandlerID	mouseLeaveHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mouseleave" );
	LEOHandlerID	mouseMoveHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mousemove" );
	LEOHandlerID	mouseDragHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mousedrag" );
	LEOHandlerID	loadPageHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "loadpage" );
	if( inHandler == arrowKeyHandlerID )
	{
		LEOValuePtr	directionParam = LEOGetParameterAtIndexFromEndOfStack( inContext, 0 );
		char		buf[40] = {};
		const char*	directionStr = LEOGetValueAsString( directionParam, buf, sizeof(buf), inContext );
		if( strcasecmp( directionStr, "left") )
		{
			[[NSApplication sharedApplication] sendAction: @selector(goPrevCard:) to: nil from: [NSApplication sharedApplication]];
			handled = YES;
		}
		else if( strcasecmp( directionStr, "right") )
		{
			[[NSApplication sharedApplication] sendAction: @selector(goNextCard:) to: nil from: [NSApplication sharedApplication]];
			handled = YES;
		}
		else if( strcasecmp( directionStr, "up") )
		{
			[[NSApplication sharedApplication] sendAction: @selector(goFirstCard:) to: nil from: [NSApplication sharedApplication]];
			handled = YES;
		}
		else if( strcasecmp( directionStr, "down") )
		{
			[[NSApplication sharedApplication] sendAction: @selector(goLastCard:) to: nil from: [NSApplication sharedApplication]];
			handled = YES;
		}
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	else if( inHandler == openCardHandlerID
			|| inHandler == closeCardHandlerID
			|| inHandler == openStackHandlerID
			|| inHandler == closeStackHandlerID
			|| inHandler == mouseEnterHandlerID
			|| inHandler == mouseDownHandlerID
			|| inHandler == mouseUpHandlerID
			|| inHandler == mouseUpOutsideHandlerID
			|| inHandler == mouseLeaveHandlerID
			|| inHandler == mouseMoveHandlerID
			|| inHandler == mouseDragHandlerID
			|| inHandler == functionKeyHandlerID
			|| inHandler == keyDownHandlerID
			|| inHandler == loadPageHandlerID )
	{
		handled = YES;
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	
	if( !handled )
		LEOContextStopWithError( inContext, "Couldn't find handler for %s.", LEOContextGroupHandlerNameForHandlerID( inContext->group, inHandler ) );
}


NSString*	WILDScriptContainerResultFromSendingMessage( id<WILDScriptContainer,WILDObject> container, NSString* fmt, ... )
{
#if 0
	#define DBGLOGPAR(args...)	NSLog(args)
#else
	#define DBGLOGPAR(args...)	
#endif

	LEOScript*	theScript = [container scriptObjectShowingErrorMessage: YES];
	NSString*	resultString = nil;
	LEOContext	ctx;
	NSArray*	parts = [fmt componentsSeparatedByString: @" "];
	NSString*	msg = [parts objectAtIndex: 0];
	size_t		bytesNeeded = 0;
	
	if( !theScript )
		return nil;
	
	WILDScriptContextUserData	*	ud = [[WILDScriptContextUserData alloc] init];
	LEOInitContext( &ctx, [container scriptContextGroupObject], ud, WILDScriptContainerUserDataCleanUp );
	ud.currentStack = container.parentObject.stack;
	ud.target = container;
	#if REMOTE_DEBUGGER
	ctx.preInstructionProc = WILDPreInstructionProc;
	ctx.promptProc = LEORemoteDebuggerPrompt;
	#endif
	ctx.callNonexistentHandlerProc = WILDCallNonexistentHandler;
	
	LEOPushEmptyValueOnStack( &ctx );	// Reserve space for return value.
		
	if( [parts count] > 1 )
	{
		// Calculate how much space we need for params temporarily:
		NSArray	*	paramFormats = [[parts objectAtIndex: 1] componentsSeparatedByString: @","];
		DBGLOGPAR( @"%@ %@", msg, paramFormats );
		for( NSString* currPart in paramFormats )
		{
			currPart = [currPart stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
			if( [currPart isEqualToString: @"%@"] )
				bytesNeeded += sizeof(NSString*);
			else if( [currPart isEqualToString: @"%s"] )
				bytesNeeded += sizeof(const char*);
			else if( [currPart isEqualToString: @"%ld"] )
				bytesNeeded += sizeof(long);
			else if( [currPart isEqualToString: @"%d"] )
				bytesNeeded += sizeof(int);
			else if( [currPart isEqualToString: @"%f"] )
				bytesNeeded += sizeof(double);
			else if( [currPart isEqualToString: @"%B"] )
				bytesNeeded += sizeof(BOOL);
			else
				[NSException raise: @"WILDMessageSendFormatException" format: @"Internal error: Unknown format qualifier '%@' in message send.", currPart];
		}
		
		// Grab the params in correct order into our temp buffer:
		if( bytesNeeded > 0 )
		{
			char	*	theBytes = calloc( bytesNeeded, 1 );
			char	*	currPos = theBytes;
			va_list		ap;
			va_start( ap, fmt );
				for( NSString* currPart in paramFormats )
				{
					currPart = [currPart stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
					if( [currPart isEqualToString: @"%@"] )
					{
						NSString	*	currStr = va_arg( ap, NSString* );
						DBGLOGPAR(@"\"%@\"", currStr);
						* ((NSString**)currPos) = currStr;
						currPos += sizeof(NSString*);
					}
					else if( [currPart isEqualToString: @"%s"] )
					{
						const char*		currCStr = va_arg( ap, const char* );
						DBGLOGPAR(@"\"%s\"", currCStr);
						* ((const char**)currPos) = currCStr;
						currPos += sizeof(NSString*);
					}
					else if( [currPart isEqualToString: @"%ld"] )
					{
						long	currLong  = va_arg( ap, long );
						DBGLOGPAR(@"%ld", currLong);
						* ((long*)currPos) = currLong;
						currPos += sizeof(long);
					}
					else if( [currPart isEqualToString: @"%d"] )
					{
						int		currInt = va_arg( ap, int );
						DBGLOGPAR(@"%d", currInt);
						* ((int*)currPos) = currInt;
						currPos += sizeof(int);
					}
					else if( [currPart isEqualToString: @"%f"] )
					{
						double	currDouble = va_arg( ap, double );
						DBGLOGPAR(@"%f", currDouble);
						* ((double*)currPos) = currDouble;
						currPos += sizeof(double);
					}
					else if( [currPart isEqualToString: @"%B"] )
					{
						BOOL	currBool = va_arg( ap, int );	// BOOL gets promoted to int.
						DBGLOGPAR(@"%s", currBool ? "YES" : "NO");
						* ((BOOL*)currPos) = currBool;
						currPos += sizeof(BOOL);
					}
					else
						DBGLOGPAR( @"Internal error: Unknown format '%@' in message send.", currPart );
				}
			va_end(ap);

			// Push the params in reverse order:
			currPos = theBytes +bytesNeeded;
			for( NSString* currPart in [paramFormats reverseObjectEnumerator] )
			{
				currPart = [currPart stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
				if( [currPart isEqualToString: @"%@"] )
				{
					currPos -= sizeof(NSString*);
					NSString	*	currStr = *(NSString**)currPos;
					DBGLOGPAR(@"pushed \"%@\"", currStr);
					const char	*	str = [currStr UTF8String];
					LEOPushStringValueOnStack( &ctx, str, str? strlen(str) : 0 );
				}
				else if( [currPart isEqualToString: @"%s"] )
				{
					currPos -= sizeof(const char*);
					const char* str = *((const char**)currPos);
					DBGLOGPAR(@"pushed \"%s\"", str ? str : "(null)");
					LEOPushStringValueOnStack( &ctx, str, str? strlen(str) : 0 );
				}
				else if( [currPart isEqualToString: @"%ld"] )
				{
					currPos -= sizeof(long);
					long	currLong = *((long*)currPos);
					DBGLOGPAR( @"pushed %ld", currLong );
					LEOPushIntegerOnStack( &ctx, currLong );
				}
				else if( [currPart isEqualToString: @"%d"] )
				{
					currPos -= sizeof(int);
					int	currInt = *((int*)currPos);
					DBGLOGPAR( @"pushed %d", currInt );
					LEOPushIntegerOnStack( &ctx, currInt );
				}
				else if( [currPart isEqualToString: @"%f"] )
				{
					currPos -= sizeof(double);
					double	currDouble = *((double*)currPos);
					DBGLOGPAR( @"pushed %f", currDouble );
					LEOPushNumberOnStack( &ctx, currDouble );
				}
				else if( [currPart isEqualToString: @"%B"] )
				{
					currPos -= sizeof(BOOL);
					BOOL	currBool = (*((BOOL*)currPos)) == YES;
					DBGLOGPAR( @"pushed %s", currBool ? "YES" : "NO" );
					LEOPushBooleanOnStack( &ctx, currBool );
				}
				else
					NSLog( @"Internal error: push failed for message send. Invalid format." );
			}
			
			NSInteger	numParams = [paramFormats count];
			DBGLOGPAR( @"pushed PC %ld", numParams );
			LEOPushIntegerOnStack( &ctx, numParams );
			
			if( theBytes )
				free(theBytes);
			theBytes = NULL;
			currPos = NULL;
		}
		else
		{
			DBGLOGPAR(@"Internal error: Invalid format string in message send.");
			LEOPushIntegerOnStack( &ctx, 0 );
		}
	}
	else
		LEOPushIntegerOnStack( &ctx, 0 );
	
	// Send message:
	LEOHandlerID	handlerID = LEOContextGroupHandlerIDForHandlerName( [container scriptContextGroupObject], [msg UTF8String] );
	LEOHandler*		theHandler = NULL;
	while( !theHandler )
	{
		theHandler = LEOScriptFindCommandHandlerWithID( theScript, handlerID );

		if( theHandler )
		{
			LEOContextPushHandlerScriptReturnAddressAndBasePtr( &ctx, theHandler, theScript, NULL, NULL );	// NULL return address is same as exit to top. basePtr is set to NULL as well on exit.
			LEORunInContext( theHandler->instructions, &ctx );
			if( ctx.errMsg[0] != 0 )
				break;
		}
		if( !theHandler )
		{
			if( theScript->GetParentScript )
				theScript = theScript->GetParentScript( theScript, &ctx );
			if( !theScript )
			{
				if( ctx.callNonexistentHandlerProc )
					ctx.callNonexistentHandlerProc( &ctx, handlerID );
				break;
			}
		}
	}
	if( ctx.errMsg[0] != 0 )
	{
		NSRunAlertPanel( @"Script Error", @"%@", @"OK", @"", @"", [NSString stringWithCString: ctx.errMsg encoding: NSUTF8StringEncoding] );
	}
	else if( ctx.stackEndPtr != ctx.stack )
	{
		char	returnValue[1024] = { 0 };
		LEOGetValueAsString( ctx.stack, returnValue, sizeof(returnValue), &ctx );
		resultString = [[[NSString alloc] initWithBytes: returnValue length: strlen(returnValue) encoding: NSUTF8StringEncoding] autorelease];
	}
	
	LEOCleanUpContext( &ctx );
	
	return resultString;
}

