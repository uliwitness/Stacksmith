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


@class WILDCard;
@class WILDCardView;


@interface WILDRecentCardsList : NSObject
{
@private
    NSMutableArray		*	mRecentCards;			// WILDCard* array.
	NSMutableArray		*	mRecentCardThumbnails;	// NSImage* array.
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
