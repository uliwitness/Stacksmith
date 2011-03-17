//
//  WILDBackground.h
//  Stacksmith
//
//  Created by Uli Kusterer on 17.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLayer.h"


@class WILDCard;


@interface WILDBackground : WILDLayer
{
@private
    NSMutableArray	*	mCards;	// List of cards belonging to this background.
}

-(void)	addCard: (WILDCard*)theCard;
-(void)	removeCard: (WILDCard*)theCard;
-(BOOL)	hasCards;

@end
