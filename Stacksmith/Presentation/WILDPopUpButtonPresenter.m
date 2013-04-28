//
//  WILDPopUpButtonPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPopUpButtonPresenter.h"
#import "WILDPart.h"
#import "WILDPartView.h"
#import "WILDPartContents.h"
#import "UKHelperMacros.h"


@implementation WILDPopUpButtonPresenter

-(void)	createSubviews
{
	[super createSubviews];
	
	if( !mMainView )
	{
		mMainView = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(0,0, 100, 23)];
		NSRect		box = [mMainView frameForAlignmentRect: [mPartView bounds]];
		[mMainView setFrame: box];
		[mMainView setBordered: YES];
		[mMainView setBezelStyle: NSRoundedBezelStyle];
		
		[mMainView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	}
	
	[mPartView addSubview: mMainView];
	
	NSRect	theBox = [self rectForLayoutRect: mPartView.part.quartzRectangle];
	[mPartView setFrame: theBox];
	
	[self refreshProperties];
}


-(void)	refreshProperties
{
	WILDPart	*	currPart = [mPartView part];
	
	[mMainView setAlignment: [currPart textAlignment]];	
	[mMainView setButtonType: NSMomentaryPushInButton];
	[mMainView setFont: [currPart textFont]];
	if( [currPart showName] )
		[mMainView setTitle: [currPart name]];
	[mMainView setTarget: mPartView];
	[mMainView setAction: @selector(updateOnClick:)];
	[mMainView setEnabled: currPart.isEnabled];
	
	WILDPartContents	*	contents = [mPartView currentPartContentsAndBackgroundContents: nil create: NO];
	BOOL					isHighlighted = [currPart highlighted];
	if( ![currPart sharedHighlight] && [[currPart partLayer] isEqualToString: @"background"] )
		isHighlighted = [contents highlighted];
	NSArray*	popupItems = [contents listItems];
	for( NSString* itemName in popupItems )
	{
		if( [itemName hasPrefix: @"-"] )
			[[mMainView menu] addItem: [NSMenuItem separatorItem]];
		else
			[mMainView addItemWithTitle: itemName];
	}
	NSUInteger selIndex = [[currPart selectedListItemIndexes] firstIndex];
	if( selIndex == NSNotFound )
		selIndex = 0;
	[mMainView selectItemAtIndex: selIndex];
	[mMainView setState: isHighlighted];

	if( [currPart iconID] != 0 )
	{
		[mMainView setImage: [currPart iconImage]];
		
		if( [currPart iconID] == -1 || [[currPart name] length] == 0
			|| ![currPart showName] )
			[mMainView setImagePosition: NSImageOnly];
		else
			[mMainView setImagePosition: NSImageAbove];
		if( [currPart iconID] != -1 && [currPart iconID] != 0 )
			[mMainView setFont: [NSFont fontWithName: @"Geneva" size: 9.0]];
		[[mMainView cell] setImageScaling: NSImageScaleNone];
	}

	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[mMainView layer] setShadowColor: theColor];
		[[mMainView layer] setShadowOpacity: 1.0];
		[[mMainView layer] setShadowOffset: [currPart shadowOffset]];
		[[mMainView layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[mMainView layer] setShadowOpacity: 0.0];
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


-(void)	removeSubviews
{
	[mMainView removeFromSuperview];
	DESTROY(mMainView);
}


-(NSRect)	selectionFrame
{
	return [[mPartView superview] convertRect: [mMainView alignmentRectForFrame: [mMainView frame]] fromView: mPartView];
}


-(NSRect)	layoutRectForRect:(NSRect)inRect
{
	return [mMainView alignmentRectForFrame: inRect];
}


-(NSRect)	rectForLayoutRect:(NSRect)inLayoutRect
{
	return [mMainView frameForAlignmentRect: inLayoutRect];
}

@end
