//
//  WILDCardView.h
//  Propaganda
//
//  Created by Uli Kusterer on 21.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDVisibleObject.h"


@class WILDCard;
@class WILDCardViewController;


@interface WILDCardView : NSView
{
	WILDCard				*mCard;
	BOOL					mPeeking;
	BOOL					mBackgroundEditMode;
	WILDCardViewController	*mOwner;	// Not retained.
	NSString				*mTransitionType;		// CATransition type to use for card changes.
	NSString				*mTransitionSubtype;	// CATransition subtype to use for card changes.
}

@property (copy)	NSString *	transitionType;
@property (copy)	NSString *	transitionSubtype;

-(void)						setCard: (WILDCard*)inCard;
-(WILDCard*)				card;

-(void)						setOwner: (WILDCardViewController*)inOwner;

-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind;

-(NSImage*)					snapshotImage;	// Full-size image of the entire card.
-(NSImage*)					thumbnailImage;	// Smaller size for use as a preview in lists etc.

@end
