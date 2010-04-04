//
//  UKPropagandaWindowBodyView.h
//  Propaganda
//
//  Created by Uli Kusterer on 21.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class UKPropagandaCard;


@interface UKPropagandaWindowBodyView : NSView
{
	UKPropagandaCard*	mCard;
	BOOL				mPeeking;
	BOOL				mBackgroundEditMode;
}

-(void)					setCard: (UKPropagandaCard*)inCard;
-(UKPropagandaCard*)	card;

@end
