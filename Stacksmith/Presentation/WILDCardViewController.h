//
//  WILDCardViewController.h
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDSearchContext.h"
#import "WILDVisibleObject.h"


@class WILDCard;
@class WILDPictureView;
@class WILDGuidelineView;


@interface WILDCardViewController : NSViewController
{
	WILDCard					*	mCurrentCard;
	CALayer						*	mAddColorOverlay;
	BOOL							mPeeking;
	BOOL							mBackgroundEditMode;
	NSMutableDictionary			*	mPartViews;
	WILDSearchContext			*	mSearchContext;
	NSString					*	mCurrentSearchString;
	IBOutlet NSTextField		*	mSearchField;
	WILDPictureView				*	mCardPictureView;
	WILDPictureView				*	mBackgroundPictureView;
	WILDGuidelineView			*	mGuidelineView;
}

-(WILDCard*)	currentCard;

-(void)		loadCard: (WILDCard*)theCard;
-(void)		reloadCard;

-(IBAction)	goHome: (id)sender;
-(IBAction)	goRecentCard: (id)sender;
-(IBAction)	goBack: (id)sender;
-(IBAction)	goFirstCard: (id)sender;
-(IBAction)	goPrevCard: (id)sender;
-(IBAction)	goNextCard: (id)sender;
-(IBAction)	goLastCard: (id)sender;

-(IBAction)	hideFindPanel: (id)sender;
-(IBAction)	showFindPanel: (id)sender;
-(IBAction)	findStringOfObject: (id)sender;
-(IBAction)	findNext: (id)sender;
-(IBAction)	findPrevious: (id)sender;
-(IBAction)	performFindPanelAction: (id)sender;

-(void)		findNextForward: (BOOL)forwardNotBackward;
-(BOOL)		searchForPattern: (NSString *)inPattern flags: (WILDSearchFlags)inFlags;
-(BOOL)		searchAgainForPattern: (NSString *)inPattern flags: (WILDSearchFlags)inFlags;

-(IBAction)	showCardInfoPanel: (id)sender;
-(IBAction)	showBackgroundInfoPanel: (id)sender;
-(IBAction)	showStackInfoPanel: (id)sender;

-(IBAction)	editBackgroundScript: (id)sender;
-(IBAction)	editCardScript: (id)sender;
-(IBAction)	editStackScript: (id)sender;

-(IBAction)	bringObjectCloser: (id)sender;
-(IBAction)	sendObjectFarther: (id)sender;

-(IBAction)	createNewButton: (id)sender;
-(IBAction)	createNewField: (id)sender;
-(IBAction)	createNewCard: (id)sender;
-(IBAction)	cutCard: (id)sender;
-(IBAction)	copyCard: (id)sender;
-(IBAction)	deleteCard: (id)sender;
-(IBAction)	createNewBackground: (id)sender;

-(IBAction)	chooseToolWithTag: (id)sender;

-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind;

-(void)	setTransitionType: (NSString*)inType subtype: (NSString*)inSubtype;

-(WILDGuidelineView*)	guidelineView;

@end
