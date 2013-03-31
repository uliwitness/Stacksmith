//
//  WILDXMLUtils.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDXMLUtils.h"


NSString*	WILDStringFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
{
	NSArray*	items = [elem elementsForName: elemName];
	if( [items count] < 1 )
		return nil;
	return [[items objectAtIndex: 0] stringValue];
}


BOOL	WILDBoolFromSubElementInElement( NSString* elemName, NSXMLElement* elem, BOOL defaultValue )
{
	NSArray*	items = [elem elementsForName: elemName];
	if( [items count] < 1 )
		return defaultValue;
	NSXMLElement*	container = [items objectAtIndex: 0];
	NSString*		tagName = [[container childAtIndex: 0] name];
	
	return [tagName isEqualToString: @"true"];
}


NSInteger	WILDIntegerFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
{
	NSArray*	items = [elem elementsForName: elemName];
	if( [items count] < 1 )
		return -1;
	return [[[items objectAtIndex: 0] stringValue] integerValue];
}


NSMutableArray*	WILDStringsFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
{
	NSArray			*	items = [elem elementsForName: elemName];
	NSMutableArray	*	subitems = [NSMutableArray arrayWithCapacity: [items count]];
	for( NSXMLElement* subElem in items )
	{
		[subitems addObject: [subElem stringValue]];
	}
	return subitems;
}


NSMutableArray*	WILDIntegersFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
{
	NSArray			*	items = [elem elementsForName: elemName];
	NSMutableArray	*	subitems = [NSMutableArray arrayWithCapacity: [items count]];
	for( NSXMLElement* subElem in items )
	{
		[subitems addObject: [NSNumber numberWithInteger: [[subElem stringValue] integerValue]] ];
	}
	return subitems;
}


NSSize	WILDSizeFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
{
	NSArray			*	subElemList = [elem elementsForName: elemName];
	if( [subElemList count] < 1 )
		return NSZeroSize;
	NSXMLElement	*	subElem = [subElemList objectAtIndex: 0];
	NSXMLElement	*	widthElem = [[subElem elementsForName: @"width"] objectAtIndex: 0];
	NSXMLElement	*	heightElem = [[subElem elementsForName: @"height"] objectAtIndex: 0];
	
	NSSize				theSize = NSZeroSize;
	
	theSize.width = [[widthElem stringValue] intValue];
	theSize.height = [[heightElem stringValue] intValue];
	
	return theSize;
}


NSRect	WILDRectFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
{
	NSArray			*	colorElems = [elem elementsForName: elemName];
	if( [colorElems count] == 0 )
		return NSZeroRect;
	
	NSXMLElement	*	subElem = [colorElems objectAtIndex: 0];
	NSXMLElement	*	leftElem = [[subElem elementsForName: @"left"] objectAtIndex: 0];
	NSXMLElement	*	topElem = [[subElem elementsForName: @"top"] objectAtIndex: 0];
	NSXMLElement	*	rightElem = [[subElem elementsForName: @"right"] objectAtIndex: 0];
	NSXMLElement	*	bottomElem = [[subElem elementsForName: @"bottom"] objectAtIndex: 0];
	
	NSRect			theRect = NSZeroRect;
	
	theRect.origin.x = [[leftElem stringValue] intValue];
	theRect.origin.y = [[topElem stringValue] intValue];
	theRect.size.width = [[rightElem stringValue] intValue] -theRect.origin.x;
	theRect.size.height = [[bottomElem stringValue] intValue] -theRect.origin.y;
	
	return theRect;
}


NSMutableIndexSet*	WILDIndexSetFromSubElementInElement( NSString* elemName, NSXMLElement* elem, NSInteger offsetIndexes )
{
	NSArray			*	colorElems = [elem elementsForName: elemName];
	if( [colorElems count] == 0 )
		return [NSIndexSet indexSet];
	
	NSXMLElement	*	subElem = [colorElems objectAtIndex: 0];
	NSMutableIndexSet*	indexes = [NSMutableIndexSet indexSet];
	
	for( NSXMLElement* currElem in [subElem elementsForName: @"integer"] )
	{
		NSInteger	theIdx = [[currElem stringValue] integerValue] +offsetIndexes;
		[indexes addIndex: theIdx];
	}
	
	return indexes;
}


