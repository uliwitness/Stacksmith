//
//  WILDStackCanvasWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-02-11.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "WILDStackCanvasWindowController.h"
#import "UKDistributedView.h"
#import "UKFinderIconCell.h"
#include "CDocument.h"


using namespace Carlson;


@interface WILDStackCanvasWindowController ()

@end

@implementation WILDStackCanvasWindowController

-(void)	windowDidLoad
{
    [super windowDidLoad];
	
	self.owningDocument->SaveThumbnailsForOpenStacks();
	
	/* Set up a finder icon cell to use: */
	UKFinderIconCell*		bCell = [[[UKFinderIconCell alloc] init] autorelease];
	[bCell setImagePosition: NSImageAbove];
	[bCell setEditable: YES];
	[self.stackCanvasView setPrototype: bCell];
	[self.stackCanvasView setCellSize: NSMakeSize(100.0,80.0)];
	
	[self.stackCanvasView reloadData];
	
	NSURL	*	theURL = [NSURL URLWithString: [NSString stringWithUTF8String: self.owningDocument->GetURL().c_str()]];
	[self.window setRepresentedURL: theURL];
	[self.window setTitle: theURL.lastPathComponent.stringByDeletingPathExtension];
}


-(NSUInteger)	numberOfItemsInDistributedView: (UKDistributedView*)distributedView
{
	return self.owningDocument->GetNumStacks();
}

-(NSPoint)		distributedView: (UKDistributedView*)distributedView
						positionForCell:(NSCell*)cell /* may be nil if the view only wants the item position. */
						atItemIndex: (NSUInteger)row
{
	if( cell )
	{
		NSImage*	stackImage = [NSImage imageNamed: @"Stack"];
		CStack* 	currStack = self.owningDocument->GetStack( row );
		NSString*	nameStr = [NSString stringWithUTF8String: currStack->GetName().c_str()];
		NSImage*	img = stackImage;
		std::string	thumbName = currStack->GetThumbnailName();
		
		if( thumbName.length() > 0 )
		{
			NSURL	*	thumbURL = [NSURL URLWithString: [NSString stringWithUTF8String: currStack->GetURL().c_str()]];
			thumbURL = [thumbURL.URLByDeletingLastPathComponent URLByAppendingPathComponent: [NSString stringWithUTF8String: thumbName.c_str()]];
			img = [[[NSImage alloc] initWithContentsOfURL: thumbURL] autorelease];
		}
		
		[cell setImage: img];
		[cell setTitle: nameStr];
	}
	
	return NSMakePoint( 10, 10 +(128 * row) );
}


-(void) distributedView: (UKDistributedView*)distributedView cellDoubleClickedAtItemIndex: (NSUInteger)item
{
	CStack* 	currStack = self.owningDocument->GetStack( item );
	currStack->Show( EEvenIfVisible );
}

@end
