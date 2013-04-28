//
//  WILDCard.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDBackground.h"
#import "WILDSearchContext.h"
#import "WILDObjectID.h"


@interface WILDCard : WILDLayer <WILDSearchable>
{
	WILDBackground	*	mOwner;
	BOOL				mMarked;
}

@property (assign) BOOL	marked;	// Don't set directly, ask the stack to do so.

-(id)						initWithXMLDocument: (NSXMLDocument*)elem forStack: (WILDStack*)theStack error: (NSError**)outError;

-(WILDObjectID)				backgroundID;	// ID of *owning* background.
-(WILDBackground*)			owningBackground;
-(void)						setOwningBackground: (WILDBackground*)theBg;

-(WILDObjectID)				cardID;			// ID of this card block.

-(NSInteger)				cardNumber;

-(void)						setTransitionType: (NSString*)inType subtype: (NSString*)inSubtype;

@end
