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
#import <AVKit/AVKit.h>
#include "CDocument.h"


using namespace Carlson;


void	CMoviePlayerPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView )
	{
		[mView removeFromSuperview];
		[mView release];
	}
	if( mControllerVisible )
	{
		mView = (ULIInvisiblePlayerView*)[[AVPlayerView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
		SetUpMoviePlayerControls();
	}
	else
		mView = [[ULIInvisiblePlayerView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	SetUpMoviePlayer();
	[inSuperView addSubview: mView];
}


void	CMoviePlayerPartMac::DestroyView()
{
	[mView removeFromSuperview];
	[mView release];
	mView = nil;
}


void	CMoviePlayerPartMac::SetControllerVisible( bool inStart )
{
	CMoviePlayerPart::SetControllerVisible(inStart);
	
	NSView	*	oldSuper = nil;
	if( mView )
	{
		oldSuper = [mView superview];
		[mView removeFromSuperview];
		[mView release];
	}
	if( mControllerVisible )
	{
		mView = (ULIInvisiblePlayerView*)[[AVPlayerView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
		SetUpMoviePlayerControls();
	}
	else
		mView = [[ULIInvisiblePlayerView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	SetUpMoviePlayer();
	[oldSuper addSubview: mView];
}


void	CMoviePlayerPartMac::SetUpMoviePlayer()
{
	[mView setWantsLayer: YES];
	mView.layer.masksToBounds = NO;
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, -mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	NSURL	*	movieURL = nil;
	std::string	mediaURL = GetDocument()->GetMediaURLByNameOfType( mMediaPath.c_str(), EMediaTypeMovie );
	if( mediaURL.length() == 0 && mMediaPath.find("file://") == 0 )
	{
		LEOContextGroup*	theGroup = GetDocument()->GetScriptContextGroupObject();
		if( (theGroup->flags & kLEOContextGroupFlagFromNetwork) == 0 );
			mediaURL = mMediaPath;
	}
	else if( mediaURL.length() == 0 && mMediaPath.find("http://") == 0 )
	{
		LEOContextGroup*	theGroup = GetDocument()->GetScriptContextGroupObject();
		if( (theGroup->flags & kLEOContextGroupFlagNoNetwork) == 0 );
			mediaURL = mMediaPath;
	}
	if( mediaURL.length() == 0 )
		mediaURL = GetDocument()->GetMediaURLByNameOfType( "Placeholder Movie", EMediaTypeMovie );
	if( mediaURL.length() > 0 )
		movieURL = [NSURL URLWithString: [NSString stringWithUTF8String: mediaURL.c_str()]];
	mView.player = [AVPlayer playerWithURL: movieURL];
	mView.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
}


void	CMoviePlayerPartMac::SetUpMoviePlayerControls()
{
	if( (mRight -mLeft) > 432 )
		[(AVPlayerView*)mView setControlsStyle: AVPlayerViewControlsStyleFloating];
	else if( (mRight -mLeft) > 150 )
		[(AVPlayerView*)mView setControlsStyle: AVPlayerViewControlsStyleInline];
	else
		[(AVPlayerView*)mView setControlsStyle: AVPlayerViewControlsStyleMinimal];
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



