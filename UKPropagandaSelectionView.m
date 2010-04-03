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
	[[UKPropagandaTools propagandaTools] removeClient: self];
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
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaCurrentToolDidChangeNotification
											object: nil];
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
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
											name: UKPropagandaCurrentToolDidChangeNotification
											object: nil];
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
	BOOL	isMyTool = ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaButtonTool && [[mPart partType] isEqualToString: @"button"])
						|| ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaFieldTool && [[mPart partType] isEqualToString: @"field"]);
   
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
	
	if( mSelected )
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
	else if( isMyTool )
	{
		[[NSColor grayColor] set];
		NSRect	peekBox = NSInsetRect( [self bounds], 1.5, 1.5 );
		[NSBezierPath strokeRect: peekBox];
		[[NSColor blackColor] set];
	}
}


-(NSView *)	hitTest: (NSPoint)aPoint	// Equivalent to Carbon kEventControlInterceptSubviewClick.
{
	BOOL	isMyTool = ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaButtonTool && [[mPart partType] isEqualToString: @"button"])
						|| ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaFieldTool && [[mPart partType] isEqualToString: @"field"]);
	NSView*	hitView = [super hitTest: aPoint];
	if( hitView != nil )	// Was in our view or a sub view, not outside us?
	{
		if( mPeeking || isMyTool )
			hitView = self;		// Redirect to us.
		else if( [[UKPropagandaTools propagandaTools] currentTool] != UKPropagandaBrowseTool )	// Another tool than the ones we support?
			hitView = nil;	// Pretend we (or our subviews) weren't hit at all.
		else if( [[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaBrowseTool && hitView == self )	// Browse tool but not in our subviews?
			hitView = nil;	// Pretend we weren't hit at all. Maybe a view under us does better.
	}
	
	return hitView;
}


-(void)	mouseDown: (NSEvent*)event
{
	BOOL	isMyTool = ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaButtonTool && [[mPart partType] isEqualToString: @"button"])
						|| ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaFieldTool && [[mPart partType] isEqualToString: @"field"]);
	if( mPeeking )
	{
		UKPropagandaScriptEditorWindowController*	sewc = [[[UKPropagandaScriptEditorWindowController alloc] initWithScriptContainer: mPart] autorelease];
		[[[[self window] windowController] document] addWindowController: sewc];
		[sewc showWindow: nil];
	}
	else if( isMyTool )
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


-(void)	currentToolDidChange: (NSNotification*)notification
{
	[self setSelected: NO];
	[self setNeedsDisplay: YES];
}

@end
