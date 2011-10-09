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


@implementation WILDPopUpButtonPresenter

-(void)	createSubviews
{
	if( !mMainView )
	{
		NSRect		box = NSInsetRect([mPartView bounds], 2, 2);
		
		mMainView = [[NSPopUpButton alloc] initWithFrame: box];
		[mMainView setBordered: YES];
		[mMainView setBezelStyle: NSRoundedBezelStyle];
		
		[mMainView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	}
	
	[mPartView addSubview: mMainView];
	
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

@end
