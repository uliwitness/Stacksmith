//
//  WILDGroupPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDGroupPresenter.h"
#import "WILDPart.h"
#import "WILDPartView.h"
#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDMovieView.h"
#import "UKHelperMacros.h"
#import "WILDPartContents.h"


@implementation WILDGroupPresenter

-(void)	dealloc
{
	[self removeSubviews];

	[super dealloc];
}

-(void)	createSubviews
{
	[super createSubviews];
	
	if( !mGroupView )
	{
		NSRect						partRect = [mPartView bounds];
		[mPartView setWantsLayer: YES];
		
		mGroupView = [[NSBox alloc] initWithFrame: partRect];
		[mPartView addSubview: mGroupView];
	}
	
	[mGroupView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
	[self refreshProperties];
}


-(void)	refreshProperties
{
	WILDPart		*	currPart = [mPartView part];

	[mPartView setHidden: !currPart.visible];
	[mGroupView setTitle: currPart.name];
	
	NSRect	theBox = [self partViewFrameForPartRect: mPartView.part.quartzRectangle];
	[mPartView setFrame: theBox];
	
	if( [currPart.partStyle isEqualToString: @"standard"] )
	{
		if( theBox.size.width < 8 || theBox.size.height < 8 )
			[mGroupView setBoxType: NSBoxSeparator];
		else
			[mGroupView setBoxType: NSBoxPrimary];
	}
	else if( [currPart.partStyle isEqualToString: @"rectangle"] )
		[mGroupView setBoxType: NSBoxCustom];
	
	[mGroupView setFillColor: currPart.fillColor];
	[mGroupView setBorderColor: currPart.lineColor];
	[mGroupView setBorderWidth: currPart.lineWidth];
	
	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[mGroupView layer] setShadowColor: theColor];
		[[mGroupView layer] setShadowOpacity: 1.0];
		[[mGroupView layer] setShadowOffset: [currPart shadowOffset]];
		[[mGroupView layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[mGroupView layer] setShadowOpacity: 0.0];
}


-(void)	namePropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	removeSubviews
{
	[mGroupView removeFromSuperview];
	DESTROY(mGroupView);
}


-(void)		setupCursorRectInPartViewWithDefaultCursor: (NSCursor*)currentCursor
{
	[mPartView addCursorRect: mPartView.visibleRect cursor: currentCursor];
}

-(NSRect)	selectionFrame
{
	return [[mPartView enclosingCardView] convertRect: [mGroupView bounds] fromView: mGroupView];
}


-(void)	addSubPartView: (WILDPartView *)inView
{
	[mGroupView.contentView addSubview: inView];
}

@end
