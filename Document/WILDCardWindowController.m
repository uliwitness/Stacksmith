//
//  WILDCardWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDCardWindowController.h"
#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDCard.h"
#import "WILDXMLUtils.h"
#import "WILDCardViewController.h"
#import "WILDCardView.h"
#import "NSFileHandle+UKReadLinewise.h"
#import "UKProgressPanelController.h"
#import "NSView+SizeWindowForViewSize.h"
#import "AGIconFamily.h"
#import <Quartz/Quartz.h>


@implementation WILDCardWindowController

- (id)initWithStack: (WILDStack*)inStack
{
    self = [super initWithWindowNibName: NSStringFromClass([self class])];
    if( self )
	{
		[self setShouldCascadeWindows: NO];
		
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
	[self.window centerHorizontallyAndVertically];
	
	[mCardViewController setView: mView];
	[mCardViewController loadCard: [[mStack cards] objectAtIndex: 0]];
		
//	if( [self fileURL] )
//	{
//		NSString*	iconPath = [[[self fileURL] path] stringByAppendingPathComponent: @"Icon\r"];
//		if( ![[NSFileManager defaultManager] fileExistsAtPath: iconPath] )
//			[self performSelector: @selector(generatePreview) withObject: nil afterDelay: 0.0];
//	}
}


-(WILDStack*)	stack
{
	return mStack;
}


-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind
{
	if( inObjectToFind == [mCardViewController currentCard]
		|| inObjectToFind == [[mCardViewController currentCard] owningBackground] )
		return self;	// Window is also visible object for card & bg.
	
	return [mCardViewController visibleObjectForWILDObject: inObjectToFind];
}


-(NSRect)	frameInScreenCoordinates
{
	return [[self window] frame];
}


-(void)	goToCard: (WILDCard*)inCard
{
	[mCardViewController loadCard: inCard];
}


-(WILDCard*)	currentCard
{
	return [mCardViewController currentCard];
}


-(void)	close
{
	[mCardViewController loadCard: nil];
	
	[super close];
}


-(void)	setTransitionType: (NSString*)inType subtype: (NSString*)inSubtype
{
	[mCardViewController setTransitionType: inType subtype: inSubtype];
}

@end