NSColor*	WILDColorFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
{
	NSArray			*	colorElems = [elem elementsForName: elemName];
	if( [colorElems count] == 0 )
		return nil;
	
	NSXMLElement	*	subElem = [colorElems objectAtIndex: 0];
	NSXMLElement	*	redElem = [[subElem elementsForName: @"red"] objectAtIndex: 0];
	NSXMLElement	*	greenElem = [[subElem elementsForName: @"green"] objectAtIndex: 0];
	NSXMLElement	*	blueElem = [[subElem elementsForName: @"blue"] objectAtIndex: 0];
	NSArray			*	alphaElems = [subElem elementsForName: @"alpha"];
	NSXMLElement	*	alphaElem = ([alphaElems count] > 0) ? [alphaElems objectAtIndex: 0] : nil;
	
	float				redValue, greenValue, blueValue, alphaValue;
	
	redValue = [[redElem stringValue] intValue];
	greenValue = [[greenElem stringValue] intValue];
	blueValue = [[blueElem stringValue] intValue];
	alphaValue = alphaElem ? [[alphaElem stringValue] intValue] : 65535.0;
	
	return [NSColor colorWithCalibratedRed: (redValue / 65535.0) green: (greenValue / 65535.0)
						blue: (blueValue / 65535.0) alpha: (alphaValue / 65535.0)];
}


NSPoint	WILDPointFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
{
	NSArray			*	subs = [elem elementsForName: elemName];
	if( [subs count] < 1 )
		return NSZeroPoint;
	NSXMLElement	*	subElem = [subs objectAtIndex: 0];
	NSXMLElement	*	leftElem = [[subElem elementsForName: @"left"] objectAtIndex: 0];
	NSXMLElement	*	topElem = [[subElem elementsForName: @"top"] objectAtIndex: 0];
	
	NSPoint		thePoint = NSZeroPoint;
	
	thePoint.x = [[leftElem stringValue] intValue];
	thePoint.y = [[topElem stringValue] intValue];
	
	return thePoint;
}


//NSDictionary*	WILDTextStyleFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
//{
//	NSArray				*	styles = [elem elementsForName: elemName];
//	NSMutableDictionary	*	attrs = [NSMutableDictionary dictionary];
//	
//	for( NSXMLElement* currStyle in styles )
//	{
//		NSString*	currStyle = [currStyle stringValue];
//		
//		if( [currStyle isEqualToString: @"bold"] )
//			[attrs setObject:  forKey: NSBol];
//	}
//	
//	return attrs;
//}


NSString*	WILDStringEscapedForXML( NSString* inString )
{
	NSMutableString*	escapedString = [[inString mutableCopy] autorelease];
	[escapedString replaceOccurrencesOfString: @"&" withString: @"&amp;" options: 0 range: NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString: @">" withString: @"&gt;" options: 0 range: NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString: @"<" withString: @"&lt;" options: 0 range: NSMakeRange(0, [escapedString length])];
	return escapedString;
}


#define MAX_INDENT_LEVEL			20


static char	sIndentChars[MAX_INDENT_LEVEL +1] = { '\t', '\t', '\t', '\t', '\t',
									'\t', '\t', '\t', '\t', '\t',
									'\t', '\t', '\t', '\t', '\t',
									'\t', '\t', '\t', '\t', '\t', 0 };


void	WILDAppendLongLongXML( NSMutableString* inStringToAppendTo, int nestingLevel, long long inNum, NSString* inTagName )
{
	if( nestingLevel > MAX_INDENT_LEVEL )
		nestingLevel = MAX_INDENT_LEVEL;
	[inStringToAppendTo appendFormat: @"%3$s<%1$@>%2$lld</%1$@>\n", inTagName, inNum, (sIndentChars +MAX_INDENT_LEVEL -nestingLevel)];
}


