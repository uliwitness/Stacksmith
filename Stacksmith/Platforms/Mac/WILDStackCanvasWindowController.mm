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
#import "WILDConcreteObjectInfoViewController.h"
#import "UKHelperMacros.h"


using namespace Carlson;


@interface WILDIconMenuButton : NSButton

@end

@implementation WILDIconMenuButton

- (nullable NSMenu *)menuForEvent:(NSEvent *)event
{
	if( event.type == NSEventTypeLeftMouseUp )
	{
		return self.menu;
	}
	else
	{
		return [super menuForEvent: event];
	}
}

@end


struct CCanvasEntry
{
	CCanvasEntry() : mMediaType(EMediaTypeUnknown), mMediaID(0), mColumnIdx(0),	mIndentLevel(0), mRowIdx(0), mIcon(nil) {};
	CCanvasEntry( const CCanvasEntry& inOriginal ) : mProject(inOriginal.mProject), mMenu(inOriginal.mMenu), mMenuItem(inOriginal.mMenuItem), mStack(inOriginal.mStack), mBackground(inOriginal.mBackground), mCard(inOriginal.mCard), mColumnIdx(inOriginal.mColumnIdx),	mIndentLevel(inOriginal.mIndentLevel), mRowIdx(inOriginal.mRowIdx), mMediaType(inOriginal.mMediaType), mMediaID(inOriginal.mMediaID) { mIcon = [inOriginal.mIcon retain]; };
	~CCanvasEntry()	{ [mIcon release]; }
	
	CCanvasEntry& operator =( const CCanvasEntry& inOriginal )	{ mProject = inOriginal.mProject; mMenu = inOriginal.mMenu; mMenuItem = inOriginal.mMenuItem; mStack = inOriginal.mStack; mBackground = inOriginal.mBackground; mCard = inOriginal.mCard; mMediaType = inOriginal.mMediaType; mMediaID = inOriginal.mMediaID; mColumnIdx = inOriginal.mColumnIdx; mRowIdx = inOriginal.mRowIdx; mIndentLevel = inOriginal.mIndentLevel; if( mIcon != inOriginal.mIcon ) { [mIcon release]; mIcon = [inOriginal.mIcon retain]; } return *this; }
	
	void	SetIcon( WILDNSImagePtr inImage )	{ if( mIcon != inImage ) { [mIcon release]; mIcon = [inImage retain]; } }
	
	CConcreteObject* GetActualObject() { if( mMediaType != EMediaTypeUnknown ) return nullptr; if( mCard ) return mCard; if( mBackground ) return mBackground; if( mStack ) return mStack; if( mMenuItem ) return mMenuItem; if( mMenu ) return mMenu; return mProject; }
	
	CDocumentRef	mProject;
	CMenuRef		mMenu;
	CMenuItemRef	mMenuItem;
	CStackRef		mStack;
	CBackgroundRef	mBackground;
	CCardRef		mCard;
	TMediaType		mMediaType;
	ObjectID		mMediaID;
	int				mColumnIdx;
	int				mRowIdx;
	int				mIndentLevel;
	NSImage		*	mIcon;
};


@interface WILDStackCanvasWindowController ()
{
	std::vector<CCanvasEntry>	items;
	NSPopover*					popover;
}

@end

@implementation WILDStackCanvasWindowController

-(void)	dealloc
{
	DESTROY_DEALLOC(popover);
	
	[super dealloc];
}

-(void)	windowDidLoad
{
    [super windowDidLoad];
	
	[self.plusButton sendActionOn: NSEventMaskLeftMouseDown];
	
	self.owningDocument->SaveThumbnailsForOpenStacks();
	
	NSURL	*	theURL = [NSURL URLWithString: [NSString stringWithUTF8String: self.owningDocument->GetURL().c_str()]];
	[self.window setRepresentedURL: theURL];
	[self.window setTitle: theURL.lastPathComponent.stringByDeletingPathExtension];
	
	/* Set up a finder icon cell to use: */
	UKFinderIconCell*		bCell = [[[UKFinderIconCell alloc] init] autorelease];
	[bCell setImagePosition: NSImageAbove];
	[bCell setEditable: YES];
	[self.stackCanvasView setPrototype: bCell];
	[self.stackCanvasView setCellSize: NSMakeSize(100.0,80.0)];
	
	[self reloadData];
	
	[self.stackCanvasView registerForDraggedTypes: [NSImage.imageTypes arrayByAddingObjectsFromArray: @[ (NSString *)kUTTypeFileURL ]]];
}


