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
#import <AVFoundation/AVFoundation.h>


using namespace Carlson;


struct CCanvasEntry
{
	CCanvasEntry() : mMediaType(EMediaTypeUnknown), mMediaID(0), mColumnIdx(0),	mIndentLevel(0), mRowIdx(0), mIcon(nil) {};
	CCanvasEntry( const CCanvasEntry& inOriginal ) : mStack(inOriginal.mStack), mBackground(inOriginal.mBackground), mCard(inOriginal.mCard), mColumnIdx(inOriginal.mColumnIdx),	mIndentLevel(inOriginal.mIndentLevel), mRowIdx(inOriginal.mRowIdx), mMediaType(inOriginal.mMediaType), mMediaID(inOriginal.mMediaID) { mIcon = [inOriginal.mIcon retain]; };
	~CCanvasEntry()	{ [mIcon release]; }
	
	CCanvasEntry& operator =( const CCanvasEntry& inOriginal )	{ mStack = inOriginal.mStack; mBackground = inOriginal.mBackground; mCard = inOriginal.mCard; mMediaType = inOriginal.mMediaType; mMediaID = inOriginal.mMediaID; mColumnIdx = inOriginal.mColumnIdx; mRowIdx = inOriginal.mRowIdx; mIndentLevel = inOriginal.mIndentLevel; if( mIcon != inOriginal.mIcon ) { [mIcon release]; mIcon = [inOriginal.mIcon retain]; } return *this; }
	
	void	SetIcon( WILDNSImagePtr inImage )	{ if( mIcon != inImage ) { [mIcon release]; mIcon = [inImage retain]; } }
	
	CStackRef		mStack;
	CBackgroundRef	mBackground;
	CCardRef		mCard;
	TMediaType		mMediaType;
	ObjectID		mMediaID;
	int				mColumnIdx;
	int				mRowIdx;
	int				mIndentLevel;
	WILDNSImagePtr	mIcon;
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
	
	currItem.mStack = CStackRef();
	currItem.mBackground = CBackgroundRef();
	currItem.mCard = CCardRef();
	CMediaCache&	mc = self.owningDocument->GetMediaCache();
	size_t numTypes = mc.GetNumMediaTypes();
	size_t currItemIdx = items.size();	// Need index as changing the array may reallocate the items, so can't keep a pointer.
	for( size_t currMediaTypeIdx = 0; currMediaTypeIdx < numTypes; currMediaTypeIdx++ )
	{
		TMediaType	currType = mc.GetMediaTypeAtIndex( currMediaTypeIdx );
		currItem.mRowIdx = 0;
		currItem.mMediaType = currType;
		
		size_t numMedia = mc.GetNumMediaOfType( currType );
		for( size_t currMediaIdx = 0; currMediaIdx < numMedia; currMediaIdx++ )
		{
			currItem.mMediaID = mc.GetIDOfMediaOfTypeAtIndex( currType, currMediaIdx );
			if( mc.GetMediaIsBuiltInByIDOfType( currItem.mMediaID, currType ) )
				continue;
			items.push_back( currItem );
			if( currType == EMediaTypeCursor || currType == EMediaTypeIcon || currType == EMediaTypePicture || currType == EMediaTypePattern )
			{
				mc.GetMediaImageByIDOfType( currItem.mMediaID, currType, [self,currItemIdx]( WILDNSImagePtr inImage, int hotspotX, int hotspotY )
				{
					if( items[currItemIdx].mIcon == nil )
						items[currItemIdx].SetIcon( inImage );
				} );
			}
			currItem.mRowIdx += 1;
			currItemIdx++;
		}
		
		currItem.mColumnIdx += 1;
	}

	/* Set up a finder icon cell to use: */
	UKFinderIconCell*		bCell = [[[UKFinderIconCell alloc] init] autorelease];
	[bCell setImagePosition: NSImageAbove];
	[bCell setEditable: YES];
	[self.stackCanvasView setPrototype: bCell];
	[self.stackCanvasView setCellSize: NSMakeSize(100.0,80.0)];
	
