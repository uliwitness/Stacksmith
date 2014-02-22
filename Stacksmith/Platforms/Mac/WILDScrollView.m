//
//  WILDScrollView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import "WILDScrollView.h"
#import "UKHelperMacros.h"


@implementation WILDScrollView

@synthesize lineColor;
@synthesize lineWidth;

-(id)	initWithFrame: (NSRect)inBox
{
	self = [super initWithFrame: inBox];
	if( self )
	{
		lineColor = [[NSColor blackColor] retain];
		lineWidth = 1.0;
	}
	return self;
}


-(id)	initWithCoder: (NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	if( self )
	{
		lineColor = [[NSColor blackColor] retain];
		lineWidth = 1.0;
	}
	return self;
}


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
		
		if( lineWidth > 0 )
		{
			NSRect	lineBox = self.bounds;
			lineBox.origin.x += lineWidth / 2.0;
			lineBox.origin.y += lineWidth / 2.0;
			lineBox.size.width -= lineWidth / 2.0;
			lineBox.size.height -= lineWidth / 2.0;
			[lineColor set];
			[NSBezierPath setDefaultLineWidth: lineWidth];
			[NSBezierPath strokeRect: lineBox];
			[NSBezierPath setDefaultLineWidth: 1.0];
		}
	}
	else
		[super drawRect: dirtyRect];
}


-(void)	setLineColor: (NSColor*)theColor
{
	ASSIGN(self->lineColor,theColor);
	[self setNeedsDisplay: YES];
}


-(void)	setLineWidth: (CGFloat)inLineWidth
{
	self->lineWidth = inLineWidth;
	[self setNeedsDisplay: YES];
}

@end
