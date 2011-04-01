//
//  WILDRecentCardsList.h
//  Stacksmith
//
//  Created by Uli Kusterer on 31.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

/*
	Keep a list of cards with thumbnail images for display in a "cards you visited"
	dialog.
 */

#import <AppKit/AppKit.h>
#import "WILDObjectID.h"


@class WILDCard;
@class WILDCardView;


@interface WILDRecentCardsList : NSObject
{
@private
	NSMutableArray		*	mRecentCardInfos;		// WILDRecentCardInfo* array.
	NSUInteger				mMaxRecentsToKeep;		// Maximum number of items in list before we start removing old ones.
}

@property (assign) NSUInteger	maxRecentsToKeep;

+(WILDRecentCardsList*)	sharedRecentCardsList;

-(void)	addCard: (WILDCard*)inCard inCardView: (WILDCardView*)inCardView;
-(void)	removeCard: (WILDCard*)inCard;

-(NSUInteger)	count;
-(WILDCard*)	cardAtIndex: (NSUInteger)inCardIndex;
-(NSImage*)		thumbnailForCardAtIndex: (NSUInteger)inCardIndex;

@end


@interface WILDRecentCardInfo : NSObject
{
	NSImage		*		thumbnail;		// Thumbnail to show in recents list.
	NSURL		*		documentURL;	// To get back to a closed stack.
	WILDObjectID		cardID;			// To get back to a closed stack's card.
	WILDCard	*		card;			// If still loaded, this is the card for quick access.
}

@property (retain) NSImage		*	thumbnail;
@property (retain) NSURL		*	documentURL;
@property (assign) WILDObjectID		cardID;
@property (retain) WILDCard		*	card;

@end