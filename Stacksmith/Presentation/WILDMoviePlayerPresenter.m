//
//  WILDMoviePlayerPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDMoviePlayerPresenter.h"
#import "WILDPart.h"
#import "WILDPartView.h"
#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDMovieView.h"
#import "UKHelperMacros.h"
#import "WILDPartContents.h"


@implementation WILDMoviePlayerPresenter

-(void)	dealloc
{
	[self removeSubviews];

	[super dealloc];
}

-(void)	createSubviews
{
	[super createSubviews];
	
	if( !mMovieView )
	{
		WILDPart					*currPart = mPartView.part;
		NSRect						partRect = [currPart quartzRectangle];
		[mPartView setWantsLayer: YES];
		partRect.origin = NSMakePoint( 2, 2 );
		
		mMovieView = [[WILDMovieView alloc] initWithFrame: partRect];

		NSColor	*	shadowColor = [currPart shadowColor];
		if( [shadowColor alphaComponent] > 0.0 )
		{
			CGColorRef theColor = [shadowColor CGColor];
			[[mPartView layer] setShadowColor: theColor];
			[[mPartView layer] setShadowOpacity: 1.0];
			[[mPartView layer] setShadowOffset: [currPart shadowOffset]];
			[[mPartView layer] setShadowRadius: [currPart shadowBlurRadius]];
		}
		else
			[[mPartView layer] setShadowOpacity: 0.0];

		[mMovieView setPreservesAspectRatio: YES];
		[mPartView addSubview: mMovieView];
	}
	
	[self refreshProperties];
	
	[mMovieView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
}


-(void)	refreshProperties
{
	WILDPart		*	currPart = [mPartView part];

	[mPartView setHidden: ![currPart visible]];
	
	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[mMovieView layer] setShadowColor: theColor];
		[[mMovieView layer] setShadowOpacity: 1.0];
		[[mMovieView layer] setShadowOffset: [currPart shadowOffset]];
		[[mMovieView layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[mMovieView layer] setShadowOpacity: 0.0];
	
	NSError			* outError = nil;
	NSString		* movPath = [[NSBundle mainBundle] pathForResource: [currPart mediaPath] ofType: @""];
	if( !movPath )
		movPath = [currPart mediaPath];
	QTMovie			* mov = [QTMovie movieWithFile: movPath error: &outError];
	[mov setCurrentTime: [currPart currentTime]];
	[mMovieView setMovie: mov];

	[mMovieView setControllerVisible: [currPart controllerVisible]];
	
	NSRect	theBox = [self rectForLayoutRect: mPartView.part.quartzRectangle];
	[mPartView setFrame: theBox];
}


-(void)	mediaPathPropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	removeSubviews
{
	[mMovieView removeFromSuperview];
	DESTROY(mMovieView);
}


-(void)		setupCursorRectInPartViewWithDefaultCursor: (NSCursor*)currentCursor;
{
	// Let the WebView set the cursor.
	//UKLog(@"no cursor rects for part %@.", mPartView.part);
}

-(NSRect)	selectionFrame
{
	return [[mPartView superview] convertRect: [mMovieView bounds] fromView: mMovieView];
}

@end
