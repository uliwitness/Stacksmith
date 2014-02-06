//
//  WILDUserPropertyEditorWindowController.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDObjectValue.h"
#import "WILDScriptContainer.h"


@class WILDCardView;


@interface WILDUserPropertyEditorWindowController : NSWindowController <NSTableViewDataSource>
{
	id<WILDObject,WILDScriptContainer>	mContainer;			// Not retained, this is our owner!
	IBOutlet NSTableView*				mTableView;			// List of property->content entries.
	NSRect								mGlobalStartRect;	// For opening animation.
	WILDCardView*						mCardView;
	NSMutableArray*						mUserProperties;
}

-(id)		initWithPropertyContainer: (id<WILDObject,WILDScriptContainer>)inContainer;

-(void)		setGlobalStartRect: (NSRect)theBox;

-(void)		setCardView: (WILDCardView*)inView;

-(IBAction)	doAddNewProperty: (id)sender;

@end
