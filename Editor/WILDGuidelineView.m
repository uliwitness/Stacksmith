//
//  WILDGuidelineView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 23.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDGuidelineView.h"


@interface WILDGuideline : NSObject
{
    CGFloat		mPosition;
	BOOL		mHorizontal;
	NSColor	*	mColor;
}

@property (assign) CGFloat						position;
@property (assign,getter=isHorizontal) BOOL		horizontal;
@property (copy) NSColor*						color;

-(id)	wildGuideline;

-(void)	drawInView: (NSView*)inView;

@end


@implementation WILDGuideline

@synthesize position = mPosition;
@synthesize horizontal = mHorizontal;
@synthesize color = mColor;

+(id)	wildGuideline
{
	return [[[[self class] alloc] init] autorelease];
}

-(void)	drawInView: (NSView*)inView
{
	[mColor set];
	NSBezierPath	*	theLine = [NSBezierPath bezierPath];
	if( mHorizontal )
	{
		[theLine moveToPoint: NSMakePoint(0.5,mPosition +0.5)];
		[theLine lineToPoint: NSMakePoint([inView bounds].size.width +0.5,mPosition +0.5)];
	}
	else
	{
		[theLine moveToPoint: NSMakePoint(mPosition +0.5,0.5)];
		[theLine lineToPoint: NSMakePoint(mPosition +0.5,[inView bounds].size.height +0.5)];
	}
	CGFloat		theDashes[2] = { 4.0, 1.0 };
	[theLine setLineDash: theDashes count: 2 phase: 0.0];
	[theLine stroke];
}

@end


@implementation WILDGuidelineView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		mGuidelines = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (void)dealloc
{
	DESTROY_DEALLOC(mGuidelines);

    [super dealloc];
}


-(void)	drawRect:(NSRect)dirtyRect
{
	for( WILDGuideline* currGuideline in mGuidelines )
		[currGuideline drawInView: self];
}


-(void)	addGuidelineAt: (CGFloat)pos horizontal: (BOOL)inIsHorizontal color: (NSColor*)inColor
{
	WILDGuideline	*	theGuideline = [WILDGuideline wildGuideline];
	[theGuideline setPosition: pos];
	[theGuideline setHorizontal: inIsHorizontal];
	[theGuideline setColor: inColor];
	[mGuidelines addObject: theGuideline];
}


-(void)	removeAllGuidelines
{
	[mGuidelines removeAllObjects];
}


-(NSView *)	hitTest: (NSPoint)aPoint
{
	return nil;	// Make all clicks pass through us.
}

@end