	[self.stackCanvasView reloadData];
	
	[self.stackCanvasView registerForDraggedTypes: [NSImage.imageTypes arrayByAddingObjectsFromArray: @[ NSFilenamesPboardType ]]];
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
		NSImage*		objectImage = currItem.mCard ? [NSImage imageNamed: @"CardIcon"] : (currItem.mBackground ? [NSImage imageNamed: @"BackgroundIcon"] : (currItem.mStack ? [NSImage imageNamed: @"StackIcon"] : [NSImage imageNamed: NSImageNameApplicationIcon]));
		CStack* 			currStack = currItem.mStack;
		CConcreteObject* 	currObject = currItem.mCard ? (CConcreteObject*)currItem.mCard : (currItem.mBackground ? (CConcreteObject*)currItem.mBackground : (currItem.mStack ? (CConcreteObject*)currItem.mStack : nullptr));
		NSString*		nameStr = currObject ? ((currObject->GetName().size() > 0) ? [NSString stringWithUTF8String: currObject->GetName().c_str()] : [NSString stringWithFormat: @"ID %lld", currObject->GetID()]) : [NSString stringWithFormat: @"ID %lld", currItem.mMediaID];
		NSImage*		img = nil;
		
		if( currObject == nullptr )
		{
			CMediaCache&	mc = self.owningDocument->GetMediaCache();
			
			std::string	mediaName = mc.GetMediaNameByIDOfType( currItem.mMediaID, currItem.mMediaType );
			if( mediaName.length() > 0 )
			{
				nameStr = [NSString stringWithUTF8String: mediaName.c_str()];
			}
			else
			{
				nameStr = [NSString stringWithFormat: @"%s %lld", mc.GetNameOfType( currItem.mMediaType ), currItem.mMediaID];
			}
			if( currItem.mIcon )
				objectImage = currItem.mIcon;
		}
		else if( currObject == currStack )
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
	if( currObj )
	{
		currObj->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [currStack,shouldEditBg]()
		{
			currStack->Show(EEvenIfVisible);
			currStack->SetEditingBackground( shouldEditBg );
		} );
	}
}


-(NSDragOperation)  distributedView: (UKDistributedView*)dv validateDrop: (id <NSDraggingInfo>)info proposedItem: (NSUInteger*)row
{
	*row = NSNotFound;

	if( [info.draggingPasteboard canReadObjectForClasses: @[ [NSImage class] ] options: @{}] )
	{
		return NSDragOperationCopy;
	}

	if( [info.draggingPasteboard canReadObjectForClasses: @[ [NSURL class] ] options: @{ NSPasteboardURLReadingContentsConformToTypesKey: NSImage.imageTypes }] )
	{
		return NSDragOperationCopy;
	}
	
	if( [info.draggingPasteboard canReadObjectForClasses: @[ [NSURL class] ] options: @{ NSPasteboardURLReadingContentsConformToTypesKey: AVMovie.movieTypes }] )
	{
		return NSDragOperationLink;
	}
	
	return NSDragOperationNone;
}

// Say whether you accept a drop of an item:
-(BOOL)	distributedView: (UKDistributedView*)dv acceptDrop:(id <NSDraggingInfo>)info onItem:(NSUInteger)row
{
	NSArray*		images = [info.draggingPasteboard readObjectsForClasses: @[ [NSImage class] ] options: @{}];
	if( !images || images.count == 0 )
	{
		NSMutableArray*	fileImages = [NSMutableArray array];
		NSArray*		urls = [info.draggingPasteboard readObjectsForClasses: @[ [NSURL class] ] options: @{ NSPasteboardURLReadingContentsConformToTypesKey: NSImage.imageTypes }];
		for( NSURL* theURL in urls )
		{
			NSImage*	img = [[[NSImage alloc] initWithContentsOfURL: theURL] autorelease];
			if( img )
				[fileImages addObject: img];
		}
		images = fileImages;
	}
	if( images && images.count > 0 )
		[self addImages: images];
	if( !images || images.count == 0 )
	{
		NSArray*		urls = [info.draggingPasteboard readObjectsForClasses: @[ [NSURL class] ] options: @{ NSPasteboardURLReadingContentsConformToTypesKey: AVMovie.movieTypes }];
		[self addMediaURLs: urls mediaType: EMediaTypeMovie];
	}
	
	return YES;
}

