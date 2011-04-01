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
@class WILDPartContents;


// Constants for describing which part was clicked during editing (for resizing etc.)
//	The bit flags here can be combined to indicate corners or the center.
typedef enum
{
  WILDPartGrabHandleNone = 0,	// Center, none of the "handle" areas clicked.
  WILDPartGrabHandleTop		= (1 << 0),
  WILDPartGrabHandleLeft	= (1 << 1),
  WILDPartGrabHandleRight	= (1 << 2),
  WILDPartGrabHandleBottom	= (1 << 3)
} WILDPartGrabHandle;


@interface WILDPartView : NSView <WILDSelectableView>
{
	BOOL				mPeeking;		// Are we currently peeking, and should thus draw our bounding box?
	WILDPart*			mPart;			// The part this view represents.
	BOOL				mSelected;		// Should we draw the selection as marching ants around this view?
	NSView*				mMainView;		// The main control in this view representing us.
	NSView*				mHelperView;	// An additional view, e.g. a label text field or so.
	BOOL				mIsBackgroundEditing;
}

@property (assign) NSView*			mainView;
@property (assign) NSView*			helperView;

-(void)			setPart: (WILDPart*)inPart;
-(WILDPart*)	part;

-(void)	setSelected: (BOOL)inState;
-(BOOL)	myToolIsCurrent;

-(void)	subscribeNotifications;
-(void)	unsubscribeNotifications;

-(void)	highlightSearchResultInRange: (NSRange)theRange;

-(WILDCardView*)	enclosingCardView;

-(void)	loadPart: (WILDPart*)currPart forBackgroundEditing: (BOOL)backgroundEditMode;
-(void)	unloadPart;

+(NSImage*)	imageForPeers: (NSArray*)views ofView: (NSView*)inView dragStartImagePos: (NSPoint*)dragStartImagePos;
+(NSRect)	rectForPeers: (NSArray*)parts dragStartImagePos: (NSPoint*)dragStartImagePos;

-(void)	drawSubView: (NSView*)subview dirtyRect: (NSRect)dirtyRect;

-(WILDPartContents*)	currentPartContentsAndBackgroundContents: (WILDPartContents**)outBgContents create: (BOOL)inDoCreate;

-(NSRect)	frameInScreenCoordinates;

@end



