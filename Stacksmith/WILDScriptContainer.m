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


NSString*	WILDScriptContainerResultFromSendingMessage( id<WILDScriptContainer> container, NSString* fmt, ... )
{
	LEOScript*	theScript = [container scriptObjectShowingErrorMessage: YES];
	NSString*	resultString = nil;
	LEOContext	ctx;
	NSArray*	parts = [fmt componentsSeparatedByString: @" "];
	NSString*	msg = [parts objectAtIndex: 0];
	size_t		bytesNeeded = 0;
	
	if( !theScript )
		return nil;
	
	LEOInitContext( &ctx, [container scriptContextGroupObject] );
	#if REMOTE_DEBUGGER
	ctx.preInstructionProc = LEORemoteDebuggerPreInstructionProc;
	ctx.promptProc = LEORemoteDebuggerPrompt;
	#endif
	
	LEOPushEmptyValueOnStack( &ctx );	// Reserve space for return value.
		
	if( [parts count] > 1 )
	{
		// Calculate how much space we need for params temporarily:
		NSArray	*	paramFormats = [[parts objectAtIndex: 1] componentsSeparatedByString: @","];
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
		}
		
		// Grab the params in correct order into our temp buffer:
		char	*	theBytes = calloc( bytesNeeded, 1 );
		char	*	currPos = theBytes;
		va_list		ap;
		va_start( ap, fmt );
			for( NSString* currPart in paramFormats )
			{
				currPart = [currPart stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
				if( [currPart isEqualToString: @"%@"] )
				{
					* (NSString**)currPos = va_arg( ap, NSString* );
					currPos += sizeof(NSString*);
				}
				else if( [currPart isEqualToString: @"%s"] )
				{
					* (const char**)currPos = va_arg( ap, const char* );
					currPos += sizeof(NSString*);
				}
				else if( [currPart isEqualToString: @"%ld"] )
				{
					* (long*)currPos = va_arg( ap, long );
					currPos += sizeof(long);
				}
				else if( [currPart isEqualToString: @"%d"] )
				{
					* (int*)currPos = va_arg( ap, int );
					currPos += sizeof(int);
				}
				else if( [currPart isEqualToString: @"%f"] )
				{
					* (double*)currPos = va_arg( ap, double );
					currPos += sizeof(double);
				}
				else if( [currPart isEqualToString: @"%B"] )
				{
					* (BOOL*)currPos = va_arg( ap, BOOL );
					currPos += sizeof(BOOL);
				}
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
				const char*		str = [(NSString*)*currPos UTF8String];
				LEOPushStringValueOnStack( &ctx, str, strlen(str) );
			}
			else if( [currPart isEqualToString: @"%s"] )
			{
				currPos -= sizeof(const char*);
				LEOPushStringValueOnStack( &ctx, *currPos, strlen(*currPos) );
			}
			else if( [currPart isEqualToString: @"%ld"] )
			{
				currPos -= sizeof(long);
				LEOPushIntegerOnStack( &ctx, *(long*)currPos );
			}
			else if( [currPart isEqualToString: @"%d"] )
			{
				currPos -= sizeof(int);
				LEOPushIntegerOnStack( &ctx, *(int*)currPos );
			}
			else if( [currPart isEqualToString: @"%f"] )
			{
				currPos -= sizeof(double);
				LEOPushNumberOnStack( &ctx, *(double*)currPos );
			}
			else if( [currPart isEqualToString: @"%B"] )
			{
				currPos -= sizeof(BOOL);
				LEOPushBooleanOnStack( &ctx, (*(BOOL*)currPos) == YES );
			}
			
			LEOPushIntegerOnStack( &ctx, [paramFormats count] );
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
				break;
		}
	}
	if( ctx.errMsg[0] != 0 )
		NSRunAlertPanel( @"Script Error", @"%@", @"OK", @"", @"", [NSString stringWithCString: ctx.errMsg encoding: NSUTF8StringEncoding] );
	else if( ctx.stackEndPtr != ctx.stack )
	{
		char	returnValue[1024] = { 0 };
		LEOGetValueAsString( ctx.stack, returnValue, sizeof(returnValue), &ctx );
		resultString = [[[NSString alloc] initWithBytes: returnValue length: strlen(returnValue) encoding: NSUTF8StringEncoding] autorelease];
	}
	
	LEOCleanUpContext( &ctx );
	
	return resultString;
}

