//
//  WILDPartPresenter.h
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <AppKit/AppKit.h>


@class WILDPart;
@class WILDPartView;


@interface WILDPartPresenter : NSObject
{
	WILDPartView	*	mPartView;
}

-(id)		initWithPartView: (WILDPartView*)inPartView;

-(void)		createSubviews;
-(void)		refreshProperties;
-(void)		removeSubviews;

-(void)		partWillChange: (NSNotification*)inPart;
-(void)		partDidChange: (NSNotification*)inPart;

-(void)		setupCursorRectInPartViewWithDefaultCursor: (NSCursor*)currentCursor;
-(NSRect)	selectionFrame;	// Frame coord. system of the part view. I.e. local to part view's superview.
-(NSRect)	layoutRectForRect: (NSRect)inRect;
-(NSRect)	rectForLayoutRect: (NSRect)inRect;

@end

