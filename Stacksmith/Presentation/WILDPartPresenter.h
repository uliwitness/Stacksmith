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
-(NSRect)	partRectForPartViewFrame: (NSRect)inRect;
-(NSRect)	partViewFrameForPartRect: (NSRect)inRect;

-(void)		removeSubPartView: (WILDPartView*)inView;
-(void)		addSubPartView: (WILDPartView*)inView;

-(NSView*)	contentView;
-(BOOL)		isViewContainer;		// This container can contain other parts whose needsViewContainer is YES, not just attached objects like timers.
-(BOOL)		needsViewContainer;		// This item needs to be embedded in a card or group, can't be attached to a button.

@end

