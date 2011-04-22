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
-(void)			setTextContents: (NSString*)inString;

-(void)			goThereInNewWindow: (BOOL)inNewWindow;

-(id)			valueForWILDPropertyNamed: (NSString*)inPropertyName;
-(void)			setObject: (id)inValue forWILDPropertyNamed: (NSString*)inPropertyName;

@end


void	LEOInitWILDObjectValue( LEOValuePtr inStorage, id<WILDObject> wildObject, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );
