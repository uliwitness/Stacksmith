//
//  UKPropagandaCardWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDCardWindowController.h"
#import "WILDDocument.h"
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


@implementation WILDCardWindowController

- (id)initWithStack: (UKPropagandaStack*)inStack
{
    self = [super initWithWindowNibName: NSStringFromClass([self class])];
    if( self )
	{
		mStack = inStack;
    }
    return self;
}


-(void)	dealloc
{
	mCardViewController = nil;	// It's an outlet now.
	mStack = nil;
	
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
		
//	if( [self fileURL] )
//	{
//		NSString*	iconPath = [[[self fileURL] path] stringByAppendingPathComponent: @"Icon\r"];
//		if( ![[NSFileManager defaultManager] fileExistsAtPath: iconPath] )
//			[self performSelector: @selector(generatePreview) withObject: nil afterDelay: 0.0];
//	}
}

@end
