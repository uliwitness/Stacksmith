//
//  WILDWebBrowserPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDWebBrowserPresenter.h"
#import "WILDPart.h"
#import "WILDPartView.h"
#import <WebKit/WebKit.h>
#import "WILDDocument.h"
#import "WILDStack.h"
#import "UKHelperMacros.h"
#import "WILDPartContents.h"


@interface WILDWebBrowserPresenter ()
{
	BOOL		mCurrentURLAlreadyLoaded;
}

@end


@implementation WILDWebBrowserPresenter

-(void)	createSubviews
{
	if( !mWebView )
	{
		WILDPart	*	currPart = [mPartView part];
		NSRect			partRect = [currPart rectangle];
		[mPartView setWantsLayer: YES];
		partRect.origin = NSMakePoint( 2, 2 );
		
		mWebView = [[WebView alloc] initWithFrame: partRect];
		[mWebView setWantsLayer: YES];
				
		[mWebView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		[mPartView addSubview: mWebView];
		[mWebView setFrameLoadDelegate: self];
//		[mWebView setUIDelegate: self];
	}
	
	[self refreshProperties];
}


-(void)	refreshProperties
{
	WILDPart		*	currPart = [mPartView part];
	WILDPartContents*	contents = nil;
	WILDPartContents*	bgContents = nil;
	
	contents = [mPartView currentPartContentsAndBackgroundContents: &bgContents create: NO];

	[mPartView setHidden: ![currPart visible]];
	
	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[mWebView layer] setShadowColor: theColor];
		[[mWebView layer] setShadowOpacity: 1.0];
		[[mWebView layer] setShadowOffset: [currPart shadowOffset]];
		[[mWebView layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[mWebView layer] setShadowOpacity: 0.0];
	
	if( currPart.currentURL )
	{
		NSURLRequest	*	theRequest = [NSURLRequest requestWithURL: currPart.currentURL];
		[mWebView.mainFrame loadRequest: theRequest];
	}
	else
	{
		NSString	*	theText = [contents text];
		if( !theText )
			theText = @"";
		[mWebView.mainFrame loadHTMLString: theText baseURL: currPart.stack.document.fileURL];
	}
}


-(void)	textPropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	currentURLPropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( !mCurrentURLAlreadyLoaded )
		[self refreshProperties];
}


-(void)	removeSubviews
{
	[mWebView removeFromSuperview];
	DESTROY(mWebView);
}


-(NSRect)	selectionFrame
{
	return [[mPartView superview] convertRect: [mWebView bounds] fromView: mWebView];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	WILDScriptContainerResultFromSendingMessage( [mPartView part], @"loadPage" );
	BOOL	cual = mCurrentURLAlreadyLoaded;
	mCurrentURLAlreadyLoaded = YES;
	[mPartView.part setCurrentURL: [NSURL URLWithString: [sender mainFrameURL]]];
	mCurrentURLAlreadyLoaded = cual;
}


- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	WILDScriptContainerResultFromSendingMessage( [mPartView part], @"loadPage %@", error.localizedDescription );
}

//- (void)webView:(WebView *)sender setStatusText:(NSString *)text
//{
//	[[mPartView part] setStatusMessage: text];
//}
//
//
//- (NSString *)webViewStatusText:(WebView *)sender
//{
//	return [[mPartView part] statusMessage];
//}

@end
