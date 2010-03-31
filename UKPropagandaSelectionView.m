//
//  UKPropagandaSelectionView.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaSelectionView.h"
#import "UKPropagandaNotifications.h"
#import "UKPropagandaScriptEditorWindowController.h"
#import "UKPropagandaPart.h"



static UKPropagandaTools*		sAnimator = nil;


@implementation UKPropagandaTools

+(UKPropagandaTools*)	propagandaTools
{
	if( !sAnimator )
		sAnimator = [[UKPropagandaTools alloc] init];
	return sAnimator;
}


-(id)	init
{
	if(( self = [super init] ))
	{
		nonRetainingClients = (NSMutableArray*) CFArrayCreateMutable( kCFAllocatorDefault, 0, NULL );
	}
	return self;
}


-(void)	animate: (NSTimer*)sender
{
	animationPhase += 2;
	animationPhase %= 8;
	
	for( UKPropagandaSelectionView* currView in nonRetainingClients )
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

@end



@implementation UKPropagandaSelectionView

@synthesize control = mControl;
@synthesize helperView = mHelperView;

-(id)	initWithFrame: (NSRect)frameRect
{
	if(( self = [super initWithFrame: frameRect] ))
	{
		
	}
	return self;
}


-(void)	dealloc
{
	[sAnimator removeClient: self];
	[self unsubscribeNotifications];
	
	[super dealloc];
}


-(void)	unsubscribeNotifications
{
	if( !mPart )
		return;
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaPartWillChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaPartDidChangeNotification
											object: mPart];
}


-(void)	subscribeNotifications
{
	if( !mPart )
		return;
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
											name: UKPropagandaPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partWillChange:)
											name: UKPropagandaPartWillChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partDidChange:)
											name: UKPropagandaPartDidChangeNotification
											object: mPart];
}


-(void)	highlightSearchResultInRange: (NSRange)theRange
{
	[(NSTextView*)mHelperView setSelectedRange: theRange];
	[(NSTextView*)mHelperView scrollRangeToVisible: theRange];
	[(NSTextView*)mHelperView showFindIndicatorForRange: theRange];
}


-(void)	setSelected: (BOOL)inState
{
	if( mSelected != inState )
	{
		mSelected = inState;
		
		if( mSelected )
			[[UKPropagandaTools propagandaTools] addClient: self];
		else
			[[UKPropagandaTools propagandaTools] removeClient: self];
	}
}


-(void)	drawRect: (NSRect)dirtyRect
{
    if( mPeeking )
	{
		NSRect	peekBox = NSInsetRect( [self bounds], 1, 1 );
		[NSBezierPath setDefaultLineWidth: 2];
		[[NSColor lightGrayColor] set];
		[NSBezierPath strokeRect: peekBox];
		[[[UKPropagandaTools propagandaTools] peekPattern] set];
		[NSBezierPath strokeRect: peekBox];
		[NSBezierPath setDefaultLineWidth: 1];
	}
	else if( mSelected )
	{
		[[NSColor keyboardFocusIndicatorColor] set];
		NSRect	clampedBounds = [self bounds];
		clampedBounds.origin.x = truncf(clampedBounds.origin.x) + 0.5;
		clampedBounds.origin.y = truncf(clampedBounds.origin.y) + 0.5;
		clampedBounds.size.width -= 1;
		clampedBounds.size.height -= 1;
		NSBezierPath*	selPath = [NSBezierPath bezierPathWithRect: NSInsetRect(clampedBounds, 1, 1)];
		CGFloat			pattern[2] = { 4, 4 };
		[[NSColor whiteColor] set];
		[selPath stroke];
		[selPath setLineDash: pattern count: 2 phase: [[UKPropagandaTools propagandaTools] animationPhase]];
		[[NSColor keyboardFocusIndicatorColor] set];
		[selPath stroke];
	}
}


-(NSView *)	hitTest: (NSPoint)aPoint	// Equivalent to Carbon kEventControlInterceptSubviewClick.
{
	NSView*	hitView = [super hitTest: aPoint];
	if( hitView != nil )	// Was in our view or a sub view, not outside us?
	{
		if( mPeeking || [[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaPointerTool )
			hitView = self;		// Redirect to us.
	}
	
	return hitView;
}


-(void)	mouseDown: (NSEvent*)event
{
	if( mPeeking )
	{
		UKPropagandaScriptEditorWindowController*	sewc = [[[UKPropagandaScriptEditorWindowController alloc] initWithScriptContainer: mPart] autorelease];
		[[[[self window] windowController] document] addWindowController: sewc];
		[sewc showWindow: nil];
	}
	else if( [[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaPointerTool )
	{
		if( [event modifierFlags] & NSShiftKeyMask
			|| [event modifierFlags] & NSCommandKeyMask )
			[self setSelected: !mSelected];
		else
		{
			[[UKPropagandaTools propagandaTools] deselectAllClients];
			[self setSelected: YES];
		}
		[self setNeedsDisplay: YES];
	}
	else
		[super mouseDown: event];
}


-(void)	peekingStateChanged: (NSNotification*)notification
{
	mPeeking = [[[notification userInfo] objectForKey: UKPropagandaPeekingStateKey] boolValue];
	[self setNeedsDisplay: YES];
}


-(void)	setRepresentedPart: (UKPropagandaPart*)inPart
{
	if( inPart == nil )
		[self unsubscribeNotifications];
	
	mPart = inPart;
	
	if( mPart != nil )
		[self subscribeNotifications];
}


-(void)	partWillChange: (NSNotification*)notification
{
	
}


-(void)	partDidChange: (NSNotification*)notification
{
	NSString*	thePropName = [[notification userInfo] objectForKey: UKPropagandaAffectedPropertyKey];
	if( [thePropName isEqualToString: @"highlighted"] && [mControl respondsToSelector: @selector(setState:)] )
	{
		//NSLog( @"View got notified that %@ highlight changed to %s", [mPart displayName], [mPart highlighted] ? "true" : "false" );
		[(NSButton*)mControl setState: [mPart highlighted] ? NSOnState : NSOffState];
	}
}

@end