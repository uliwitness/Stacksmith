//
//  WILDMovieView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 29.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDMovieView.h"
#import "WILDTools.h"
#import "WILDPartView.h"


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
	if( !currentCursor )
	{
		WILDPartView*		pv = [self superview];
		currentCursor = [[[[pv part] stack] document] cursorWithID: 128];
	}
	[self addCursorRect: [self bounds] cursor: currentCursor];
}

@end
