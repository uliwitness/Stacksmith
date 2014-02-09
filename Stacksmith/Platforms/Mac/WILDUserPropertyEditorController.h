//
//  WILDUserPropertyEditorController.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CConcreteObject.h"
#import "CPart.h"


@interface WILDUserPropertyEditorController : NSObject <NSTableViewDataSource>
{
	Carlson::CConcreteObject*	mContainer;			// Not retained, this is our owner!
	IBOutlet NSTableView*		mTableView;			// List of property->content entries.
}

@property (assign,nonatomic) Carlson::CConcreteObject*	propertyContainer;

-(id)		initWithPropertyContainer: (Carlson::CConcreteObject*)inContainer;

-(IBAction)	doAddNewProperty: (id)sender;

@end
