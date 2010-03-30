//
//  UKPropagandaXMLUtils.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


NSString*			UKPropagandaStringFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSMutableArray*		UKPropagandaStringsFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSMutableArray*		UKPropagandaIntegersFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
BOOL				UKPropagandaBoolFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSInteger			UKPropagandaIntegerFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSSize				UKPropagandaSizeFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSRect				UKPropagandaRectFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSPoint				UKPropagandaPointFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSColor*			UKPropagandaColorFromSubElementInElement( NSString* elemName, NSXMLElement* elem );
NSMutableIndexSet*	UKPropagandaIndexSetFromSubElementInElement( NSString* elemName, NSXMLElement* elem, NSInteger offsetIndexes );
