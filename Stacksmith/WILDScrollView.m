//
//  WILDScrollView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import "WILDScrollView.h"
#import "WILDPartView.h"
#import "UKHelperMacros.h"
#import "WILDStack.h"
#import "WILDPart.h"
#import "WILDDocument.h"


@implementation WILDScrollView

@synthesize lineColor;

-(void)	dealloc
{
	DESTROY(lineColor);
	
	[super dealloc];
}

-(void)	drawRect: (NSRect)dirtyRect
{
	if( [self borderType] == NSLineBorder )
	{
		[[self backgroundColor] set];
		NSRectFill( dirtyRect );
		
		if( !lineColor )
			lineColor = [[NSColor blackColor] retain];
		[lineColor set];
		[NSBezierPath strokeRect: [self bounds]];
	}
	else
		[super drawRect: dirtyRect];
}

-(void)	resetCursorRects
{
	NSCursor	*	currentCursor = [WILDTools cursorForTool: [[WILDTools sharedTools] currentTool]];
	if( !currentCursor )
	{
		WILDPartView*		pv = (WILDPartView*) [self superview];
		currentCursor = [[[[pv part] stack] document] cursorWithID: 128];
	}
	[self addCursorRect: [self bounds] cursor: currentCursor];
}

@end
