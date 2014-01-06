//
//  CSearchContext.h
//  Stacksmith
//
//  Created by Uli Kusterer on 27.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

/*
	This file implements searching for text in Stacksmith. It consists of a
	protocol every searchable object should implement, that makes it possible
	to ask it for the next result.
*/

#include <cstddef>
#include <cstdint>
#include <string>


namespace Carlson {

class CCard;
class CPart;


// Flags to pass to searchForPattern:withContext:flags:
//	No flags means we should do a simple substring search.
enum
{
	ESearchBackwards		= (1 << 0),		// Search for the result *preceding* this one, not the next one.
	ESearchWholeWords		= (1 << 1),		// Search for whole words, delimited by spaces, punctuation etc.
	ESearchCaseInsensitive	= (1 << 2)		// Ignore case differences.
};
typedef uint32_t TSearchFlags;



// This is passed to searchForPattern:withContext:flags: to provide context for the current search:
//	It keeps track of the last search result, so we can continue our search there.
struct CSearchContext
{
	CCard*		mStartCard;					// So we can detect end of search.
	CCard*		mCurrentCard;				// The card on which we found a part that matches.
	CPart*		mCurrentPart;				// The part in which we found the result.
	size_t		mCurrentResultRangeStart;	// We highlight the range starting here.
	size_t		mCurrentResultRangeEnd;		// We continue search after this range, we highlight this range.
};


// Protocol searchable objects should implement:
class CSearchable
{
// Search for the given search pattern, keeping track of the last found item by changing inContext's instance variables:
bool	SearchForPatternWithContextAndFlags( const std::string& inPattern, CSearchContext* inContext,
			TSearchFlags inFlags );	// Returns true if it found something, false if nothing found.

};

}