-(void)	reloadData
{
	items.erase(items.begin(),items.end());
	
	CCanvasEntry	currItem;
	
	currItem.mProject = self.owningDocument;
	currItem.mStack = nullptr;
	currItem.mBackground = nullptr;
	currItem.mCard = nullptr;
	currItem.mIndentLevel = 0;
	currItem.mRowIdx = 0;
	items.push_back( currItem );
	currItem.mColumnIdx += 1;
	currItem.mProject = nullptr;

	for( size_t x = 0; x < self.owningDocument->GetNumMenus(); x++ )
	{
		currItem.mMenu = self.owningDocument->GetMenu( x );
		currItem.mMenuItem = nullptr;
		currItem.mStack = nullptr;
		currItem.mBackground = nullptr;
		currItem.mCard = nullptr;
		currItem.mIndentLevel = 0;
		currItem.mRowIdx = 0;
		items.push_back( currItem );
		for( size_t y = 0; y < currItem.mMenu->GetNumItems(); y++ )
		{
			currItem.mMenuItem = currItem.mMenu->GetItem(y);
			currItem.mCard = nullptr;
			currItem.mIndentLevel = 1;
			currItem.mRowIdx += 1;
			items.push_back( currItem );
		}
		
		currItem.mColumnIdx++;
	}
	
	currItem.mMenu = nullptr;
	currItem.mMenuItem = nullptr;
	
	for( size_t x = 0; x < self.owningDocument->GetNumStacks(); x++ )
	{
		currItem.mStack = self.owningDocument->GetStack( x );
		currItem.mStack->Load([](CStack * theStack){});	// +++ Won't work with stacks on internet.
		currItem.mBackground = nullptr;
		currItem.mCard = nullptr;
		currItem.mIndentLevel = 0;
		currItem.mRowIdx = 0;
		items.push_back( currItem );
		for( size_t y = 0; y < currItem.mStack->GetNumBackgrounds(); y++ )
		{
			currItem.mBackground = currItem.mStack->GetBackground(y);
			currItem.mCard = nullptr;
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
				mc.GetMediaImageByIDOfType( currItem.mMediaID, currType, [self,currItemIdx]( const CImageCanvas& inImage, int hotspotX, int hotspotY )
										   {
											   if( items[currItemIdx].mIcon == nil )
												   items[currItemIdx].SetIcon( [[[NSImage alloc] initWithCGImage: inImage.GetMacImage() size: NSZeroSize] autorelease] );
										   } );
			}
			currItem.mRowIdx += 1;
			currItemIdx++;
		}
		
		currItem.mColumnIdx += 1;
	}

	[self.stackCanvasView reloadData];
}


-(NSUInteger)	numberOfItemsInDistributedView: (UKDistributedView*)distributedView
{
	return items.size();
}


