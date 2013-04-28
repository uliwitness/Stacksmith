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
#import "StacksmithVersion.h"


#define TOSTRING2(x)	#x
#define TOSTRING(x)		TOSTRING2(x)


@interface WILDWebBrowserPresenter ()
{
	BOOL		mCurrentURLAlreadyLoaded;
}

@end


@implementation WILDWebBrowserPresenter

-(void)	dealloc
{
	[self removeSubviews];

	[super dealloc];
}

-(void)	createSubviews
{
	if( !mWebView )
	{
		WILDPart	*	currPart = [mPartView part];
		NSRect			partRect = [currPart quartzRectangle];
		[mPartView setWantsLayer: YES];
		partRect.origin = NSMakePoint( 2, 2 );
		
		mWebView = [[WebView alloc] initWithFrame: partRect];
		[mWebView setWantsLayer: YES];
				
		[mWebView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		[mPartView addSubview: mWebView];
		[mWebView setFrameLoadDelegate: self];
		[mWebView setApplicationNameForUserAgent: @"Stacksmith/" TOSTRING(STACKSMITH_SHORT_VERSION) "." TOSTRING(SVN_VERSION_NUM)];
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
	
	if( currPart.currentURL && ![currPart.currentURL.absoluteString	 isEqualToString: @"about:blank"] )
	{
		NSURLRequest	*	theRequest = [NSURLRequest requestWithURL: currPart.currentURL];
		[mWebView.mainFrame loadRequest: theRequest];
	}
	else
	{
		NSString	*	theText = [contents text];
		if( !theText )
			theText = @"";
		[mWebView.mainFrame loadHTMLString: theText baseURL: nil /*currPart.stack.document.fileURL*/];
	}
}


-(void)	currentURLPropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( !mCurrentURLAlreadyLoaded )
		[self refreshProperties];
}


-(void)	textPropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( !mCurrentURLAlreadyLoaded )
	{
		[mPartView.part setCurrentURL: nil];
		[self refreshProperties];
	}
}


-(void)	removeSubviews
{
	[mWebView removeFromSuperview];
	[mWebView setFrameLoadDelegate: nil];
	DESTROY(mWebView);
}


-(void)		setupCursorRectInPartViewWithDefaultCursor: (NSCursor*)currentCursor;
{
	// Let the WebView set the cursor.
	//UKLog(@"no cursor rects for part %@.", mPartView.part);
}

-(NSRect)	selectionFrame
{
	return [[mPartView superview] convertRect: [mWebView bounds] fromView: mWebView];
}


-(void)	webView: (WebView *)sender didFinishLoadForFrame: (WebFrame *)frame
{
	if( ! mCurrentURLAlreadyLoaded )
	{
		BOOL	cual = mCurrentURLAlreadyLoaded;
		mCurrentURLAlreadyLoaded = YES;
		NSString	*	mainFrameURLString = [sender mainFrameURL];
		NSURL		*	currURL = nil;
		if( mainFrameURLString.length > 0 && ![mainFrameURLString isEqualToString: @"about:blank"] )
			currURL = [NSURL URLWithString: [sender mainFrameURL]];
			
		[mPartView.part setCurrentURL: currURL];
		
		// Now make sure the part's contents match the web page HTML:
		WebFrame *webFrame = [sender mainFrame];
		WebDataSource *source = [webFrame dataSource];
		NSData *data = [source data];
		NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		[[mPartView part] setTextContents: str];
		mCurrentURLAlreadyLoaded = cual;
		
		WILDScriptContainerResultFromSendingMessage( [mPartView part], @"loadPage" );
	}
}


- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	WILDScriptContainerResultFromSendingMessage( [mPartView part], @"loadPage %@", error.localizedDescription );
}

@end
