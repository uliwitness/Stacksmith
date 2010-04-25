//
//  UKPropagandaCardWindowController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class UKPropagandaCardViewController;
@class UKPropagandaWindowBodyView;
@class UKPropagandaStack;


@interface UKPropagandaCardWindowController : NSWindowController
{
	UKPropagandaStack						*	mStack;
	IBOutlet UKPropagandaWindowBodyView		*	mView;
	IBOutlet UKPropagandaCardViewController	*	mCardViewController;
}

@end
