//
//  CMoviePlayerPartMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMoviePlayerPartMac.h"
#import "WILDInvisiblePlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "WILDPlayerView.h"
#include "CDocument.h"
#import "UKHelperMacros.h"
#import "NSObject+JCSKVOWithBlocks.h"
#include "CAlert.h"


using namespace Carlson;


CMoviePlayerPartMac::~CMoviePlayerPartMac()
{
	DestroyView();
	DESTROY_DEALLOC(mCurrentMovie);
}


void	CMoviePlayerPartMac::WakeUp()
{
	CMoviePlayerPart::WakeUp();
}


void	CMoviePlayerPartMac::GoToSleep()
{
	if( mCurrentMovie )
	{
		mCurrentTime = CMTimeGetSeconds([mCurrentMovie currentTime]) * 60.0;
		if( mRateObserver )
		{
			[mCurrentMovie jcsRemoveObserver: mRateObserver];
			mRateObserver = nil;
		}
		DESTROY(mTimeObserver);
		DESTROY(mCurrentMovie);
	}
	
	CMoviePlayerPart::GoToSleep();
}


void	CMoviePlayerPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView.superview == inSuperView )
	{
		[mView.animator removeFromSuperview];
		[inSuperView.animator addSubview: mView];	// Make sure we show up in right layering order.
		return;
	}
	if( mView || mCurrentMovie )
	{
		if( mCurrentMovie )
		{
			mCurrentTime = CMTimeGetSeconds([mCurrentMovie currentTime]) * 60.0;
			if( mRateObserver )
			{
				[mCurrentMovie jcsRemoveObserver: mRateObserver];
				mRateObserver = nil;
			}
		}
		[mView.animator removeFromSuperview];
		[mView release];
	}
	if( mControllerVisible )
	{
		mView = (WILDInvisiblePlayerView*)[[WILDPlayerView alloc] initWithFrame: NSMakeRect(GetLeft(), GetTop(), GetRight() -GetLeft(), GetBottom() -GetTop())];
		SetUpMoviePlayerControls();
	}
	else
	{
		mView = [[WILDInvisiblePlayerView alloc] initWithFrame: NSMakeRect(GetLeft(), GetTop(), GetRight() -GetLeft(), GetBottom() -GetTop())];
		[mView setCursor: [NSCursor arrowCursor]];
		GetDocument()->GetMediaCache().GetMediaImageByIDOfType( mCursorID, EMediaTypeCursor,
		[this]( WILDNSImagePtr inImage, int xHotSpot, int yHotSpot )
		{
			NSCursor *theCursor = (GetStack()->GetTool() != EBrowseTool) ? [NSCursor arrowCursor] : [[[NSCursor alloc] initWithImage: inImage hotSpot: NSMakePoint(xHotSpot, yHotSpot)] autorelease];
			[mView setCursor: theCursor];
		} );
	}
	mView.owningPart = this;
	SetUpMoviePlayer();
	[mView setAutoresizingMask: GetCocoaResizeFlags( mPartLayoutFlags )];
	[mView setToolTip: [NSString stringWithUTF8String: mToolTip.c_str()]];
	[inSuperView.animator addSubview: mView];
}


void	CMoviePlayerPartMac::DestroyView()
{
	DESTROY(mTimeObserver);
	if( mCurrentMovie )
		mCurrentTime = CMTimeGetSeconds([mCurrentMovie currentTime]) * 60.0;
	if( mRateObserver )
	{
		[mCurrentMovie jcsRemoveObserver: mRateObserver];
		mRateObserver = nil;
	}
	[mView.animator removeFromSuperview];
	[mView release];
	mView = nil;
}


void	CMoviePlayerPartMac::SetControllerVisible( bool inStart )
{
	CMoviePlayerPart::SetControllerVisible(inStart);
	
	NSView	*	oldSuper = nil;
	if( mView )
	{
		mCurrentTime = CMTimeGetSeconds([mCurrentMovie currentTime]) * 60.0;
		if( mRateObserver )
		{
			[mCurrentMovie jcsRemoveObserver: mRateObserver];
			mRateObserver = nil;
		}
		oldSuper = [mView superview];
		[mView.animator removeFromSuperview];
		[mView release];
	}
	if( mControllerVisible )
	{
		mView = (WILDInvisiblePlayerView*)[[WILDPlayerView alloc] initWithFrame: NSMakeRect(GetLeft(), GetTop(), GetRight() -GetLeft(), GetBottom() -GetTop())];
		SetUpMoviePlayerControls();
	}
	else
	{
		mView = [[WILDInvisiblePlayerView alloc] initWithFrame: NSMakeRect(GetLeft(), GetTop(), GetRight() -GetLeft(), GetBottom() -GetTop())];
	}
	mView.owningPart = this;
	SetUpMoviePlayer();
	[oldSuper.animator addSubview: mView];
}


