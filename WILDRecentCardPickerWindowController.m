//
//  WILDRecentCardPickerWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDRecentCardPickerWindowController.h"
#import "WILDCardViewController.h"
#import "UKHelperMacros.h"
#import "WILDRecentCardsList.h"


@interface WILDRecentCardListItem : NSObject
{
@private
    NSImage		*	thumbnail;
	WILDCard	*	card;
}

@property (retain) NSImage	*	thumbnail;
@property (retain) WILDCard *	card;

@end


@implementation WILDRecentCardListItem

@synthesize thumbnail;
@synthesize card;

-(NSString *)  imageUID
{
	return [NSString stringWithFormat: @"%p", card];
}


-(NSString *) imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;
}


-(id) imageRepresentation
{
	return thumbnail;
}

@end


@implementation WILDRecentCardPickerWindowController

@synthesize recentCardsListView = mRecentCardsListView;

-(id)	initWithCardViewController: (WILDCardViewController*)inCardVC
{
	if(( self = [super initWithWindowNibName: NSStringFromClass([self class])] ))
	{
		mCardViewController = [inCardVC retain];
		mRecentCardsList = [[NSMutableArray alloc] init];
		
		[self setShouldCascadeWindows: NO];
	}
	
	return self;
}

-(void)	dealloc
{
	DESTROY( mRecentCardsList );
	DESTROY( mRecentCardsListView );
	DESTROY( mCardViewController );
	
	[super dealloc];
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	WILDRecentCardsList	*	rcc = [WILDRecentCardsList sharedRecentCardsList];
	NSUInteger	numCards = [rcc count];
	for( NSUInteger x = 0; x < numCards; x++ )
	{
		WILDRecentCardListItem	* rcli = [[WILDRecentCardListItem alloc] init];
		[rcli setThumbnail: [rcc thumbnailForCardAtIndex: x]];
		[rcli setCard: [rcc cardAtIndex: x]];
		[mRecentCardsList addObject: rcli];
		[rcli release];
	}
	[mRecentCardsListView reloadData];
}


-(IBAction)	showWindow: (id)sender
{
	[[self window] makeKeyAndOrderFrontWithZoomEffectFromRect: NSZeroRect];
}


-(IBAction)	doCancelButton: (id)sender
{
	[[self window] orderOutWithZoomEffectToRect: NSZeroRect];
	[self close];
}


-(NSUInteger) numberOfItemsInImageBrowser: (IKImageBrowserView *) aBrowser;
{
	return [mRecentCardsList count];
}


-(id /*IKImageBrowserItem*/) imageBrowser: (IKImageBrowserView *) aBrowser itemAtIndex: (NSUInteger)itemIdx
{
	return [mRecentCardsList objectAtIndex: itemIdx];
}

@end
