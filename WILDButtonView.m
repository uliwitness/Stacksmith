//
//  WILDButtonView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import "WILDButtonView.h"
#import "WILDPartView.h"


@implementation WILDButtonView

-(void)	drawRect: (NSRect)dirtyRect
{
	[super drawRect: dirtyRect];
	
	WILDPartView*	pv = [self superview];
	[pv drawSubView: self dirtyRect: dirtyRect];
}


-(void)	mouseDown: (NSEvent*)event
{
	WILDPartView*	pv = [self superview];
	if( [[pv part] autoHighlight] )
		[super mouseDown: event];
}


-(NSView *)	hitTest: (NSPoint)aPoint
{
	NSView	*	theView = [super hitTest: aPoint];
	if( !theView && [self mouse: aPoint inRect: [self bounds]] )
		return self;
	else
		return theView;
}

@end
