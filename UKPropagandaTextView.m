//
//  UKPropagandaTextView.m
//  Propaganda
//
//  Created by Uli Kusterer on 25.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaTextView.h"
#import "UKPropagandaPart.h"
#import "UKPropagandaStack.h"


@implementation UKPropagandaTextView

@synthesize representedPart = mPart;

// Apparently NSTextView doesn't do fancy new stuff like cursor rects and instead
//	re-sets the cursor on mouse-moves:
-(void)	mouseMoved: (NSEvent*)event
{
	if( [self isEditable] )
		[super mouseMoved: event];
	else
		[[[mPart stack] cursorWithID: 128] set];
}

@end
