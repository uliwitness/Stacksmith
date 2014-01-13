//
//  CWebBrowserPartMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CWebBrowserPartMac.h"
#import <WebKit/WebKit.h>


using namespace Carlson;


void	CWebBrowserPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView )
		[mView release];
	mView = [[WebView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	NSURLRequest*	theRequest = [NSURLRequest requestWithURL: [NSURL URLWithString: @"http://hammer-language.com"]];
	[mView.mainFrame loadRequest: theRequest];
	[mView setWantsLayer: YES];
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	[inSuperView addSubview: mView];
}


void	CWebBrowserPartMac::SetPeeking( bool inState )
{
	ApplyPeekingStateToView(inState, mView);
}


