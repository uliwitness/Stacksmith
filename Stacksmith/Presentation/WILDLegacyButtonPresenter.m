//
//  WILDLegacyButtonPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLegacyButtonPresenter.h"
#import "WILDButtonView.h"
#import "WILDButtonCell.h"
#import "UKHelperMacros.h"
#import "WILDPartContents.h"


@implementation WILDLegacyButtonPresenter

-(void)	createButton
{
	[super createButton];
	
	[mMainView setCell: [[[WILDButtonCell alloc] initTextCell: @""] autorelease]];
}


-(void)	refreshProperties
{
	[super refreshProperties];
	
	WILDPart*	currPart = [mPartView part];
	if( [[currPart style] isEqualToString: @"transparent"] )
	{
		[mMainView setBordered: NO];

		[mMainView setAlignment: [currPart textAlignment]];
		[mMainView setButtonType: NSMomentaryPushInButton];
		
#if TRANSPARENT_BUTTONS_INVERT
		WILDPartContents	*	contents = [mPartView currentPartContentsAndBackgroundContents: nil create: NO];
		BOOL					isHighlighted = [currPart highlighted];
		if( ![currPart sharedHighlight] && [[currPart partLayer] isEqualToString: @"background"] )
			isHighlighted = [contents highlighted];
		if( isHighlighted )
		{
			CALayer*	theLayer = [self layer];
			[theLayer setOpaque: NO];
			CIFilter*	theFilter = [CIFilter filterWithName: @"CIDifferenceBlendMode"];
			[theFilter setDefaults];
			//[theLayer setSize: [self bounds].size];
			[theLayer setCompositingFilter: theFilter];
		}
#endif
	}
	else if( [[currPart style] isEqualToString: @"opaque"] )
	{
		[mMainView setBordered: NO];
		[[mMainView cell] setBackgroundColor: [NSColor whiteColor]];
		[mMainView setAlignment: [currPart textAlignment]];
		[mMainView setButtonType: NSMomentaryPushInButton];
	}
	else if( [[currPart style] isEqualToString: @"rectangle"]
			|| [[currPart style] isEqualToString: @"roundrect"]
			|| [[currPart style] isEqualToString: @"oval"] )
	{
		WILDButtonCell*	ourCell = [mMainView cell];
		[ourCell setBackgroundColor: [currPart fillColor]];
		[ourCell setLineColor: [currPart lineColor]];
		[mMainView setCell: ourCell];
		[mMainView setBordered: YES];
				
		if( [[currPart style] isEqualToString: @"roundrect"]
			|| [[currPart style] isEqualToString: @"standard"]
			|| [[currPart style] isEqualToString: @"default"] )
			[mMainView setBezelStyle: NSRoundedBezelStyle];
		else if( [[currPart style] isEqualToString: @"oval"] )
			[mMainView setBezelStyle: NSCircularBezelStyle];

		if( [[currPart style] isEqualToString: @"default"] )
		{
			[mMainView setKeyEquivalent: @"\r"];
			[ourCell setDrawAsDefault: YES];
		}
		[mMainView setAlignment: [currPart textAlignment]];
		[mMainView setButtonType: NSMomentaryPushInButton];
	}
	else if( [[currPart style] isEqualToString: @"standard"]
			|| [[currPart style] isEqualToString: @"default"] )
	{
		[mMainView setBordered: YES];
		[mMainView setBezelStyle: NSRoundedBezelStyle];
		
		if( [[currPart style] isEqualToString: @"default"] )
			[mMainView setKeyEquivalent: @"\r"];
		[mMainView setAlignment: [currPart textAlignment]];
		[mMainView setButtonType: NSMomentaryPushInButton];
	}
	else if( [[currPart style] isEqualToString: @"checkbox"] )
	{
		[mMainView setButtonType: NSSwitchButton];
	}
	else if( [[currPart style] isEqualToString: @"radiobutton"] )
	{
		[mMainView setButtonType: NSRadioButton];
	}
}

@end
