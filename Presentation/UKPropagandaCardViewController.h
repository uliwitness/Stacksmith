//
//  UKPropagandaCardViewController.h
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKPropagandaSearchContext.h"


@class UKPropagandaCard;


@interface UKPropagandaCardViewController : NSViewController
{
	UKPropagandaCard			*	mCurrentCard;
	CALayer						*	mAddColorOverlay;
	BOOL							mPeeking;
	BOOL							mBackgroundEditMode;
	NSMutableDictionary			*	mPartViews;
	UKPropagandaSearchContext	*	mSearchContext;
	NSString					*	mCurrentSearchString;
}

-(void)	loadCard: (UKPropagandaCard*)theCard;

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

-(void)	findNextForward: (BOOL)forwardNotBackward;
-(BOOL)	searchForPattern: (NSString *)inPattern flags: (UKPropagandaSearchFlags)inFlags;
-(BOOL)	searchAgainForPattern: (NSString *)inPattern flags: (UKPropagandaSearchFlags)inFlags;

@end
