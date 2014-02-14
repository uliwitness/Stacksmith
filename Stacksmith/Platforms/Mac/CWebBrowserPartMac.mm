//
//  CWebBrowserPartMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CWebBrowserPartMac.h"
#import <WebKit/WebKit.h>
#include "CAlert.h"
#include "CStack.h"


using namespace Carlson;


@interface WILDWebBrowserDelegate : NSObject

@property (assign,nonatomic) CWebBrowserPartMac*	owningBrowser;

@end

@implementation WILDWebBrowserDelegate

-(void)	webView: (WebView *)sender didFinishLoadForFrame: (WebFrame *)frame
{
	if( frame == sender.mainFrame )
	{
		const char*	currURLStr = sender.mainFrame.dataSource.request.URL.absoluteString.UTF8String;
		self.owningBrowser->SetCurrentURL( currURLStr );
		self.owningBrowser->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "loadPage" );
	}
}


-(void)	webView: (WebView *)sender didFailLoadWithError: (NSError *)error forFrame: (WebFrame *)frame
{
	self.owningBrowser->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "loadPage %s", error.localizedDescription.UTF8String );
}

@end


void	CWebBrowserPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView.superview == inSuperView )
	{
		[mView removeFromSuperview];
		[inSuperView addSubview: mView];	// Make sure we show up in right layering order.
		return;
	}
	if( mView )
		[mView release];
	if( !mMacDelegate )
	{
		mMacDelegate = [[WILDWebBrowserDelegate alloc] init];
		mMacDelegate.owningBrowser = this;
	}
	mView = [[WebView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	[mView setFrameLoadDelegate: mMacDelegate];
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


void	CWebBrowserPartMac::SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom )
{
	CWebBrowserPart::SetRect( left, top, right, bottom );
	[mView setFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	GetStack()->RectChangedOfPart( this );
}


void	CWebBrowserPartMac::LoadCurrentURL( const std::string& inURL )
{
	if( inURL.length() == 0 )	// No URL? Just load an empty HTML doc filled with our bg color:
	{
		// CSS's rgb() is 0...255, we use 0...65535, so we divide by 65535/255, which is 257:
		NSString* coloredBackgorundHTML = [NSString stringWithFormat: @"<html><head><title></title></head><body style=\"background-color: rgba(%d,%d,%d,%d);\"></body></html>",mFillColorRed / 257,mFillColorGreen / 257,mFillColorBlue / 257,mFillColorAlpha / 257];
		[mView.mainFrame loadHTMLString: coloredBackgorundHTML baseURL: nil];
	}
	else
	{
		NSURLRequest*	theRequest = [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithUTF8String: inURL.c_str()]]];
		[mView.mainFrame loadRequest: theRequest];
	}
}


NSView*	CWebBrowserPartMac::GetView()
{
	return mView;
}


