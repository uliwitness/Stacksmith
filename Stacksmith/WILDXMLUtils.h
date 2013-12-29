//
//  WILDXMLUtils.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#if __cplusplus
extern "C" {
#endif


// Calls for reading:
NSString*			WILDStringFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSMutableArray*		WILDStringsFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSMutableArray*		WILDIntegersFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
BOOL				WILDBoolFromSubElementInElement( NSString* elemName, NSXMLElement* elem, BOOL defaultValue );
NSInteger			WILDIntegerFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
int					WILDIntFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSSize				WILDSizeFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSRect				WILDRectFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSPoint				WILDPointFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSColor*			WILDColorFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSMutableIndexSet*	WILDIndexSetFromSubElementInElement( NSString* elemName, NSXMLElement* elem, NSInteger offsetIndexes );

// Calls for writing:
void		WILDAppendLongLongXML( NSMutableString* inStringToAppendTo, int nestingLevel, long long inNum, NSString* inTagName );
void		WILDAppendLongXML( NSMutableString* inStringToAppendTo, int nestingLevel, long inNum, NSString* inTagName );
void		WILDAppendStringXML( NSMutableString* inStringToAppendTo, int nestingLevel, NSString* inString, NSString* inTagName );	// Calls WILDStringEscapedForXML on inString.
void		WILDAppendBoolXML( NSMutableString* inStringToAppendTo, int nestingLevel, BOOL inBool, NSString* inTagName );
void		WILDAppendRectXML( NSMutableString* inStringToAppendTo, int nestingLevel, NSRect inBox, NSString* inTagName );
void	WILDAppendColorXML( NSMutableString* inStringToAppendTo, int nestingLevel, NSColor* inColor, NSString* inTagName );
void	WILDAppendSizeXML( NSMutableString* inStringToAppendTo, int nestingLevel, NSSize inSize, NSString* inTagName );
NSString*	WILDStringEscapedForXML( NSString* inString, NSString** outBinaryAttribute );
NSString*	WILDStringEscapedForXMLAttribute( NSString* inString );


#if __cplusplus
}
#endif

