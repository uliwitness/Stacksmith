//
//  WILDObjectValue.h
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

/*!
	@header WILDObjectValue
	This file contains everything that is needed to interface Stacksmith's
	Objective-C object hierarchy (buttons, fields, cards) with the Leonie bytecode
	interpreter. A protocol that the Objective-C objects conform to, to allow
	performing common operations on them (like retrieve property values, change
	their value, call handlers in their scripts, add user properties etc.
	
	So that the Leonie bytecode interpreter can deal with objects of this type,
	it also defines kLeoValueTypeWILDObject, which is like a native object, but
	guarantees that the object conforms to the WILDObject protocol and is an
	Objective-C object (the same could be done with C++ objects in other hosts
	or on other platforms).
	
	You can create such a value using the <tt>LEOInitWILDObjectValue</tt> function,
	just like any other values.
*/

#include "LEOValue.h"
#import <Foundation/Foundation.h>
#import "UKHelperMacros.h"


extern struct LEOValueType	kLeoValueTypeWILDObject;


@protocol WILDObject <NSObject>

// The BOOL returns on these methods indicate whether the given object can do
//	what was asked (as in, ever). So if a property doesn't exist, they'd return
//	NO. If an object has no contents, the same.

-(NSString*)	textContents;
-(BOOL)			setTextContents: (NSString*)inString;

-(BOOL)			goThereInNewWindow: (BOOL)inNewWindow;

-(id)				valueForWILDPropertyNamed: (NSString*)inPropertyName ofRange: (NSRange)byteRange;
-(LEOValueTypePtr)	typeForWILDPropertyNamed: (NSString*)inPropertyName;
-(BOOL)				setValue: (id)inValue forWILDPropertyNamed: (NSString*)inPropertyName inRange: (NSRange)byteRange;

-(struct LEOScript*)	scriptObjectShowingErrorMessage: (BOOL)showError;
-(id<WILDObject>)		parentObject;

@optional
-(BOOL)				deleteWILDObject;

-(void)				addUserPropertyNamed: (NSString*)userPropName;
-(void)				deleteUserPropertyNamed: (NSString*)userPropName;
-(NSMutableArray*)	allUserProperties;	// Each item is a dictionary with property name and value. For use by userProp editor GUI. This is a mutable copy of internal storage, changing it won't change the object.
-(void)				setValue: (NSString*)inValue forUserPropertyNamed: (NSString*)inName oldName: (NSString*)inOldName;	// inOldName == nil if you're not renaming. For use by userProp editor GUI.

@end


void				LEOInitWILDObjectValue( struct LEOValueObject* inStorage, id<WILDObject> wildObject, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );
struct LEOScript*	LEOForgeScriptGetParentScript( struct LEOScript* inScript, struct LEOContext* inContext );


extern NSString*	WILDUserPropertyNameKey;
extern NSString*	WILDUserPropertyValueKey;
