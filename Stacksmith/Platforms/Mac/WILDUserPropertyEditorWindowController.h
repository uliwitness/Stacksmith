//
//  WILDUserPropertyEditorWindowController.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CConcreteObject.h"
#import "CPart.h"


@class WILDCardView;


@interface WILDUserPropertyEditorWindowController : NSWindowController <NSTableViewDataSource>
{
	Carlson::CConcreteObject*	mContainer;			// Not retained, this is our owner!
	IBOutlet NSTableView*		mTableView;			// List of property->content entries.
	NSRect						mGlobalStartRect;	// For opening animation.
	NSMutableArray*				mUserProperties;
}

-(id)		initWithPropertyContainer: (Carlson::CConcreteObject*)inContainer;

-(void)		setGlobalStartRect: (NSRect)theBox;

-(IBAction)	doAddNewProperty: (id)sender;

@end
