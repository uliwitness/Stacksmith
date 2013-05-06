//
//  WILDPartView.h
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDTools.h"
#import "WILDVisibleObject.h"


@class WILDPart;
@class WILDCardView;
@class WILDPartContents;
@class WILDPartPresenter;
@class WILDGuidelineView;


// Constants for describing which part was clicked during editing (for resizing etc.)
//	The bit flags here can be combined to indicate corners or the center.
typedef enum
{
  WILDPartGrabHandleNone		= 0,	// None of the "handle" areas clicked.
  WILDPartGrabHandleTop			= (1 << 0),
  WILDPartGrabHandleLeft		= (1 << 1),
  WILDPartGrabHandleRight		= (1 << 2),
  WILDPartGrabHandleBottom		= (1 << 3),
  WILDPartGrabHandleSeparator	= (1 << 4)	// Split view separator or popup title/body separator.
} WILDPartGrabHandle;


@interface WILDPartView : NSView <WILDSelectableView,WILDVisibleObject,NSPopoverDelegate,NSTextViewDelegate,NSTableViewDelegate,NSTableViewDataSource>
{
	BOOL				mPeeking;		// Are we currently peeking, and should thus draw our bounding box?
	WILDPart*			mPart;			// The part this view represents.
	BOOL				mSelected;		// Should we draw the selection as marching ants around this view?
	NSView*				mMainView;		// The main control in this view representing us.
	NSView*				mHelperView;	// An additional view, e.g. a label text field or so.
	BOOL				mIsBackgroundEditing;
	NSPopover*			mCurrentPopover;
	NSTrackingArea*		mMouseEventTrackingArea;
	WILDPartPresenter*	mPartPresenter;
	NSMutableArray*		mSubPartViews;
}

@property (assign) NSView*			mainView;
@property (assign) NSView*			helperView;
@property (assign) BOOL				isBackgroundEditing;

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
-(void)	addToGuidelineView: (WILDGuidelineView*)guidelineView;

+(NSImage*)	imageForPeers: (NSArray*)views ofView: (NSView*)inView dragStartImagePos: (NSPoint*)dragStartImagePos;
+(NSRect)	rectForPeers: (NSArray*)parts dragStartImagePos: (NSPoint*)dragStartImagePos;

-(void)	drawSelectionHighlightInView: (NSView*)overlayView;

-(WILDPartContents*)	currentPartContentsAndBackgroundContents: (WILDPartContents**)outBgContents create: (BOOL)inDoCreate;

-(NSRect)	frameInScreenCoordinates;

-(NSRect)	selectionRect;
-(void)		drawPartFrameInView: (NSView*)overlayView;
-(NSRect)	partRectForPartViewFrame: (NSRect)newBox;
-(NSRect)	partViewFrameForPartRect: (NSRect)newBox;


-(void)	partWillChange: (NSNotification*)notif;
-(void)	partDidChange: (NSNotification*)notif;
-(void)	savePart;

-(IBAction)	showInfoPanel: (id)sender;

-(void)	updateOnClick: (NSButton*)sender;

@end