// Use this to handle drops on the trash etc:
-(void)				distributedView: (UKDistributedView*)dv dragEndedWithOperation: (NSDragOperation)operation
{
	
}


-(IBAction)	paste: (id)sender
{
	NSPasteboard*	thePastie = [NSPasteboard generalPasteboard];
	NSArray*		images = [thePastie readObjectsForClasses: @[ [NSImage class] ] options: @{}];
	
	[self addImages: images];
}


-(void)	addImages: (NSArray<NSImage*>*)images
{
	// Make a first "new icon" entry as a new row below all existing items (in case there's no media, this will add a new row).
	CCanvasEntry	newIcon;
	newIcon = items[items.size() -1];
	newIcon.mColumnIdx++;
	newIcon.mRowIdx = 0;
	for( auto currItem : items )
	{
		if( currItem.mMediaType == EMediaTypeIcon )
		{
			newIcon = currItem;
			newIcon.mRowIdx++;
		}
	}
	newIcon.mMediaType = EMediaTypeIcon;
	newIcon.mStack = CStackRef();
	newIcon.mCard = CCardRef();
	newIcon.mBackground = CBackgroundRef();
	newIcon.mIndentLevel = 0;
	[newIcon.mIcon release];
	newIcon.SetIcon( nil );
	
	ObjectID		iconToSelect = 0;
	for( NSImage* theImg in images )
	{
		NSString*	pictureName = [theImg name];
		if( !pictureName )
			pictureName = @"From Clipboard";
		ObjectID	pictureID = self.owningDocument->GetMediaCache().GetUniqueIDForMedia();
		
		std::string	filePath = self.owningDocument->GetMediaCache().AddMediaWithIDTypeNameSuffixHotSpotIsBuiltInReturningURL( pictureID, EMediaTypeIcon, [pictureName UTF8String], "png" );
		NSString*	imgFileURLStr = [NSString stringWithUTF8String: filePath.c_str()];
		NSURL*		imgFileURL = [NSURL URLWithString: imgFileURLStr];
		
		[theImg lockFocus];
			NSBitmapImageRep	*	bir = [[NSBitmapImageRep alloc] initWithFocusedViewRect: NSMakeRect(0,0,theImg.size.width,theImg.size.height)];
		[theImg unlockFocus];
		NSData	*	pngData = [bir representationUsingType: NSPNGFileType properties: @{}];
		[pngData writeToURL: imgFileURL atomically: YES];
		newIcon.mMediaID = pictureID;
		newIcon.SetIcon( theImg );
		items.push_back(newIcon);
		iconToSelect = pictureID;
		newIcon.mColumnIdx++;
	}
	
	[self.stackCanvasView reloadData];
}


