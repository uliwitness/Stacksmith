//
//  WILDToolButtonCell.m
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-02-22.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "WILDToolButtonCell.h"

@implementation WILDToolButtonCell

-(void)	drawBezelWithFrame: (NSRect)frame inView: (NSView*)controlView
{
	NSColor		*	fillColor = nil;
	if( [self state] == NSOnState )
		fillColor = [NSColor colorWithCalibratedWhite: 1.0 alpha: 0.4];
	else
		fillColor = [NSColor colorWithCalibratedWhite: 0.5 alpha: 0.2];
	if( !self.isEnabled )
		fillColor = [fillColor blendedColorWithFraction: 0.2 ofColor: NSColor.whiteColor];
	else if( self.isHighlighted )
		fillColor = [fillColor blendedColorWithFraction: 0.5 ofColor: NSColor.blackColor];
	[fillColor set];
	[[NSBezierPath bezierPathWithRoundedRect: frame xRadius: frame.size.height / 10 yRadius: frame.size.height / 10] fill];
}


-(NSCellHitResult)	hitTestForEvent: (NSEvent *)event inRect: (NSRect)cellFrame ofView: (NSView *)controlView
{
	NSUInteger		hitPart = NSCellHitNone;
	NSPoint			mousePos = [controlView convertPoint: [event locationInWindow] fromView: nil];
	
	if( NSPointInRect( mousePos, cellFrame ) )
	{
		hitPart = NSCellHitContentArea | NSCellHitTrackableArea;
	}
	
	return hitPart;
}


-(NSInteger)	nextState
{
	return [self state];
}

@end
