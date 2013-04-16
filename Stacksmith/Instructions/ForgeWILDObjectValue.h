//
//  ForgeWILDObjectValue.h
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

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
