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
#import "WILDPart.h"
#import "WILDPartView.h"


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
	if( [[currPart partStyle] isEqualToString: @"transparent"] )
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
			CALayer*	theLayer = [mPartView layer];
			[theLayer setOpaque: NO];
			CIFilter*	theFilter = [CIFilter filterWithName: @"CIDifferenceBlendMode"];
			[theFilter setDefaults];
			//[theLayer setSize: [self bounds].size];
			[theLayer setCompositingFilter: theFilter];
		}
#endif
	}
	else if( [[currPart partStyle] isEqualToString: @"opaque"] )
	{
		[mMainView setBordered: NO];
		[[mMainView cell] setBackgroundColor: [NSColor whiteColor]];
		[mMainView setAlignment: [currPart textAlignment]];
		[mMainView setButtonType: NSMomentaryPushInButton];
	}
	else if( [[currPart partStyle] isEqualToString: @"rectangle"]
			|| [[currPart partStyle] isEqualToString: @"roundrect"]
			|| [[currPart partStyle] isEqualToString: @"oval"] )
	{
		WILDButtonCell*	ourCell = [mMainView cell];
		[ourCell setBackgroundColor: [currPart fillColor]];
		[ourCell setLineColor: [currPart lineColor]];
		[ourCell setLineWidth: currPart.lineWidth];
		[mMainView setCell: ourCell];
		[mMainView setBordered: YES];
				
		if( [[currPart partStyle] isEqualToString: @"roundrect"]
			|| [[currPart partStyle] isEqualToString: @"standard"]
			|| [[currPart partStyle] isEqualToString: @"default"] )
			[mMainView setBezelStyle: NSRoundedBezelStyle];
		else if( [[currPart partStyle] isEqualToString: @"oval"] )
			[mMainView setBezelStyle: NSCircularBezelStyle];

		if( [[currPart partStyle] isEqualToString: @"default"] )
		{
			[mMainView setKeyEquivalent: @"\r"];
			[ourCell setDrawAsDefault: YES];
		}
		[mMainView setAlignment: [currPart textAlignment]];
		[mMainView setButtonType: NSMomentaryPushInButton];
	}
	else if( [[currPart partStyle] isEqualToString: @"standard"]
			|| [[currPart partStyle] isEqualToString: @"default"] )
	{
		[mMainView setBordered: YES];
		[mMainView setBezelStyle: NSRoundedBezelStyle];
		
		if( [[currPart partStyle] isEqualToString: @"default"] )
			[mMainView setKeyEquivalent: @"\r"];
		[mMainView setAlignment: [currPart textAlignment]];
		[mMainView setButtonType: NSMomentaryPushInButton];
	}
	else if( [[currPart partStyle] isEqualToString: @"checkbox"] )
	{
		[mMainView setButtonType: NSSwitchButton];
	}
	else if( [[currPart partStyle] isEqualToString: @"radiobutton"] )
	{
		[mMainView setButtonType: NSRadioButton];
	}
}

@end
