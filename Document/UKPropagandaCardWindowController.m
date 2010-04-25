//
//  UKPropagandaCardWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "UKPropagandaCardWindowController.h"
#import "UKPropagandaDocument.h"
#import "UKPropagandaStack.h"
#import "UKPropagandaCard.h"
#import "UKPropagandaXMLUtils.h"
#import "UKPropagandaCardViewController.h"
#import "UKPropagandaWindowBodyView.h"
#import "NSFileHandle+UKReadLinewise.h"
#import "UKProgressPanelController.h"
#import "NSView+SizeWindowForViewSize.h"
#import "AGIconFamily.h"
#import <Quartz/Quartz.h>


@implementation UKPropagandaCardWindowController

- (id)init
{
    self = [super init];
    if (self)
	{
		mStack = [[UKPropagandaStack alloc] init];
    }
    return self;
}


-(void)	dealloc
{
	mCardViewController = nil;	// It's an outlet now.
	
	DESTROY(mStack);
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	// Make sure window fits the cards:
	NSSize		cardSize = [mStack cardSize];
	if( cardSize.width == 0 || cardSize.height == 0 )
		cardSize = NSMakeSize( 512, 342 );
	[mView sizeWindowForViewSize: cardSize];
	
	[mCardViewController setView: mView];
	[mCardViewController loadCard: [[mStack cards] objectAtIndex: 0]];
}

@end