void	CMoviePlayerPartMac::SetUpMoviePlayer()
{
	[mView setWantsLayer: YES];
	mView.layer.masksToBounds = NO;
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setBorderWidth: mLineWidth];
	[mView.layer setBorderColor: [NSColor colorWithCalibratedRed: mLineColorRed / 65535.0 green: mLineColorGreen / 65535.0 blue: mLineColorBlue / 65535.0 alpha: mLineColorAlpha / 65535.0].CGColor];
	[mView.layer setBackgroundColor: [NSColor colorWithCalibratedRed: mFillColorRed / 65535.0 green: mFillColorGreen / 65535.0 blue: mFillColorBlue / 65535.0 alpha: mFillColorAlpha / 65535.0].CGColor];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	NSURL	*	movieURL = nil;
	std::string	mediaURL = SanitizeMediaPath( mMediaPath );
	if( mediaURL.length() > 0 )
		movieURL = [NSURL URLWithString: [NSString stringWithUTF8String: mediaURL.c_str()]];
	if( !mCurrentMovie )
	{
		ASSIGN(mCurrentMovie,[AVPlayer playerWithURL: movieURL]);
		mCurrentMovie.actionAtItemEnd = AVPlayerActionAtItemEndPause;
		DESTROY(mRateObserver);
	}
	mView.player = mCurrentMovie;
	if( !mRateObserver )
		SetUpRateObserver();
	[mCurrentMovie seekToTime: CMTimeMakeWithSeconds( mCurrentTime / 60.0, 1)];
}


void	CMoviePlayerPartMac::SetUpRateObserver()
{
	DESTROY(mRateObserver);
	mRateObserver = [mCurrentMovie jcsAddObserverForKeyPath: PROPERTY(rate) options: NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew queue: [NSOperationQueue mainQueue] block: ^(NSDictionary *change)
	{
		const char*	msg = NULL;
		float		theRate = mCurrentMovie.rate;
		if( theRate != mLastNotifiedRate )
		{
			if( theRate == 0.0 )
				msg = "stopMovie";
			else if( mLastNotifiedRate == 0.0 )
				msg = "playMovie";
			if( msg )
			{
				CAutoreleasePool		pool;
				this->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, msg );
			}
			mCurrentTime = CMTimeGetSeconds([mCurrentMovie currentTime]) * 60.0;
			mLastNotifiedRate = theRate;
		}
	}];

	DESTROY(mTimeObserver);
	mTimeObserver = [[mView.player addPeriodicTimeObserverForInterval: CMTimeMakeWithSeconds( 7.0 * 24.0 * 60.0 * 60.0, 1 ) queue: dispatch_get_main_queue() usingBlock:
	^( CMTime time )
	{
		LEOInteger	newTime = CMTimeGetSeconds( time ) * 60;
		if( newTime != mCurrentTime )
		{
			CAutoreleasePool		pool;
			this->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ /*CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs );*/ }, EMayGoUnhandled, "timeChange %d", newTime );
			mCurrentTime = newTime;
		}
	}] retain];
}


void	CMoviePlayerPartMac::SetUpMoviePlayerControls()
{
	if( (GetRight() -GetLeft()) > 160 && (GetBottom() -GetTop()) > 80 )
		[(AVPlayerView*)mView setControlsStyle: AVPlayerViewControlsStyleFloating];
	else
		[(AVPlayerView*)mView setControlsStyle: AVPlayerViewControlsStyleMinimal];
}


void	CMoviePlayerPartMac::SetStarted( bool inStart )
{
	if( inStart )
		[mCurrentMovie play];
	else
		[mCurrentMovie pause];
	CMoviePlayerPart::SetStarted( inStart );
}


std::string	CMoviePlayerPartMac::SanitizeMediaPath( const std::string& inPath )
{
	LEOContextGroup*	theGroup = GetDocument()->GetScriptContextGroupObject();
	if( (theGroup->flags & kLEOContextGroupFlagFromNetwork) == 0 );
	
	std::string		outURL;
	if( inPath.find( "http://" ) == 0 && (theGroup->flags & kLEOContextGroupFlagNoNetwork) == 0 )
	{
		outURL = inPath;
	}
	else if( inPath.find( "file://" ) == 0 && (theGroup->flags & kLEOContextGroupFlagFromNetwork) == 0 )
	{
		outURL = inPath;
	}
	else if( inPath.find( "/" ) == 0 && (theGroup->flags & kLEOContextGroupFlagFromNetwork) == 0 )
	{
		outURL = "file://" + inPath;
	}
	else
	{
		outURL = GetDocument()->GetMediaCache().GetMediaURLByNameOfType( inPath, EMediaTypeMovie );
	}
	if( outURL.length() == 0 )
		outURL = GetDocument()->GetMediaCache().GetMediaURLByNameOfType( "Placeholder Movie", EMediaTypeMovie );
	
	return outURL;
}


