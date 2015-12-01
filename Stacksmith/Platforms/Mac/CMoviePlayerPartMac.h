//
//  CMoviePlayerPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMoviePlayerPartMac__
#define __Stacksmith__CMoviePlayerPartMac__


#include "CMoviePlayerPart.h"
#include "CMacPartBase.h"
#import "WILDMoviePlayerInfoViewController.h"


@class WILDInvisiblePlayerView;
@class AVPlayer;


namespace Carlson {


class CMoviePlayerPartMac : public CMoviePlayerPart, public CMacPartBase
{
public:
	CMoviePlayerPartMac( CLayer *inOwner ) : CMoviePlayerPart( inOwner ), mView(nil), mRateObserver(nil), mLastNotifiedRate(0.0), mCurrentMovie(nil), mTimeObserver(NULL) {};

	virtual void		WakeUp();
	virtual void		GoToSleep();

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView();
	virtual void	WillBeDeleted()					{ CMacPartBase::WillBeDeleted(); };
	virtual void	SetPeeking( bool inState );

	virtual void		SetStarted( bool inStart );
	virtual void		SetMediaPath( const std::string& inPath );
	virtual void		SetCurrentTime( LEOInteger inTicks );
	virtual LEOInteger	GetCurrentTime();
	virtual void		SetControllerVisible( bool inStart );
	virtual void		SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom );
	virtual void		SetVisible( bool visible )		{ CMoviePlayerPart::SetVisible(visible); [mView setHidden: !visible]; };

	virtual void		SetFillColor( int r, int g, int b, int a );
	virtual void		SetLineColor( int r, int g, int b, int a );
	virtual void		SetShadowColor( int r, int g, int b, int a );
	virtual void		SetShadowOffset( double w, double h );
	virtual void		SetShadowBlurRadius( double r );
	virtual void		SetLineWidth( int w );
	virtual void		SetToolTip( const std::string& inToolTip )	{ CMoviePlayerPart::SetToolTip(inToolTip); [mView setToolTip: [NSString stringWithUTF8String: inToolTip.c_str()]]; };
	virtual void		SetPartLayoutFlags( TPartLayoutFlags inFlags );
	virtual void		SetScript( std::string inScript );

	virtual NSView*		GetView();
	virtual Class		GetPropertyEditorClass()	{ return [WILDMoviePlayerInfoViewController class]; };
	
	virtual void		SetCursorID( ObjectID inID );
	
	virtual void		OpenScriptEditorAndShowOffset( size_t byteOffset )	{ CMacPartBase::OpenScriptEditorAndShowOffset(byteOffset); };
	virtual void		OpenScriptEditorAndShowLine( size_t lineIndex )	{ CMacPartBase::OpenScriptEditorAndShowLine(lineIndex); };
	virtual void		OpenContentsEditor()	{ CMacPartBase::OpenContentsEditor(); };

	virtual std::string	SanitizeMediaPath( const std::string& inPath );
	
protected:
	~CMoviePlayerPartMac();
	
	void			SetUpMoviePlayer();
	void			SetUpMoviePlayerControls();
	void			SetUpRateObserver();
	
	WILDInvisiblePlayerView	*	mView;
	AVPlayer				*	mCurrentMovie;
	id							mRateObserver;
	float						mLastNotifiedRate;
	NSObject				*	mTimeObserver;
};


}

#endif /* defined(__Stacksmith__CMoviePlayerPartMac__) */
