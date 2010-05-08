//
//  WILDTools.m
//  Stacksmith
//
//  Created by Uli Kusterer on 03.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDTools.h"
#import "WILDNotifications.h"


static WILDTools*		sAnimator = nil;


@implementation WILDTools

+(WILDTools*)	sharedTools
{
	if( !sAnimator )
		sAnimator = [[WILDTools alloc] init];
	return sAnimator;
}


+(BOOL)		toolIsPaintTool: (WILDTool)theTool
{
	return ( theTool >= WILDSelectTool );
}


+(NSCursor*)	cursorForTool: (WILDTool)theTool
{
	if( theTool == WILDBrowseTool )
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
		tool = WILDBrowseTool;
	}
	return self;
}


-(void)	animate: (NSTimer*)sender
{
	animationPhase += 2;
	animationPhase %= 8;
	
	for( id<WILDSelectableView> currView in nonRetainingClients )
	{
		[currView setNeedsDisplay: YES];
	}
}

-(NSInteger)	animationPhase
{
	return animationPhase;
}


-(void)		addClient: (id<WILDSelectableView>)theClient
{
	[nonRetainingClients addObject: theClient];
	if( [nonRetainingClients count] == 1 )	// Just added the first client! Start our timer!
	{
		animationTimer = [[NSTimer scheduledTimerWithTimeInterval: 0.08 target: self selector: @selector(animate:) userInfo: nil repeats: YES] retain];
	}
}


-(void)		removeClient: (id<WILDSelectableView>)theClient
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
	for( id<WILDSelectableView> currView in clients )
	{
		[currView setSelected: NO];
		[currView setNeedsDisplay: YES];
	}
}

-(NSInteger)	numberOfSelectedClients
{
	return [nonRetainingClients count];
}


-(NSSet*)	clients
{
	return [NSSet setWithArray: nonRetainingClients];
}

-(NSColor*)	peekPattern
{
	if( !peekPattern )
		peekPattern = [[NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_22"]] retain];
	
	return peekPattern;
}


-(WILDTool)	currentTool
{
	return tool;
}


-(void)	setCurrentTool: (WILDTool)theTool
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDCurrentToolWillChangeNotification object: nil];
	tool = theTool;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDCurrentToolDidChangeNotification object: nil];
}

@end
