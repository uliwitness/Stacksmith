//
//  WILDXMLUtils.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


NSString*			WILDStringFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSMutableArray*		WILDStringsFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSMutableArray*		WILDIntegersFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
BOOL				WILDBoolFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSInteger			WILDIntegerFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSSize				WILDSizeFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSRect				WILDRectFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSPoint				WILDPointFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSColor*			WILDColorFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSMutableIndexSet*	WILDIndexSetFromSubElementInElement( NSString* elemName, NSXMLElement* elem, NSInteger offsetIndexes );
