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
}


-(void)	mediaPathPropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	removeSubviews
{
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
