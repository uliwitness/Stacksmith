//
//  WILDRecentCardPickerWindowController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@class WILDCardViewController;


@interface WILDRecentCardPickerWindowController : NSWindowController
{
@private
    WILDCardViewController	*	mCardViewController;
	IKImageBrowserView		*	mRecentCardsListView;
	NSMutableArray			*	mRecentCardsList;
}

@property (retain) IBOutlet	IKImageBrowserView *	recentCardsListView;

-(id)		initWithCardViewController: (WILDCardViewController*)inCardVC;

-(IBAction)	doCancelButton: (id)sender;

@end
