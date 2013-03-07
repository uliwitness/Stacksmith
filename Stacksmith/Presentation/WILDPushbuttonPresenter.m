//
//  WILDPushbuttonPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPushbuttonPresenter.h"
#import "WILDPart.h"
#import "WILDPartView.h"
#import "UKHelperMacros.h"


@implementation WILDPushbuttonPresenter

-(void)	createButton
{
	NSRect		box = NSInsetRect([mPartView bounds], 2, 2);
	
	mMainView = [[WILDButtonView alloc] initWithFrame: box];
	[mMainView setBordered: YES];
	[mMainView setBezelStyle: NSRoundedBezelStyle];
	
	[mMainView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
}

-(void)	createSubviews
{
	if( !mMainView )
		[self createButton];
	
	[mPartView addSubview: mMainView];
	
	[self refreshProperties];
}


-(void)	refreshProperties
{
	WILDPart	*	currPart = [mPartView part];
	if( [[currPart style] isEqualToString: @"default"] )
		[mMainView setKeyEquivalent: @"\r"];
	else
		[mMainView setKeyEquivalent: @""];
	
	[mMainView setAlignment: [currPart textAlignment]];	
	[mMainView setButtonType: NSMomentaryPushInButton];
	[mMainView setFont: [currPart textFont]];
	if( [currPart showName] )
		[mMainView setTitle: [currPart name]];
	[mMainView setTarget: mPartView];
	[mMainView setAction: @selector(updateOnClick:)];
	
	WILDPartContents	*	contents = [mPartView currentPartContentsAndBackgroundContents: nil create: NO];
	BOOL					isHighlighted = [currPart highlighted];
	if( ![currPart sharedHighlight] && [[currPart partLayer] isEqualToString: @"background"] )
		isHighlighted = [contents highlighted];
	[mMainView setState: isHighlighted ? NSOnState : NSOffState];

	if( [currPart iconID] != 0 )
	{
		NSImage	*	theIcon = [currPart iconImage];
		[mMainView setImage: theIcon];
		
		if( [currPart iconID] == -1 || [[currPart name] length] == 0
			|| ![currPart showName] )
			[mMainView setImagePosition: NSImageOnly];
		else
			[mMainView setImagePosition: NSImageAbove];
		if( [currPart iconID] != -1 && [currPart iconID] != 0 )
			[mMainView setFont: [NSFont fontWithName: @"Geneva" size: 9.0]];
		[[mMainView cell] setImageScaling: NSImageScaleNone];
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


-(void)	stylePropertyDidChangeOfPart: (WILDPart*)inPart
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

@end
