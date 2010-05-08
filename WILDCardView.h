//
//  WILDWindowBodyView.h
//  Propaganda
//
//  Created by Uli Kusterer on 21.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WILDCard;


@interface WILDCardView : NSView
{
	WILDCard*			mCard;
	BOOL				mPeeking;
	BOOL				mBackgroundEditMode;
}

-(void)					setCard: (WILDCard*)inCard;
-(WILDCard*)	card;

@end
