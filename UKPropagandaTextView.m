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
#import "UKPropagandaSelectionView.h"


@implementation UKPropagandaTextView

@synthesize representedPart = mPart;

// Apparently NSTextView doesn't do fancy new stuff like cursor rects and instead
//	re-sets the cursor on mouse-moves:
-(void)	mouseMoved: (NSEvent*)event
{
	UKPropagandaTool	currTool = [[UKPropagandaTools propagandaTools] currentTool];
	NSCursor*			currCursor = [UKPropagandaTools cursorForTool: currTool];
	if( !currCursor )
		currCursor = [[[mPart stack] document] cursorWithID: 128];
	
	if( [self isEditable] && currTool == UKPropagandaBrowseTool )
		[super mouseMoved: event];
	else
		[currCursor set];
}

@end
