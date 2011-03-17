//
//  WILDScriptContainer.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDScriptContainer.h"


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
