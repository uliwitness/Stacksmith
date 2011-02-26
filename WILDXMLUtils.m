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


BOOL	WILDBoolFromSubElementInElement( NSString* elemName, NSXMLElement* elem )
{
	NSArray*	items = [elem elementsForName: elemName];
	if( [items count] < 1 )
		return NO;
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
	NSXMLElement	*	subElem = [[elem elementsForName: elemName] objectAtIndex: 0];
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
	
	float				redValue, greenValue, blueValue;
	
	redValue = [[redElem stringValue] intValue];
	greenValue = [[greenElem stringValue] intValue];
	blueValue = [[blueElem stringValue] intValue];
	
	return [NSColor colorWithCalibratedRed: (redValue / 65535.0) green: (greenValue / 65535.0)
						blue: (blueValue / 65535.0) alpha: 1.0];
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


