//
//  WILDWindowBodyView.h
//  Propaganda
//
//  Created by Uli Kusterer on 21.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WILDCard;
@class WILDCardViewController;


@interface WILDCardView : NSView
{
	WILDCard*				mCard;
	BOOL					mPeeking;
	BOOL					mBackgroundEditMode;
	WILDCardViewController	*mOwner;	// Not retained.
}

-(void)					setCard: (WILDCard*)inCard;
-(WILDCard*)			card;

-(void)					setOwner: (WILDCardViewController*)inOwner;

@end
