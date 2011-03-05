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
}

-(WILDCard*)	currentCard;

-(void)		loadCard: (WILDCard*)theCard;
-(void)		reloadCard;

-(IBAction)	goHome: (id)sender;
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

-(IBAction)	showButtonInfoPanel: (id)sender;
-(IBAction)	showFieldInfoPanel: (id)sender;
-(IBAction)	showCardInfoPanel: (id)sender;
-(IBAction)	showBackgroundInfoPanel: (id)sender;
-(IBAction)	showStackInfoPanel: (id)sender;

-(IBAction)	bringObjectCloser: (id)sender;
-(IBAction)	sendObjectFarther: (id)sender;

-(IBAction)	createNewButton: (id)sender;
-(IBAction)	createNewField: (id)sender;
-(IBAction)	createNewBackground: (id)sender;

-(IBAction)	chooseToolWithTag: (id)sender;

-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind;

@end
