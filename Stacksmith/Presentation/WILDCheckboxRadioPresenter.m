//
//  WILDCheckboxRadioPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDCheckboxRadioPresenter.h"
#import "WILDPart.h"
#import "WILDPartView.h"
#import "UKHelperMacros.h"


@implementation WILDCheckboxRadioPresenter

-(void)	createSubviews
{
	
	if( !mMainView )
	{
		NSRect		box = NSInsetRect([mPartView bounds], 2, 2);
		
		mMainView = [[WILDButtonView alloc] initWithFrame: box];
		[mMainView setBordered: NO];
		
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
	if( [[currPart partStyle] isEqualToString: @"radiobutton"] )
		[mMainView setButtonType: NSRadioButton];
	else
		[mMainView setButtonType: NSSwitchButton];
	
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
	//UKLog( @"%@ highlight: %s", currPart, (isHighlighted ? "YES" : "NO") );
	[mMainView setState: isHighlighted ? NSOnState : NSOffState];

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


-(void)	highlightPropertyDidChangeOfPart: (WILDPart*)inPart
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
	return [[mPartView superview] convertRect: [mMainView bounds] fromView: mMainView];
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
