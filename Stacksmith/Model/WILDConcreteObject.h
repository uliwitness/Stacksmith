//
//  WILDConcreteObject.h
//  Stacksmith
//
//  Created by Uli Kusterer on 01.05.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WILDScriptContainer.h"
#import "WILDObjectValue.h"


@class WILDDocument;


@interface WILDConcreteObject : NSObject <WILDScriptContainer,WILDObject>
{
	CFMutableDictionaryRef		mPropertyTypes;
	NSMutableDictionary*		mPropertyNames;
	
	struct LEOScript*			mScriptObject;		// Compiled script, lazily created/recreated on changes.

	NSMutableDictionary		*	mUserProperties;

	LEOObjectID					mIDForScripts;		// The ID Leonie uses to refer to this object.
	LEOObjectSeed				mSeedForScripts;	// The seed value to go with mIDForScripts.
	struct LEOValueObject		mValueForScripts;	// A LEOValue so scripts can reference us (see mIDForScripts).
	
	NSString				*	mName;
	NSString				*	mScript;
}

@property (copy,nonatomic)	NSString	*	name;
@property (copy,nonatomic)	NSString	*	script;

-(WILDDocument*)	document;
-(void)				updateChangeCount: (NSDocumentChangeType)inChange;

-(NSString*)		propertyWillChangeNotificationName;
-(NSString*)		propertyDidChangeNotificationName;

-(void)				getID: (LEOObjectID*)outID seedForScripts: (LEOObjectSeed*)outSeed;
-(void)				getPropertyTypes: (CFMutableDictionaryRef*)outPropertyTypes names: (NSMutableDictionary**)outPropertyNames;
@end


// Macros for defining property mappings more safely than writing manual code:
//	PROPERTY_MAP_START
//		PROPERTY_MAPPING(userLevel,"userlevel",kLeoValueTypeInteger)
//	PROPERTY_MAP_END

#define PROPERTY_MAP_START	-(void)	getPropertyTypes: (CFMutableDictionaryRef*)outPropertyTypes names: (NSMutableDictionary**)outPropertyNames \
{ \
static CFMutableDictionaryRef	sPropertyTypes = NULL; \
static NSMutableDictionary*		sPropertyNames = nil; \
if( !sPropertyTypes ) \
{ \
sPropertyTypes = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFCopyStringDictionaryKeyCallBacks, NULL ); \
sPropertyNames = [[NSMutableDictionary alloc] init];

#define PROPERTY_MAPPING(objCName,lowercaseHammerName,type)			\
CFDictionaryAddValue( sPropertyTypes, CFSTR(lowercaseHammerName), &type ); \
[sPropertyNames setObject: PROPERTY(objCName) forKey: @ lowercaseHammerName];


#define PROPERTY_MAP_END		\
} \
\
*outPropertyNames = [sPropertyNames retain]; \
*outPropertyTypes = (CFMutableDictionaryRef) CFRetain( sPropertyTypes ); \
}



