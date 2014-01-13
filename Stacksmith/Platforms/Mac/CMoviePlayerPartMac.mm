//
//  CMoviePlayerPartMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMoviePlayerPartMac.h"
#import "ULIInvisiblePlayerView.h"
#import <AVFoundation/AVFoundation.h>


using namespace Carlson;


void	CMoviePlayerPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView )
		[mView release];
	mView = [[ULIInvisiblePlayerView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	[mView setWantsLayer: YES];
	mView.layer.masksToBounds = NO;
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, -mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	mView.player = [AVPlayer playerWithURL: [[NSBundle mainBundle] URLForResource: @"PlaceholderMovie" withExtension: @"mov"]];
	[inSuperView addSubview: mView];
}


void	CMoviePlayerPartMac::DestroyView()
{
	[mView removeFromSuperview];
	[mView release];
	mView = nil;
}

void	CMoviePlayerPartMac::SetPeeking( bool inState )
{
	ApplyPeekingStateToView(inState, mView);
}