-(void) concreteCppObject: (CConcreteObject**)outObject image: (NSImage**)outImage stack: (CStack**)outStack forCanvasEntry: (const CCanvasEntry&)currItem
{
	if( outImage )
	{
		NSImage * img = currItem.mCard ? [NSImage imageNamed: @"CardIcon"] : (currItem.mBackground ? [NSImage imageNamed: @"BackgroundIcon"] : (currItem.mStack ? [NSImage imageNamed: @"StackIcon"] : nil));
		if( !img && currItem.mMenuItem )
		{
			img = [NSImage imageNamed: @"MenuItemIcon"];
		}
		if( !img && currItem.mMenu )
		{
			img = [NSImage imageNamed: @"MenuIcon"];
		}
		if( !img && currItem.mProject )
		{
			img = [NSImage imageNamed: @"StackCanvasIcon"];
		}
		if( !img )
		{
			img = [NSImage imageNamed: NSImageNameApplicationIcon];
		}
		*outImage = img;
	}
	if( outStack )
	{
		*outStack = currItem.mStack;
	}
	if( outObject )
	{
		CConcreteObject* 	currObject = currItem.mCard ? (CConcreteObject*)currItem.mCard : (currItem.mBackground ? (CConcreteObject*)currItem.mBackground : (currItem.mStack ? (CConcreteObject*)currItem.mStack : nullptr));
		if( !currObject )
		{
			currObject = currItem.mMenuItem ? (CConcreteObject*)currItem.mMenuItem : (CConcreteObject*)currItem.mMenu;
		}
		if( !currObject )
		{
			currObject = (CConcreteObject*)currItem.mProject;
		}
		*outObject = currObject;
	}
	
}


