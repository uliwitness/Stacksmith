//
//  WILDInvisiblePlayerView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-03-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "ULIInvisiblePlayerView.h"
#include "CMoviePlayerPart.h"


@interface WILDInvisiblePlayerView : ULIInvisiblePlayerView
{
	NSTrackingArea	*	mCursorTrackingArea;
	NSCursor*			mCursor;
}

@property (assign,nonatomic) Carlson::CMoviePlayerPart*	owningPart;
@property (retain,nonatomic) NSCursor*					cursor;

@end
