//
//  UKPropagandaSelectionView.h
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKPropagandaTools.h"


@class UKPropagandaPart;
@class UKPropagandaWindowBodyView;


@interface UKPropagandaSelectionView : NSView <UKPropagandaSelectableView>
{
	BOOL				mPeeking;		// Are we currently peeking, and should thus draw our bounding box?
	UKPropagandaPart*	mPart;			// The part this view represents.
	BOOL				mSelected;		// Should we draw the selection as marching ants around this view?
	NSControl*			mControl;		// The main control in this view representing us.
	NSView*				mHelperView;	// An additiona view, e.g. a label text field or so.
}

@property (assign) NSControl*	control;
@property (assign) NSView*		helperView;

-(void)					setRepresentedPart: (UKPropagandaPart*)inPart;
-(UKPropagandaPart*)	representedPart;

-(void)	setSelected: (BOOL)inState;

-(void)	subscribeNotifications;
-(void)	unsubscribeNotifications;

-(void)	highlightSearchResultInRange: (NSRange)theRange;

-(UKPropagandaWindowBodyView*)	enclosingCardView;

-(void)	loadPart: (UKPropagandaPart*)currPart forBackgroundEditing: (BOOL)backgroundEditMode;
-(void)	unloadPart;

@end



