//
//  WILDTimerPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDTimerPresenter.h"
#import "WILDPart.h"
#import "WILDPartView.h"
#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDMovieView.h"
#import "UKHelperMacros.h"
#import "WILDPartContents.h"


@implementation WILDTimerPresenter

-(void)	dealloc
{
	[self removeSubviews];

	[super dealloc];
}

-(void)	createSubviews
{
	[super createSubviews];
	
	if( !mIcon )
	{
		NSRect						partRect = [mPartView bounds];
		[mPartView setWantsLayer: YES];
		
		mIcon = [[NSImageView alloc] initWithFrame: partRect];
		NSImage	*	theIcon = [NSImage imageNamed: @"TimerIcon"];
		if( !theIcon )
			theIcon = [NSImage imageNamed: @"NSApplicationIcon"];
		[mIcon setImage: theIcon];
		[mPartView addSubview: mIcon];
	}
	
	[mIcon setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
	[self refreshProperties];
}


-(void)	sendTimerMessage: (NSTimer*)sender
{
	if( ![mPartView myToolIsCurrent] )	// DOn't run timer while editing.
	{
		WILDPart		*	currPart = [mPartView part];
		WILDScriptContainerResultFromSendingMessage( currPart, currPart.timerMessage );
	}
}


-(void)	refreshProperties
{
	WILDPart		*	currPart = [mPartView part];

	[mPartView setHidden: !mPartView.myToolIsCurrent || ![currPart visible]];
	
	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[mIcon layer] setShadowColor: theColor];
		[[mIcon layer] setShadowOpacity: 1.0];
		[[mIcon layer] setShadowOffset: [currPart shadowOffset]];
		[[mIcon layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[mIcon layer] setShadowOpacity: 0.0];
	
	NSRect	theBox = [self partViewFrameForPartRect: mPartView.part.quartzRectangle];
	[mPartView setFrame: theBox];
	
	if( mTimer && (currPart.timerInterval <= 0 || currPart.timerMessage.length == 0) )
	{
		[mTimer invalidate];
		DESTROY(mTimer);
	}
	else if( !mTimer && currPart.timerInterval > 0 && currPart.timerMessage.length > 0 )
	{
		NSTimeInterval	interval = currPart.timerInterval / 60.0;
		mTimer = [[NSTimer scheduledTimerWithTimeInterval: interval target: self selector:@selector(sendTimerMessage:) userInfo: @{} repeats: YES] retain];
	}
}


-(void)	timerIntervalPropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	timerMessagePropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	removeSubviews
{
	[mTimer invalidate];
	DESTROY(mTimer);
	
	[mIcon removeFromSuperview];
	DESTROY(mIcon);
}


-(void)		setupCursorRectInPartViewWithDefaultCursor: (NSCursor*)currentCursor
{
	[mPartView addCursorRect: mPartView.visibleRect cursor: currentCursor];
}

-(NSRect)	selectionFrame
{
	[mPartView setHidden: !mPartView.myToolIsCurrent || ![mPartView.part visible]];
	return [[mPartView superview] convertRect: [mIcon bounds] fromView: mIcon];
}

@end
