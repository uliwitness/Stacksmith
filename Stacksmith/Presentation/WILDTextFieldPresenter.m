//
//  WILDTextFieldPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDTextFieldPresenter.h"
#import "WILDPart.h"
#import "WILDPartView.h"
#import "WILDTextView.h"
#import "WILDScrollView.h"
#import "WILDDocument.h"
#import "UKHelperMacros.h"
#import "WILDPartContents.h"


@implementation WILDTextFieldPresenter

-(void)	createSubviews
{
	[super createSubviews];
	
	if( !mScrollView )
	{
		WILDPart	*	currPart = [mPartView part];
		NSRect			partRect = [currPart quartzRectangle];
		[mPartView setWantsLayer: YES];
		partRect.origin = NSMakePoint( 2, 2 );
		
		mTextView = [[WILDTextView alloc] initWithFrame: partRect];
		[mTextView setFont: [currPart textFont]];
		[mTextView setWantsLayer: YES];
		[mTextView setDrawsBackground: NO];
		[mTextView setUsesFindPanel: NO];
		[mTextView setDelegate: self];
		[mTextView setRepresentedPart: currPart];
				
		mScrollView = [[WILDScrollView alloc] initWithFrame: partRect];
		[mScrollView setDocumentCursor: [(WILDDocument*)[[currPart stack] document] cursorWithID: 128]];
		[mScrollView setWantsLayer: YES];
		NSRect			txBox = partRect;
		txBox.origin = NSZeroPoint;

		[mTextView setFrame: txBox];
		[mScrollView setDocumentView: mTextView];
		[mScrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		[mPartView addSubview: mScrollView];
	}
	
	NSRect	theBox = [self rectForLayoutRect: mPartView.part.quartzRectangle];
	[mPartView setFrame: theBox];
	
	[self refreshProperties];
}


-(void)	refreshProperties
{
	WILDPart		*	currPart = [mPartView part];
	WILDPartContents*	contents = nil;
	WILDPartContents*	bgContents = nil;
	
	contents = [mPartView currentPartContentsAndBackgroundContents: &bgContents create: NO];

	[mPartView setHidden: ![currPart visible]];
	[mTextView setAlignment: [currPart textAlignment]];
	if( [currPart wideMargins] )
		[mTextView setTextContainerInset: NSMakeSize( 5, 2 )];
	
	// A field can be edited if:
	//	It is a card field and its lockText is FALSE.
	//	It is a bg field, its lockText is FALSE its sharedText is TRUE and we're editing the background.
	//	It is a bg field, its lockText is FALSE and its sharedText is FALSE.
	BOOL		shouldBeEditable = ![currPart lockText] && (![currPart sharedText] || [mPartView isBackgroundEditing]);
	if( ![currPart isEnabled] )
		shouldBeEditable = NO;
	[mTextView setEditable: shouldBeEditable];
	[mTextView setSelectable: shouldBeEditable];
	
	if( [[currPart partStyle] isEqualToString: @"transparent"] )
	{
		[mScrollView setBorderType: NSNoBorder];
		[mScrollView setDrawsBackground: NO];
		[mTextView setDrawsBackground: NO];
	}
	else if( [[currPart partStyle] isEqualToString: @"opaque"] )
	{
		[mScrollView setBorderType: NSNoBorder];
		[mScrollView setBackgroundColor: [NSColor whiteColor]];
	}
	else if( [[currPart partStyle] isEqualToString: @"standard"] )
	{
		[mScrollView setBorderType: NSBezelBorder];
		[mScrollView setBackgroundColor: [NSColor whiteColor]];
	}
	else if( [[currPart partStyle] isEqualToString: @"roundrect"] )
	{
		[mScrollView setBorderType: NSBezelBorder];
		[mScrollView setBackgroundColor: [NSColor whiteColor]];
	}
	else if( [[currPart partStyle] isEqualToString: @"scrolling"] )
	{
		[mScrollView setBorderType: NSLineBorder];
		[mScrollView setBackgroundColor: [NSColor whiteColor]];
	}
	else
	{
		[mScrollView setBorderType: NSLineBorder];
		[mScrollView setBackgroundColor: [currPart fillColor]];
		[mScrollView setLineColor: [currPart lineColor]];
	}
	[mScrollView setVerticalScrollElasticity: [currPart hasVerticalScroller] ? NSScrollElasticityAutomatic : NSScrollElasticityNone];
	[mScrollView setHasVerticalScroller: [currPart hasVerticalScroller]];
	[mScrollView setHorizontalScrollElasticity: [currPart hasHorizontalScroller] ? NSScrollElasticityAutomatic : NSScrollElasticityNone];
	[mScrollView setHasHorizontalScroller: [currPart hasHorizontalScroller]];

	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[mScrollView layer] setShadowColor: theColor];
		[[mScrollView layer] setShadowOpacity: 1.0];
		[[mScrollView layer] setShadowOffset: [currPart shadowOffset]];
		[[mScrollView layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[mScrollView layer] setShadowOpacity: 0.0];
	
	NSAttributedString*	attrStr = [contents styledTextForPart: currPart];
	if( attrStr )
		[[mTextView textStorage] setAttributedString: attrStr];
	else
	{
		NSString*	theText = [contents text];
		if( theText )
			[mTextView setString: [contents text]];
	}
}


-(void)	namePropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	textAlignmentPropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	showNamePropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	textPropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	textDidChange: (NSNotification *)notification
{
	WILDPartContents	*	contents = [mPartView currentPartContentsAndBackgroundContents: nil create: YES];
	
	[contents setStyledText: [notification.object textStorage]];
	
	[[mPartView part] updateChangeCount: NSChangeDone];
}


-(void)	removeSubviews
{
	DESTROY(mTextView);
	[mScrollView removeFromSuperview];
	DESTROY(mScrollView);
}


-(NSRect)	selectionFrame
{
	return [[mPartView superview] convertRect: [mScrollView bounds] fromView: mScrollView];
}

@end