-(void)	addMediaURLs: (NSArray<NSURL*>*)urls mediaType: (TMediaType)inType
{
	CCanvasEntry	newEntry[EMediaType_Last];
	NSWorkspace*	workspace = [NSWorkspace sharedWorkspace];
	
	ObjectID		iconToSelect = 0;
	for( NSURL* theURL in urls )
	{
		NSString*	pictureName = [[theURL lastPathComponent] stringByDeletingPathExtension];
		ObjectID	pictureID = self.owningDocument->GetMediaCache().GetUniqueIDForMedia();
		TMediaType	currMediaType = inType;
		
		if( currMediaType == EMediaTypeUnknown )
		{
			NSString	*	uti = nil;
			if( [theURL getResourceValue: &uti forKey: NSURLTypeIdentifierKey error: NULL] )
			{
				if( [workspace type: uti conformsToType: @"public.movie"] )
				{
					currMediaType = EMediaTypeMovie;
				}
				else if( [workspace type: uti conformsToType: @"public.image"] )
				{
					currMediaType = EMediaTypeIcon;
				}
				else if( [workspace type: uti conformsToType: @"public.audio"] )
				{
					currMediaType = EMediaTypeSound;
				}
			}
		}
		
		if( currMediaType == EMediaTypeUnknown )
			continue;
		
		CCanvasEntry&	newIcon = newEntry[currMediaType];
		if( newIcon.mMediaType != currMediaType	)
		{
			// Make a first "new icon" entry as a new row below all existing items (in case there's no media, this will add a new row).
			newIcon = items[items.size() -1];
			newIcon.mColumnIdx++;
			newIcon.mRowIdx = 0;
			for( auto currItem : items )
			{
				if( currItem.mMediaType == currMediaType )
				{
					newIcon = currItem;
					newIcon.mRowIdx++;
				}
			}
			newIcon.mMediaType = currMediaType;
			newIcon.mStack = CStackRef();
			newIcon.mCard = CCardRef();
			newIcon.mBackground = CBackgroundRef();
			newIcon.mIndentLevel = 0;
			newIcon.SetIcon( nil );
		}
		
		std::string	filePath = self.owningDocument->GetMediaCache().AddMediaWithIDTypeNameSuffixHotSpotIsBuiltInReturningURL( pictureID, currMediaType, [pictureName UTF8String], [theURL pathExtension].UTF8String );
		NSString*	imgFileURLStr = [NSString stringWithUTF8String: filePath.c_str()];
		NSURL*		imgFileURL = [NSURL URLWithString: imgFileURLStr];
		NSError*	err = nil;
		if( ![[NSFileManager defaultManager] copyItemAtURL: theURL toURL: imgFileURL error: &err] )
		{
			[[NSApplication sharedApplication] presentError: err];
			return;
		}
		newIcon.mMediaID = pictureID;
		if( currMediaType == EMediaTypeIcon || currMediaType == EMediaTypePicture || currMediaType == EMediaTypeCursor || currMediaType == EMediaTypePattern )
		{
			newIcon.SetIcon( [[[NSImage alloc] initWithContentsOfURL: imgFileURL] autorelease] );
		}
		items.push_back(newIcon);
		iconToSelect = pictureID;
		newIcon.mColumnIdx++;
	}
	
	[self.stackCanvasView reloadData];
}


-(IBAction)	pickMediaFile: (id)sender
{
	NSOpenPanel	*	openPanel = [NSOpenPanel openPanel];
	[openPanel beginSheetModalForWindow: self.window completionHandler: ^(NSInteger result)
	{
		if( result == NSFileHandlingPanelOKButton )
		{
			[self addMediaURLs: openPanel.URLs mediaType: EMediaTypeUnknown];
		}
	}];
}


-(IBAction)	delete: (id)sender
{
	NSEnumerator * enny = self.stackCanvasView.selectedItemEnumerator;
	while( NSNumber* currSelItemIdx = [enny nextObject] )
	{
		CCanvasEntry&	entry = items[currSelItemIdx.integerValue];
		std::string		mediaURL = self.owningDocument->GetMediaCache().GetMediaURLByIDOfType( entry.mMediaID, entry.mMediaType);
		[[NSFileManager defaultManager] removeItemAtURL: [NSURL URLWithString: [NSString stringWithUTF8String: mediaURL.c_str()]] error: NULL];
		self.owningDocument->GetMediaCache().DeleteMediaWithIDOfType( entry.mMediaID, entry.mMediaType);
		entry.mMediaType = EMediaTypeUnknown;	// Mark as deleted.
	}
	
	for( auto itty = items.begin(); itty != items.end(); )
	{
		if( itty->mMediaType == EMediaTypeUnknown && itty->mStack == CStackRef() )
		{
			itty = items.erase( itty );
		}
		else
			 itty++;
	}
	
	[self.stackCanvasView reloadData];
}

@end
