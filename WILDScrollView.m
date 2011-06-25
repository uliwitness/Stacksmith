//
//  WILDScrollView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import "WILDScrollView.h"
#import "WILDPartView.h"


@implementation WILDScrollView

-(void)	resetCursorRects
{
	NSCursor	*	currentCursor = [WILDTools cursorForTool: [[WILDTools sharedTools] currentTool]];
	if( !currentCursor )
	{
		WILDPartView*		pv = [self superview];
		currentCursor = [[[[pv part] stack] document] cursorWithID: 128];
	}
	[self addCursorRect: [self bounds] cursor: currentCursor];
}

@end
