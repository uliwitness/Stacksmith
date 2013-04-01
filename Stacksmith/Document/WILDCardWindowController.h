//
//  WILDCardWindowController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDVisibleObject.h"


@class WILDCardViewController;
@class WILDWindowBodyView;
@class WILDStack;
@class WILDCard;


@interface WILDCardWindowController : NSWindowController <WILDVisibleObject>
{
	WILDStack						*	mStack;
	IBOutlet WILDWindowBodyView		*	mView;
	IBOutlet WILDCardViewController	*	mCardViewController;
}

-(id)			initWithStack: (WILDStack*)inStack;

-(WILDStack*)	stack;

-(void)			goToCard: (WILDCard*)inCard;

-(WILDCard*)	currentCard;

-(void)			setTransitionType: (NSString*)inType subtype: (NSString*)inSubtype;

-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind;

@end
