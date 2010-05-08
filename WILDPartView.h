//
//  WILDSelectionView.h
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDTools.h"


@class WILDPart;
@class WILDCardView;


@interface WILDPartView : NSView <WILDSelectableView>
{
	BOOL				mPeeking;		// Are we currently peeking, and should thus draw our bounding box?
	WILDPart*			mPart;			// The part this view represents.
	BOOL				mSelected;		// Should we draw the selection as marching ants around this view?
	NSControl*			mControl;		// The main control in this view representing us.
	NSView*				mHelperView;	// An additional view, e.g. a label text field or so.
}

@property (assign) NSControl*			control;
@property (assign) NSView*				helperView;

-(void)			setPart: (WILDPart*)inPart;
-(WILDPart*)	part;

-(void)	setSelected: (BOOL)inState;

-(void)	subscribeNotifications;
-(void)	unsubscribeNotifications;

-(void)	highlightSearchResultInRange: (NSRange)theRange;

-(WILDCardView*)	enclosingCardView;

-(void)	loadPart: (WILDPart*)currPart forBackgroundEditing: (BOOL)backgroundEditMode;
-(void)	unloadPart;

-(NSImage*)	imageForPeerViews: (NSArray*)views dragStartImagePos: (NSPoint*)dragStartImagePos;

@end



