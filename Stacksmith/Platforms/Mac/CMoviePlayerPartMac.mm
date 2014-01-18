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
	SetUpMoviePlayer();
	[inSuperView addSubview: mView];
}


void	CMoviePlayerPartMac::DestroyView()
{
	[mView removeFromSuperview];
	[mView release];
	mView = nil;
}


void	CMoviePlayerPartMac::SetUpMoviePlayer()
{
	mView.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
}


void	CMoviePlayerPartMac::SetStarted( bool inStart )
{
	if( inStart )
		[mView.player play];
	else
		[mView.player pause];
	CMoviePlayerPart::SetStarted( inStart );
}


void	CMoviePlayerPartMac::SetMediaPath( const std::string& inPath )
{
	mView.player = [AVPlayer playerWithURL: [NSURL URLWithString: [NSString stringWithUTF8String: inPath.c_str()]]];
	CMoviePlayerPart::SetMediaPath( inPath );
}


void	CMoviePlayerPartMac::SetCurrentTime( LEOInteger inTicks )
{
	[mView.player seekToTime: CMTimeMakeWithSeconds( inTicks / 60.0, 1 )];
}


LEOInteger	CMoviePlayerPartMac::GetCurrentTime()
{
	return CMTimeGetSeconds([mView.player currentTime]) * 60.0;
}


void	CMoviePlayerPartMac::SetPeeking( bool inState )
{
	ApplyPeekingStateToView(inState, mView);
}



