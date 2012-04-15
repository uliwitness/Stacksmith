//
//  WILDSearchContext.h
//  Propaganda
//
//  Created by Uli Kusterer on 27.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

/*
	This file implements searching for text in Stacksmith. It consists of a
	protocol every searchable object should implement, that makes it possible
	to ask it for the next result.
*/

#import <Cocoa/Cocoa.h>


@class WILDCard;
@class WILDPart;


// Flags to pass to searchForPattern:withContext:flags:
//	No flags means we should do a simple substring search.
enum
{
	WILDSearchBackwards			= (1 << 0),		// Search for the result *preceding* this one, not the next one.
	WILDSearchWholeWords		= (1 << 1),		// Search for whole words, delimited by spaces, punctuation etc.
	WILDSearchCaseInsensitive	= (1 << 2)		// Ignore case differences.
};
typedef uint32_t WILDSearchFlags;



// This is passed to searchForPattern:withContext:flags: to provide context for the current search:
//	It keeps track of the last search result, so we can continue our search there.
@interface WILDSearchContext : NSObject
{
	WILDCard*		mStartCard;				// So we can detect end of search.
	WILDCard*		mCurrentCard;			// The card on which we found a part that matches.
	WILDPart*		mCurrentPart;			// The part in which we found the result.
	NSRange			mCurrentResultRange;	// We continue search after this range, we highlight this range.
}

@property (assign)	WILDCard*		startCard;			// So we can detect end of search. If the target is a card and this contains NIL, the card is the first card visited in the search, and it should set this and mCurrentCard to point to it.
@property (assign)	WILDCard*		currentCard;		// The card on which we found a part that matches. If the target is a card and this contains another card, the target should set this to point to it and start a new search.
@property (assign)	WILDPart*		currentPart;		// The part in which we found the result. If the target is a part and this contains another part, the target should set this to point to it and start a new search.
@property (assign)	NSRange			currentResultRange;	// The range (inside mCurrentPart) where the last match was found. We continue search after this range, we highlight this range.

@end



// Protocol searchable objects should implement:
@protocol WILDSearchable

// Search for the given search pattern, keeping track of the last found item by changing inContext's instance variables:
-(BOOL)	searchForPattern: (NSString*)inPattern withContext: (WILDSearchContext*)inContext
			flags: (WILDSearchFlags)inFlags;	// Returns YES if it found something, NO if nothing found.

@end
