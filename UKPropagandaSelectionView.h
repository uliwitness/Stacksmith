//
//  UKPropagandaSelectionView.h
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UKPropagandaPart;


@protocol UKPropagandaSelectableView

-(void)	setNeedsDisplay: (BOOL)inState;
-(void)	setSelected: (BOOL)inState;

@end



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

-(void)	setRepresentedPart: (UKPropagandaPart*)inPart;

-(void)	setSelected: (BOOL)inState;

-(void)	subscribeNotifications;
-(void)	unsubscribeNotifications;

-(void)	highlightSearchResultInRange: (NSRange)theRange;

@end



// The different tools the selection view can support:
enum
{
	UKPropagandaBrowseTool = 0,			// Regular tool for browsing, clicking, using.
	UKPropagandaPointerTool				// Pointer tool for editing all objects.
};
typedef NSInteger	UKPropagandaTool;


// Helper class that has a timer and tells all currently selected views to
//	update. It also maintains the pattern phase used for the selection's
//	marching ants animation, so they all march the same way.

@interface UKPropagandaTools : NSObject
{
	NSMutableArray*		nonRetainingClients;
	NSInteger			animationPhase;
	NSTimer*			animationTimer;
	NSColor*			peekPattern;
	UKPropagandaTool	tool;
}

+(UKPropagandaTools*)	propagandaTools;

-(void)					animate: (id)sender;
-(NSInteger)			animationPhase;

-(void)					addClient: (id<UKPropagandaSelectableView>)theClient;
-(void)					removeClient: (id<UKPropagandaSelectableView>)theClient;
-(void)					deselectAllClients;

-(NSColor*)				peekPattern;

-(UKPropagandaTool)		currentTool;

@end
