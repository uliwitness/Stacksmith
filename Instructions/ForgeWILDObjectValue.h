//
//  ForgeWILDObjectValue.h
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "LEOValue.h"


extern struct LEOValueType	kLeoValueTypeWILDObject;


@protocol WILDObject <NSObject>

-(NSString*)	textContents;
-(BOOL)			setTextContents: (NSString*)inString;

-(BOOL)			goThereInNewWindow: (BOOL)inNewWindow;

-(id)			valueForWILDPropertyNamed: (NSString*)inPropertyName;
-(BOOL)			setValue: (id)inValue forWILDPropertyNamed: (NSString*)inPropertyName;

@end


void	LEOInitWILDObjectValue( LEOValuePtr inStorage, id<WILDObject> wildObject, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );
