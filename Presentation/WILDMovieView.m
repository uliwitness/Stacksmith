//
//  WILDMovieView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 29.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDMovieView.h"
#import "WILDTools.h"


@implementation WILDMovieView

-(id)	init
{
    self = [super init];
    if (self)
	{
        // Initialization code here.
    }
    
    return self;
}

-(void)	dealloc
{
    [super dealloc];
}


-(void)	resetCursorRects
{
	//[super resetCursorRects];
	
	NSCursor	*	currentCursor = [WILDTools cursorForTool: [[WILDTools sharedTools] currentTool]];
	[self addCursorRect: [self bounds] cursor: currentCursor];
}

@end
