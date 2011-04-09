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
	DESTROY_DEALLOC( mRecentCardsList );
	DESTROY_DEALLOC( mRecentCardsListView );
	DESTROY_DEALLOC( mCardViewController );
	
	[super dealloc];
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	WILDRecentCardsList	*	rcc = [WILDRecentCardsList sharedRecentCardsList];
	NSInteger				numCards = [rcc count];
	for( NSInteger x = (numCards -1); x >= 0; x-- )
	{
		WILDRecentCardListItem	* rcli = [[WILDRecentCardListItem alloc] init];
		[rcli setThumbnail: [rcc thumbnailForCardAtIndex: x]];
		[rcli setCard: [rcc cardAtIndex: x]];
		[mRecentCardsList addObject: rcli];
		[rcli release];
	}
	
	CGFloat		numItemsPerRow = sqrt(numCards);
	if( numItemsPerRow < 4 )
		numItemsPerRow = 4;
	CGFloat		theWidth = [mRecentCardsListView bounds].size.width -15;
	theWidth -= [mRecentCardsListView intercellSpacing].width * (numItemsPerRow + 2);
	theWidth /= numItemsPerRow;
	[mRecentCardsListView setCellSize: NSMakeSize(theWidth,(theWidth/4.0)*3.0)];
	
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


-(void) imageBrowserSelectionDidChange: (IKImageBrowserView *)aBrowser
{
	NSUInteger	selectedIdx = [[mRecentCardsListView selectionIndexes] firstIndex];
	if( selectedIdx != NSNotFound )
	{
		WILDCard*	theCard = [[mRecentCardsList objectAtIndex: selectedIdx] card];
		[mCardViewController loadCard: theCard];
	}
	
	[[self window] orderOutWithZoomEffectToRect: NSZeroRect];
	[self close];
}

@end
