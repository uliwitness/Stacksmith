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


struct CCanvasEntry
{
	CCanvasEntry() : mColumnIdx(0),	mIndentLevel(0), mRowIdx(0) {};
	CCanvasEntry( const CCanvasEntry& inOriginal ) : mStack(inOriginal.mStack), mBackground(inOriginal.mBackground), mCard(inOriginal.mCard), mColumnIdx(inOriginal.mColumnIdx),	mIndentLevel(inOriginal.mIndentLevel), mRowIdx(inOriginal.mRowIdx) {};
	
	CStackRef		mStack;
	CBackgroundRef	mBackground;
	CCardRef		mCard;
	int				mColumnIdx;
	int				mRowIdx;
	int				mIndentLevel;
};


@interface WILDStackCanvasWindowController ()
{
	std::vector<CCanvasEntry>	items;
}

@end

@implementation WILDStackCanvasWindowController

-(void)	windowDidLoad
{
    [super windowDidLoad];
	
	self.owningDocument->SaveThumbnailsForOpenStacks();
	
	NSURL	*	theURL = [NSURL URLWithString: [NSString stringWithUTF8String: self.owningDocument->GetURL().c_str()]];
	[self.window setRepresentedURL: theURL];
	[self.window setTitle: theURL.lastPathComponent.stringByDeletingPathExtension];
	
	CCanvasEntry	currItem;
	for( size_t x = 0; x < self.owningDocument->GetNumStacks(); x++ )
	{
		currItem.mStack = self.owningDocument->GetStack( x );
		currItem.mStack->Load([](CStack * theStack){});	// +++ Won't work with stacks on internet.
		currItem.mBackground = NULL;
		currItem.mCard = NULL;
		currItem.mIndentLevel = 0;
		currItem.mRowIdx = 0;
		items.push_back( currItem );
		for( size_t y = 0; y < currItem.mStack->GetNumBackgrounds(); y++ )
		{
			currItem.mBackground = currItem.mStack->GetBackground(y);
			currItem.mCard = NULL;
			currItem.mIndentLevel = 1;
			currItem.mRowIdx += 1;
			items.push_back( currItem );
			currItem.mBackground->Load([](CLayer * theBg){});	// +++ Won't work with stacks on internet.
			
			currItem.mIndentLevel = 2;
			for( size_t z = 0; z < currItem.mBackground->GetNumCards(); z++ )
			{
				currItem.mRowIdx += 1;
				currItem.mCard = currItem.mBackground->GetCard(z);
				items.push_back( currItem );
				currItem.mCard->Load([](CLayer * theCd){});	// +++ Won't work with stacks on internet.
			}
		}

		currItem.mColumnIdx++;
	}

	/* Set up a finder icon cell to use: */
	UKFinderIconCell*		bCell = [[[UKFinderIconCell alloc] init] autorelease];
	[bCell setImagePosition: NSImageAbove];
	[bCell setEditable: YES];
	[self.stackCanvasView setPrototype: bCell];
	[self.stackCanvasView setCellSize: NSMakeSize(100.0,80.0)];
	
	[self.stackCanvasView reloadData];
}


-(NSUInteger)	numberOfItemsInDistributedView: (UKDistributedView*)distributedView
{
	return items.size();
}

-(NSPoint)		distributedView: (UKDistributedView*)distributedView
						positionForCell:(NSCell*)cell /* may be nil if the view only wants the item position. */
						atItemIndex: (NSUInteger)row
{
	CCanvasEntry	currItem = items[row];
	if( cell )
	{
		NSImage*		objectImage = currItem.mCard ? [NSImage imageNamed: @"CardIcon"] : (currItem.mBackground ? [NSImage imageNamed: @"BackgroundIcon"] : [NSImage imageNamed: @"StackIcon"]);
		CStack* 			currStack = currItem.mStack;
		CConcreteObject* 	currObject = currItem.mCard ? (CConcreteObject*)currItem.mCard : (currItem.mBackground ? (CConcreteObject*)currItem.mBackground : (CConcreteObject*)currItem.mStack);
		NSString*		nameStr = [NSString stringWithUTF8String: currObject->GetName().c_str()];
		NSImage*		img = nil;
		
		if( currObject == currStack )
		{
			std::string		thumbName = currStack->GetThumbnailName();
			
			if( thumbName.length() > 0 )
			{
				NSURL	*	thumbURL = [NSURL URLWithString: [NSString stringWithUTF8String: currStack->GetURL().c_str()]];
				thumbURL = [thumbURL.URLByDeletingLastPathComponent URLByAppendingPathComponent: [NSString stringWithUTF8String: thumbName.c_str()]];
				img = [[[NSImage alloc] initWithContentsOfURL: thumbURL] autorelease];
			}
		}
		if( !img )
			img = objectImage;
		
		[cell setImage: img];
		[cell setTitle: nameStr];
	}
	
	return NSMakePoint( 10 + currItem.mRowIdx * 100, 10 + currItem.mColumnIdx * 128 );
}


-(void) distributedView: (UKDistributedView*)distributedView cellDoubleClickedAtItemIndex: (NSUInteger)item
{
	CStack*				currStack = items[item].mStack;
	CConcreteObject* 	currObj = items[item].mCard ? (CConcreteObject*)items[item].mCard : (items[item].mBackground ? (CConcreteObject*)items[item].mBackground : (CConcreteObject*)items[item].mStack);
	bool				shouldEditBg = (!items[item].mCard && items[item].mBackground);
	currObj->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [currStack,shouldEditBg](){ currStack->Show(EEvenIfVisible); currStack->SetEditingBackground( shouldEditBg ); } );
}

@end