-(NSPoint)		distributedView: (UKDistributedView*)distributedView
						positionForCell:(NSCell*)cell /* may be nil if the view only wants the item position. */
						atItemIndex: (NSUInteger)row
{
	CCanvasEntry	currItem = items[row];
	if( cell )
	{
		CConcreteObject* 	currObject = nullptr;
		NSImage*			objectImage = nil;
		CStack* 			currStack = nil;
		[self concreteCppObject: &currObject image: &objectImage stack: &currStack forCanvasEntry: currItem];
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


-(void)	distributedView: (UKDistributedView*)distributedView
		   setObjectValue: (id)val
			 forItemIndex: (NSUInteger)row;
{
	CCanvasEntry		currItem = items[row];
	CConcreteObject* 	currObject = nullptr;
	[self concreteCppObject: &currObject image: NULL stack: NULL forCanvasEntry: currItem];
	if( currObject )
		currObject->SetName( ((NSString*)val).UTF8String );
	else
	{
		CMediaCache&	mc = self.owningDocument->GetMediaCache();
		mc.SetMediaNameByIDOfType( ((NSString*)val).UTF8String, currItem.mMediaID, currItem.mMediaType );
	}
}


-(void) distributedView: (UKDistributedView*)distributedView cellDoubleClickedAtItemIndex: (NSUInteger)row
{
	CCanvasEntry	&	currItem = items[row];
	CStack*				currStack = nullptr;
	CConcreteObject* 	currObj = nullptr;
	[self concreteCppObject: &currObj image: NULL stack: &currStack forCanvasEntry: currItem];
	bool				shouldEditBg = (!currItem.mCard && currItem.mBackground);
	if( currObj )
	{
		bool success = currObj->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [currStack,shouldEditBg]()
		{
			currStack->Show(EEvenIfVisible);
			currStack->SetEditingBackground( shouldEditBg );
		}, "", EVisualEffectSpeedNormal );
		if( !success )
		{
			CMacScriptableObjectBase * macPart = dynamic_cast<CMacScriptableObjectBase*>(currObj);
			if( macPart )
			{
				WILDConcreteObjectInfoViewController	*	piv = [[[macPart->GetPropertyEditorClass() alloc] initWithConcreteObject: currObj] autorelease];
				[popover release];
				popover = [[NSPopover alloc] init];
				//popover.delegate = self;
				popover.contentSize = piv.view.frame.size;
				popover.contentViewController = piv;
				[popover setBehavior: NSPopoverBehaviorTransient];
				NSRect itemRect = [distributedView rectForItemAtIndex: row];
				CGFloat distViewHeight = distributedView.frame.size.height;
				itemRect.origin.y = distViewHeight -NSMaxY(itemRect);
				[popover showRelativeToRect: itemRect ofView: distributedView preferredEdge: NSMaxYEdge];
			}
		}
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


-(NSMenu*) distributedView: (UKDistributedView*)distributedView menuForItemIndex: (NSUInteger)item
{
	NSMenu * theMenu = nil;
	CCanvasEntry &		currItem = items[item];
	CScriptableObject * scriptableObject = currItem.GetActualObject();

	if( scriptableObject )
	{
		theMenu = [[[NSMenu alloc] initWithTitle: @"Contextual Menu"] autorelease];
		NSMenuItem * infoItem = [theMenu addItemWithTitle:@"Get Info…" action:@selector(showItemInfo:) keyEquivalent:@""];
		infoItem.target = self;
		infoItem.tag = item;
	}
	
	return theMenu;
}


-(void) showItemInfo:(NSMenuItem *)sender
{
	NSUInteger row = sender.tag;
	UKDistributedView * distributedView = self.stackCanvasView;
	CCanvasEntry & currItem = items[row];
	CConcreteObject * scriptableObject = currItem.GetActualObject();
	CMacScriptableObjectBase * macPart = scriptableObject ? dynamic_cast<CMacScriptableObjectBase*>(scriptableObject) : nullptr;
	if( macPart )
	{
		WILDConcreteObjectInfoViewController * piv = [[[macPart->GetPropertyEditorClass() alloc] initWithConcreteObject: scriptableObject] autorelease];
		[popover release];
		popover = [[NSPopover alloc] init];
		//popover.delegate = self;
		popover.contentSize = piv.view.frame.size;
		popover.contentViewController = piv;
		[popover setBehavior: NSPopoverBehaviorTransient];
		NSRect itemRect = [distributedView rectForItemAtIndex: row];
		CGFloat distViewHeight = distributedView.frame.size.height;
		itemRect.origin.y = distViewHeight -NSMaxY(itemRect);
		[popover showRelativeToRect: itemRect ofView: distributedView preferredEdge: NSMaxYEdge];
	}
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
		
		CGImageRef imageRef = [theImg CGImageForProposedRect:NULL context:NULL hints:nil];
		NSBitmapImageRep *bir = [[NSBitmapImageRep alloc] initWithCGImage: imageRef];
		NSData	*	pngData = [bir representationUsingType: NSBitmapImageFileTypePNG properties: @{}];
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
		if( result == NSModalResponseOK )
		{
			[self addMediaURLs: openPanel.URLs mediaType: EMediaTypeUnknown];
		}
	}];
}


-(IBAction) plusButtonClicked:(id)sender
{
	[self.plusButton.menu popUpMenuPositioningItem: self.plusButton.menu.itemArray.lastObject atLocation: NSMakePoint(NSMaxX(self.plusButton.bounds), NSMinY(self.plusButton.bounds)) inView: self.plusButton];
}


-(IBAction)	addStack: (id)sender
{
	CAutoreleasePool pool;
	
	CStack * newStack = self.owningDocument->AddNewStack();
	
	[self.stackCanvasView reloadData];
	[self selectScriptableObject: newStack];
}


-(IBAction)	addMenu: (id)sender
{
	CAutoreleasePool pool;

	tinyxml2::XMLDocument   document;
	std::string             xml( "<menu><name>New Menu</name></menu>" );
	document.Parse( xml.c_str() );
	CMenu * newMenu = self.owningDocument->NewMenuWithElement(document.RootElement());
	
	[self.stackCanvasView reloadData];
	[self selectScriptableObject: newMenu];
}


-(IBAction)	addMenuItem: (id)sender
{
	CAutoreleasePool pool;
	
	CScriptableObject * selectedObject = self.selectedScriptableObject;
	if( !selectedObject )
		return;
	
	CMenu * selectedMenu = dynamic_cast<CMenu *>(selectedObject);
	CMenuItem * selectedMenuItem = dynamic_cast<CMenuItem *>(selectedObject);
	
	// An item is selected? Append to same menu, *we* probably selected the item when we added an item to the menu before.
	if( !selectedMenu && selectedMenuItem ) {
		selectedMenu = dynamic_cast<CMenu *>(selectedMenuItem->GetParentObject(NULL, NULL));
	}
	
	if( selectedMenu )
	{
		tinyxml2::XMLDocument   document;
		std::string             xml( "<menuitem><name>New Item</name></menuitem>" );
		document.Parse( xml.c_str() );
		CMenuItem * newMenuItem = selectedMenu->NewMenuItemWithElement( document.RootElement() );
		
		[self.stackCanvasView reloadData];
		[self selectScriptableObject: newMenuItem];
	}
}


-(IBAction)	addCard: (id)sender
{
	CAutoreleasePool pool;
	
	CScriptableObject * selectedObject = self.selectedScriptableObject;
	if( !selectedObject )
		return;
	
	CStack * selectedStack = dynamic_cast<CStack *>(selectedObject);
	CCard * selectedCard = dynamic_cast<CCard *>(selectedObject);
	CBackground * selectedBackground = dynamic_cast<CBackground *>(selectedObject);

	if( !selectedBackground && selectedCard ) {
		selectedBackground = selectedCard->GetBackground();
	}

	if( !selectedStack && selectedBackground )
	{
		selectedStack = selectedBackground->GetStack();
	}
	
	if( !selectedBackground && selectedStack )
	{
		selectedBackground = selectedStack->GetBackground(selectedStack->GetNumBackgrounds() - 1);
	}

	if( selectedStack )
	{
		CCard * newCard = selectedStack->AddNewCardWithBackground( selectedBackground );
		[self.stackCanvasView reloadData];
		[self selectScriptableObject: newCard];
	}
}


-(IBAction)	addBackground: (id)sender
{
	CAutoreleasePool pool;
	
	CScriptableObject * selectedObject = self.selectedScriptableObject;
	if( !selectedObject )
		return;
	
	CStack * selectedStack = dynamic_cast<CStack *>(selectedObject);
	CCard * selectedCard = dynamic_cast<CCard *>(selectedObject);
	CBackground * selectedBackground = dynamic_cast<CBackground *>(selectedObject);
	
	if( !selectedStack && selectedCard ) {
		selectedStack = selectedCard->GetStack();
	}
	
	if( !selectedStack && selectedBackground )
	{
		selectedStack = selectedBackground->GetStack();
	}
	
	if( selectedStack )
	{
		CCard * newCard = selectedStack->AddNewCardWithBackground();
		[self.stackCanvasView reloadData];
		[self selectScriptableObject: newCard];
	}
}


-(BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	if( menuItem.action == @selector(addMenuItem:) )
	{
		CScriptableObject * selectedObject = self.selectedScriptableObject;
		if( !selectedObject )
			return NO;
		CMenu * selectedMenu = dynamic_cast<CMenu *>(selectedObject);
		CMenuItem * selectedMenuItem = dynamic_cast<CMenuItem *>(selectedObject);
		return selectedMenu || selectedMenuItem;
	}
	else if( menuItem.action == @selector(addBackground:) || menuItem.action == @selector(addCard:) )
	{
		CScriptableObject * selectedObject = self.selectedScriptableObject;
		if( !selectedObject )
			return NO;
		CStack * selectedStack = dynamic_cast<CStack *>(selectedObject);
		CCard * selectedCard = dynamic_cast<CCard *>(selectedObject);
		CBackground * selectedBackground = dynamic_cast<CBackground *>(selectedObject);
		return selectedStack || selectedCard || selectedBackground;
	}
	else
	{
		return YES;
	}
}


-(void) selectScriptableObject: (CConcreteObject *)obj
{
	NSUInteger x = 0;
	for( CCanvasEntry& currItem : items )
	{
		if( currItem.GetActualObject() == obj )
		{
			[self.stackCanvasView selectItem: x byExtendingSelection: NO];
			break;
		}
		
		++x;
	}
}


-(CScriptableObject *) selectedScriptableObject
{
	if( self.stackCanvasView.selectedItemIndex == NSNotFound )
		return nullptr;
	
	return items[self.stackCanvasView.selectedItemIndex].GetActualObject();
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
