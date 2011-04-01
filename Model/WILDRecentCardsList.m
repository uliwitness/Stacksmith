//
//  WILDRecentCardsList.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDRecentCardsList.h"


static WILDRecentCardsList	*	sSharedRecentCardsList = nil;


@implementation WILDRecentCardsList

@synthesize maxRecentsToKeep = mMaxRecentsToKeep;

+(WILDRecentCardsList*)	sharedRecentCardsList
{
	if( !sSharedRecentCardsList )
	{
		sSharedRecentCardsList = [[WILDRecentCardsList alloc] init];
	}
	
	return sSharedRecentCardsList;
}

-(id)	init
{
    self = [super init];
    if( self )
	{
        mRecentCards = [[NSMutableArray alloc] init];
        mRecentCardThumbnails = [[NSMutableArray alloc] init];
		
		mMaxRecentsToKeep = 7 * 6;	// HyperCard's "Recent" dialog has 7 columns & 6 rows.
    }
    
    return self;
}

-(void)	dealloc
{
	DESTROY( mRecentCards );
	
    [super dealloc];
}


-(void)	addCard: (WILDCard*)inCard inCardView: (WILDCardView*)inCardView
{
	NSUInteger	idx = [mRecentCards indexOfObject: inCard];
	if( idx != NSNotFound )
	{
		[mRecentCards removeObjectAtIndex: idx];
		[mRecentCardThumbnails removeObjectAtIndex: idx];
	}
	[mRecentCards addObject: inCard];
	[mRecentCardThumbnails addObject: [inCardView thumbnailImage]];
	
	if( [mRecentCards count] > mMaxRecentsToKeep )
	{
		[mRecentCards removeObjectAtIndex: 0];
		[mRecentCardThumbnails removeObjectAtIndex: 0];
	}
}


-(void)	removeCard: (WILDCard*)inCard
{
	NSUInteger	idx = [mRecentCards indexOfObject: inCard];
	if( idx != NSNotFound )
	{
		[mRecentCards removeObjectAtIndex: idx];
		[mRecentCardThumbnails removeObjectAtIndex: idx];
	}
}


-(NSUInteger)	count
{
	return [mRecentCards count];
}


-(WILDCard*)	cardAtIndex: (NSUInteger)inCardIndex
{
	return [mRecentCards objectAtIndex: inCardIndex];
}


-(NSImage*)		thumbnailForCardAtIndex: (NSUInteger)inCardIndex
{
	return [mRecentCardThumbnails objectAtIndex: inCardIndex];
}

@end
