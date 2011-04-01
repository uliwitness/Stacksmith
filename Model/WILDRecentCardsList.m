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
        mRecentCardInfos = [[NSMutableArray alloc] init];
		
		mMaxRecentsToKeep = 7 * 6;	// HyperCard's "Recent" dialog has 7 columns & 6 rows.
    }
    
    return self;
}

-(void)	dealloc
{
	DESTROY( mRecentCardInfos );
	
    [super dealloc];
}


-(void)	addCard: (WILDCard*)inCard inCardView: (WILDCardView*)inCardView
{
	// Remove any previous entries for the same card. We only show each card once:
	NSUInteger	currIdx = 0;
	for( WILDRecentCardInfo * currInfo in mRecentCardInfos )
	{
		if( [currInfo card] == inCard )
		{
			[mRecentCardInfos removeObjectAtIndex: currIdx];
			break;
		}
		
		currIdx ++;
	}

	WILDRecentCardInfo	*	newInfo = [[[WILDRecentCardInfo alloc] init] autorelease];
	newInfo.card = inCard;
	newInfo.thumbnail = [inCardView thumbnailImage];
	newInfo.documentURL = [[[inCard stack] document] fileURL];
	[mRecentCardInfos addObject: newInfo];
	
	if( [mRecentCardInfos count] > mMaxRecentsToKeep )
		[mRecentCardInfos removeObjectAtIndex: 0];
}


-(void)	unloadCard: (WILDCard*)inCard
{
	for( WILDRecentCardInfo * currInfo in mRecentCardInfos )
	{
		if( [currInfo card] == inCard )
		{
			[currInfo setCard: nil];
			break;
		}
	}
}


-(void)	removeCard: (WILDCard*)inCard
{
	NSUInteger	currIdx = 0;
	for( WILDRecentCardInfo * currInfo in mRecentCardInfos )
	{
		if( [currInfo card] == inCard )
		{
			[mRecentCardInfos removeObjectAtIndex: currIdx];
			break;
		}
		
		currIdx ++;
	}
}


-(NSUInteger)	count
{
	return [mRecentCardInfos count];
}


-(WILDCard*)	cardAtIndex: (NSUInteger)inCardIndex
{
	return [[mRecentCardInfos objectAtIndex: inCardIndex] card];
}


-(NSImage*)		thumbnailForCardAtIndex: (NSUInteger)inCardIndex
{
	return [[mRecentCardInfos objectAtIndex: inCardIndex] thumbnail];
}

@end


@implementation WILDRecentCardInfo

@synthesize thumbnail;
@synthesize documentURL;
@synthesize cardID;
@synthesize card;

-(void)	dealloc
{
	DESTROY(thumbnail);
	DESTROY(documentURL);
	DESTROY(card);
	
	[super dealloc];
}

@end
