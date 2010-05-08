//
//  WILDWindowBodyView.m
//  Propaganda
//
//  Created by Uli Kusterer on 21.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDCardView.h"
#import "WILDStack.h"
#import "WILDCard.h"
#import "WILDNotifications.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDPartView.h"


@implementation WILDCardView

-(id)	initWithFrame: (NSRect)frameRect
{
	if(( self = [super initWithFrame: frameRect] ))
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
												name: WILDPeekingStateChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
												name: WILDCurrentToolDidChangeNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(backgroundEditModeChanged:)
												name: WILDBackgroundEditModeChangedNotification
												object: nil];
	}
	
	return self;
}


-(id)	initWithCoder: (NSCoder *)aDecoder
{
	if(( self = [super initWithCoder: aDecoder] ))
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
												name: WILDPeekingStateChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
												name: WILDCurrentToolDidChangeNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(backgroundEditModeChanged:)
												name: WILDBackgroundEditModeChangedNotification
												object: nil];
	}
	
	return self;
}


-(void)	dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDBackgroundEditModeChangedNotification
											object: nil];
	[super dealloc];
}


-(void)	setCard: (WILDCard*)inCard
{
	mCard = inCard;
}


-(WILDCard*)	card;
{
	return mCard;
}


-(void)	resetCursorRects
{
	WILDTool	currTool = [[WILDTools sharedTools] currentTool];
	NSCursor*			currCursor = [WILDTools cursorForTool: currTool];
	if( mPeeking )
		currCursor = [NSCursor arrowCursor];
	if( !currCursor )
		currCursor = [[[mCard stack] document] cursorWithID: 128];
	[self addCursorRect: [self visibleRect] cursor: currCursor];
}


-(void)	mouseDown: (NSEvent*)event
{
	if( mPeeking )
	{
		WILDScriptEditorWindowController*	sewc = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mBackgroundEditMode ? [mCard owningBackground] : mCard] autorelease];
		[[[[self window] windowController] document] addWindowController: sewc];
		[sewc showWindow: nil];
	}
	else if( [[WILDTools sharedTools] currentTool] == WILDButtonTool
				|| [[WILDTools sharedTools] currentTool] == WILDFieldTool )
	{
		[[WILDTools sharedTools] deselectAllClients];
	}
	else
	{
		[[self window] makeFirstResponder: self];
		[super mouseDown: event];
	}
}


-(void)	peekingStateChanged: (NSNotification*)notification
{
	[[self window] invalidateCursorRectsForView: self];
	mPeeking = [[[notification userInfo] objectForKey: WILDPeekingStateKey] boolValue];
}

-(void)	backgroundEditModeChanged: (NSNotification*)notification
{
	mBackgroundEditMode = [[[notification userInfo] objectForKey: WILDBackgroundEditModeKey] boolValue];
}


-(void)	currentToolDidChange: (NSNotification*)notification
{
	[[self window] invalidateCursorRectsForView: self];
}


-(BOOL)	acceptsFirstResponder
{
	return YES;
}

@end
