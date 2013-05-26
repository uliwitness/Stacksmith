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
		
		if( mPartView.part.hasHorizontalScroller || mPartView.part.hasVerticalScroller )
		{
			NSRect	contentBounds = [mGroupView.contentView bounds];
			mScrollView = [[NSScrollView alloc] initWithFrame: contentBounds];
			NSView	*	docView = [[[NSView alloc] initWithFrame: contentBounds] autorelease];
			[mScrollView setDocumentView: docView];
			[mScrollView setDrawsBackground: NO];
			[mGroupView addSubview: mScrollView];
		}
	}
	
	[mGroupView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[mScrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
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

	if( !mScrollView && (mPartView.part.hasHorizontalScroller || mPartView.part.hasVerticalScroller) )
	{
		mScrollView = [[NSScrollView alloc] initWithFrame: [mGroupView.contentView bounds]];
		[mScrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		NSView	*	docView = [[[NSView alloc] initWithFrame: [mGroupView.contentView bounds]] autorelease];
		[mScrollView setDocumentView: docView];
		[mScrollView setDrawsBackground: NO];
		
		for( NSView* subber in [mGroupView.contentView subviews] )
		{
			[mScrollView.documentView addSubview: subber];
		}
		
		[mGroupView addSubview: mScrollView];
	}
	else if( mScrollView && !mPartView.part.hasHorizontalScroller && !mPartView.part.hasVerticalScroller )
	{
		[mScrollView removeFromSuperview];
		for( NSView* subber in mScrollView.subviews )
		{
			[mGroupView.contentView addSubview: subber];
		}
		
		DESTROY(mScrollView);
	}
	
	[mScrollView setHasHorizontalScroller: currPart.hasHorizontalScroller];
	[mScrollView setHasVerticalScroller: currPart.hasVerticalScroller];
	NSSize	contentSize = currPart.contentSize;
	if( contentSize.width == 0 )
		contentSize.width = [mGroupView.contentView bounds].size.width;
	if( contentSize.height == 0 )
		contentSize.height = [mGroupView.contentView bounds].size.height;
	[mScrollView.documentView setFrameSize: contentSize];
	[mScrollView.contentView scrollToPoint: NSMakePoint(0, contentSize.height -mScrollView.documentVisibleRect.size.height)];
	[mScrollView reflectScrolledClipView: mScrollView.contentView];
	
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


-(void)	contentSizePropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	removeSubviews
{
	[mGroupView removeFromSuperview];
	DESTROY(mGroupView);
	[mScrollView removeFromSuperview];
	DESTROY(mScrollView);
}


-(void)		setupCursorRectInPartViewWithDefaultCursor: (NSCursor*)currentCursor
{
	[mPartView addCursorRect: mPartView.visibleRect cursor: currentCursor];
}

-(NSRect)	selectionFrame
{
	return [[mPartView enclosingCardView] convertRect: [mGroupView bounds] fromView: mGroupView];
}


-(NSView*)	contentView
{
	return (mScrollView ? mScrollView.documentView : mGroupView.contentView);
}


-(BOOL)	isViewContainer
{
	return YES;
}

@end