void	WILDAppendLongXML( NSMutableString* inStringToAppendTo, int nestingLevel, long inNum, NSString* inTagName )
{
	if( nestingLevel > MAX_INDENT_LEVEL )
		nestingLevel = MAX_INDENT_LEVEL;
	[inStringToAppendTo appendFormat: @"%3$s<%1$@>%2$ld</%1$@>\n", inTagName, inNum, (sIndentChars +MAX_INDENT_LEVEL -nestingLevel)];
}


void	WILDAppendStringXML( NSMutableString* inStringToAppendTo, int nestingLevel, NSString* inString, NSString* inTagName )
{
	if( nestingLevel > MAX_INDENT_LEVEL )
		nestingLevel = MAX_INDENT_LEVEL;
	[inStringToAppendTo appendFormat: @"%3$s<%1$@>%2$@</%1$@>\n", inTagName, WILDStringEscapedForXML(inString), (sIndentChars +MAX_INDENT_LEVEL -nestingLevel)];
}


void	WILDAppendBoolXML( NSMutableString* inStringToAppendTo, int nestingLevel, BOOL inBool, NSString* inTagName )
{
	if( nestingLevel > MAX_INDENT_LEVEL )
		nestingLevel = MAX_INDENT_LEVEL;
	[inStringToAppendTo appendFormat: @"%3$s<%1$@>%2$@</%1$@>\n", inTagName, (inBool ? @"<true />" : @"<false />"), (sIndentChars +MAX_INDENT_LEVEL -nestingLevel)];
}


void	WILDAppendRectXML( NSMutableString* inStringToAppendTo, int nestingLevel, NSRect inBox, NSString* inTagName )
{
	if( nestingLevel > MAX_INDENT_LEVEL )
		nestingLevel = MAX_INDENT_LEVEL;
	[inStringToAppendTo appendFormat: @"%6$s<%1$@>\n%6$s\t<left>%2$d</left>\n%6$s\t<top>%3$d</top>\n%6$s\t<right>%4$d</right>\n%6$s\t<bottom>%5$d</bottom>\n%6$s</%1$@>\n",
											inTagName, (int)NSMinX(inBox), (int)NSMinY(inBox), (int)NSMaxX(inBox), (int)NSMaxY(inBox), (sIndentChars +MAX_INDENT_LEVEL -nestingLevel)];
}


void	WILDAppendColorXML( NSMutableString* inStringToAppendTo, int nestingLevel, NSColor* inColor, NSString* inTagName )
{
	if( nestingLevel > MAX_INDENT_LEVEL )
		nestingLevel = MAX_INDENT_LEVEL;
	
	inColor = [inColor colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	int		redColor = [inColor redComponent] * 65535.0;
	int		greenColor = [inColor greenComponent] * 65535.0;
	int		blueColor = [inColor blueComponent] * 65535.0;
	int		alphaColor = [inColor alphaComponent] * 65535.0;
	
	[inStringToAppendTo appendFormat: @"%2$s<%1$@>\n%2$s\t<red>%3$d</red>\n%2$s\t<green>%4$d</green>\n%2$s\t<blue>%5$d</blue>\n%2$s\t<alpha>%6$d</alpha>\n%2$s</%1$@>\n", inTagName, (sIndentChars +MAX_INDENT_LEVEL -nestingLevel), redColor, greenColor, blueColor, alphaColor];
}


void	WILDAppendSizeXML( NSMutableString* inStringToAppendTo, int nestingLevel, NSSize inSize, NSString* inTagName )
{
	if( nestingLevel > MAX_INDENT_LEVEL )
		nestingLevel = MAX_INDENT_LEVEL;
	
	[inStringToAppendTo appendFormat: @"%2$s<%1$@>\n%2$s\t<width>%3$d</width>\n%2$s\t<height>%4$d</height>\n%2$s</%1$@>\n", inTagName, (sIndentChars +MAX_INDENT_LEVEL -nestingLevel), (int)inSize.width, (int)inSize.height];
}




