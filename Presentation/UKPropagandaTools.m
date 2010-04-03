//
//  UKPropagandaTools.m
//  Stacksmith
//
//  Created by Uli Kusterer on 03.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "UKPropagandaTools.h"
#import "UKPropagandaNotifications.h"


static UKPropagandaTools*		sAnimator = nil;


@implementation UKPropagandaTools

+(UKPropagandaTools*)	propagandaTools
{
	if( !sAnimator )
		sAnimator = [[UKPropagandaTools alloc] init];
	return sAnimator;
}


+(BOOL)		toolIsPaintTool: (UKPropagandaTool)theTool
{
	return ( theTool >= UKPropagandaSelectTool );
}


+(NSCursor*)	cursorForTool: (UKPropagandaTool)theTool
{
	if( theTool == UKPropagandaBrowseTool )
		return nil;	// Default cursor -- need to ask stack.
	else if( [self toolIsPaintTool: theTool] )
		return [NSCursor crosshairCursor];
	else
		return [NSCursor arrowCursor];
}


-(id)	init
{
	if(( self = [super init] ))
	{
		nonRetainingClients = (NSMutableArray*) CFArrayCreateMutable( kCFAllocatorDefault, 0, NULL );
		tool = UKPropagandaBrowseTool;
	}
	return self;
}


-(void)	animate: (NSTimer*)sender
{
	animationPhase += 2;
	animationPhase %= 8;
	
	for( id<UKPropagandaSelectableView> currView in nonRetainingClients )
	{
		[currView setNeedsDisplay: YES];
	}
}

-(NSInteger)	animationPhase
{
	return animationPhase;
}


-(void)		addClient: (id<UKPropagandaSelectableView>)theClient
{
	[nonRetainingClients addObject: theClient];
	if( [nonRetainingClients count] == 1 )	// Just added the first client! Start our timer!
	{
		animationTimer = [[NSTimer scheduledTimerWithTimeInterval: 0.08 target: self selector: @selector(animate:) userInfo: nil repeats: YES] retain];
	}
}


-(void)		removeClient: (id<UKPropagandaSelectableView>)theClient
{
	[nonRetainingClients removeObject: theClient];
	if( [nonRetainingClients count] == 0 )	// Just removed the last client! Stop our timer!
	{
		[animationTimer invalidate];
		[animationTimer release];
		animationTimer = nil;
	}
}


-(void)	deselectAllClients
{
	NSArray*	clients = [[nonRetainingClients copy] autorelease];
	for( id<UKPropagandaSelectableView> currView in clients )
	{
		[currView setSelected: NO];
		[currView setNeedsDisplay: YES];
	}
}

-(NSInteger)	numberOfSelectedClients
{
	return [nonRetainingClients count];
}

-(NSColor*)	peekPattern
{
	if( !peekPattern )
		peekPattern = [[NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_22"]] retain];
	
	return peekPattern;
}


-(UKPropagandaTool)	currentTool
{
	return tool;
}


-(void)	setCurrentTool: (UKPropagandaTool)theTool
{
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaCurrentToolWillChangeNotification object: nil];
	tool = theTool;
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaCurrentToolDidChangeNotification object: nil];
}

@end