void	CMoviePlayerPartMac::SetMediaPath( const std::string& inPath )
{
	if( mRateObserver )
	{
		[mCurrentMovie jcsRemoveObserver: mRateObserver];
		mRateObserver = nil;
	}
	
	std::string	movieURLCpp( SanitizeMediaPath(inPath) );
	NSURL	*	movieURL = [NSURL URLWithString: [NSString stringWithUTF8String: movieURLCpp.c_str()]];
	
	ASSIGN(mCurrentMovie,[AVPlayer playerWithURL: movieURL]);
	mView.player = mCurrentMovie;
	SetUpRateObserver();
	CMoviePlayerPart::SetMediaPath( movieURLCpp );
}


void	CMoviePlayerPartMac::SetCurrentTime( LEOInteger inTicks )
{
	CMoviePlayerPart::SetCurrentTime(inTicks);
	[mCurrentMovie seekToTime: CMTimeMakeWithSeconds( inTicks / 60.0, 1 )];
}


LEOInteger	CMoviePlayerPartMac::GetCurrentTime()
{
	if( mCurrentMovie )
		mCurrentTime = CMTimeGetSeconds([mCurrentMovie currentTime]) * 60.0;
	return mCurrentTime;
}


void	CMoviePlayerPartMac::SetFillColor( int r, int g, int b, int a )
{
	CMoviePlayerPart::SetFillColor( r, g, b, a );

	[mView.layer setBackgroundColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
}


void	CMoviePlayerPartMac::SetLineColor( int r, int g, int b, int a )
{
	CMoviePlayerPart::SetLineColor( r, g, b, a );

	[mView.layer setBorderColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
}


void	CMoviePlayerPartMac::SetShadowColor( int r, int g, int b, int a )
{
	CMoviePlayerPart::SetShadowColor( r, g, b, a );
	
	[mView.layer setShadowOpacity: (a == 0) ? 0.0 : 1.0];
	if( a != 0 )
	{
		[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CMoviePlayerPartMac::SetShadowOffset( double w, double h )
{
	CMoviePlayerPart::SetShadowOffset( w, -h );
	
	[mView.layer setShadowOffset: NSMakeSize(w,-h)];
}


void	CMoviePlayerPartMac::SetShadowBlurRadius( double r )
{
	CMoviePlayerPart::SetShadowBlurRadius( r );
	
	[mView.layer setShadowRadius: r];
}


void	CMoviePlayerPartMac::SetLineWidth( int w )
{
	CMoviePlayerPart::SetLineWidth( w );
	
	[mView.layer setBorderWidth: w];
}


void	CMoviePlayerPartMac::SetPeeking( bool inState )
{
	ApplyPeekingStateToView(inState, mView);
}


void	CMoviePlayerPartMac::SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom )
{
	CMoviePlayerPart::SetRect( left, top, right, bottom );
	[mView setFrame: NSMakeRect(GetLeft(), GetTop(), GetRight() -GetLeft(), GetBottom() -GetTop())];
	GetStack()->RectChangedOfPart( this );
}


void	CMoviePlayerPartMac::SetCursorID( ObjectID inID )
{
	CMoviePlayerPart::SetCursorID( inID );
	if( [mView respondsToSelector: @selector(setCursor:)] )
	{
		[mView setCursor: [NSCursor arrowCursor]];
		GetDocument()->GetMediaCache().GetMediaImageByIDOfType( inID, EMediaTypeCursor,
		[this]( WILDNSImagePtr inImage, int xHotSpot, int yHotSpot )
		{
			NSCursor *theCursor = (GetStack()->GetTool() != EBrowseTool) ? [NSCursor arrowCursor] : [[[NSCursor alloc] initWithImage: inImage hotSpot: NSMakePoint(xHotSpot, yHotSpot)] autorelease];
			[mView setCursor: theCursor];
		} );
	}
}


NSView*	CMoviePlayerPartMac::GetView()
{
	return mView;
}


void	CMoviePlayerPartMac::SetScript( std::string inScript )
{
	CMoviePlayerPart::SetScript( inScript );
	
	[mView updateTrackingAreas];
}


void	CMoviePlayerPartMac::SetPartLayoutFlags( TPartLayoutFlags inFlags )
{
	CMoviePlayerPart::SetPartLayoutFlags( inFlags );
	
	[mView setAutoresizingMask: GetCocoaResizeFlags( mPartLayoutFlags )];
}

