//
//  WILDMediaListDataSource.m
//  Stacksmith
//
//  Created by Uli Kusterer on 05.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "WILDMediaListDataSource.h"
#import "CStack.h"
#import "CDocument.h"
#import <Quartz/Quartz.h>
#include "CImageCanvas.h"


using namespace Carlson;


@interface WILDSimpleImageBrowserItem : NSObject // IKImageBrowserItem
{
	NSString*					mName;
	NSString*					mFileName;
	BOOL						mIsBuiltIn;
	ObjectID					mID;
	WILDMediaListDataSource*	mOwner;
	CImageCanvas				mImage;
}

@property (retain) NSImage*							image;
@property (retain) NSString*						name;
@property (retain) NSString*						filename;
@property (assign) ObjectID							pictureID;
@property (assign) WILDMediaListDataSource*			owner;
@property (assign) BOOL								isBuiltIn;

@end


@implementation WILDSimpleImageBrowserItem

@synthesize name = mName;
@synthesize filename = mFileName;
@synthesize pictureID = mID;
@synthesize owner = mOwner;
@synthesize isBuiltIn = mIsBuiltIn;

-(id)	init
{
	self = [super init];
	if( self )
	{
		
	}
	return self;
}

-(void)	dealloc
{
	[mName release];
	mName = nil;
	[mFileName release];
	mFileName = nil;
	
	[super dealloc];
}


-(NSString *)  imageUID
{
	return [NSString stringWithFormat: @"%lld", mID];
}

-(NSString *) imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;
}


-(NSImage*)	image
{
	return mImage.GetMacImage();
}


-(void)	setImage:(NSImage *)inImage
{
	mImage = CImageCanvas( inImage );
}


-(id) imageRepresentation
{
	if( !mImage.IsValid() )
	{
		std::string	imagePath = [mOwner document]->GetMediaCache().GetMediaURLByIDOfType( mID, mOwner.mediaType );
		if( imagePath.size() != 0 )
			mImage = CImageCanvas(imagePath);
	}
	if( !mImage.IsValid() )
		mImage = CImageCanvas( [NSImage imageNamed: @"NoIcon"] );
	
	return mImage.GetMacImage();
}

-(NSString *) imageTitle
{
	return mName;
}

@end


@implementation WILDMediaListDataSource

@synthesize document = mDocument;
@synthesize iconListView = mIconListView;
@synthesize imagePathField = mImagePathField;
@synthesize delegate = mDelegate;
@synthesize mediaType = mMediaType;

-(id)	init
{
	if(( self = [super init] ))
	{
		mMediaType = EMediaTypeIcon;
	}
	
	return self;
}


-(void)	dealloc
{
	[mIcons release];
	mIcons = nil;
	[mIconListView release];
	mIconListView = nil;
	[mImagePathField release];
	mImagePathField = nil;
	
	[super dealloc];
}


-(void)	setIconListView: (IKImageBrowserView*)inIconListView
{
	if( mIconListView != inIconListView )
	{
		[mIconListView release];
		mIconListView = [inIconListView retain];
		
		[mIconListView registerForDraggedTypes: [NSArray arrayWithObject: NSURLPboardType]];
	}
}


-(void)	ensureIconListExists
{
	if( !mIcons )
	{
		mIcons = [[NSMutableArray alloc] init];

		WILDSimpleImageBrowserItem	*sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
		if( mMediaType == EMediaTypeIcon )
			sibi.name = @"No Icon";
		else if( mMediaType == EMediaTypePicture )
			sibi.name = @"No Picture";
		else if( mMediaType == EMediaTypeCursor )
			sibi.name = @"Default Cursor";
		else if( mMediaType == EMediaTypeSound )
			sibi.name = @"No Sound";
		else if( mMediaType == EMediaTypeMovie )
			sibi.name = @"No Movie";
		else if( mMediaType == EMediaTypePattern )
			sibi.name = @"No Pattern";
		sibi.filename = nil;
		sibi.pictureID = 0;
		sibi.owner = self;
		[mIcons addObject: sibi];

		NSInteger	x = 0, count = mDocument->GetMediaCache().GetNumMediaOfType( mMediaType );
		for( x = 0; x < count; x++ )
		{
			NSString*		theName = nil;
			ObjectID		theID = 0;
			NSString*		fileName = nil;
			BOOL			isBuiltIn = NO;
			sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
			sibi.owner = self;
			
			theID = mDocument->GetMediaCache().GetIDOfMediaOfTypeAtIndex( mMediaType, x );
			theName = [NSString stringWithUTF8String: mDocument->GetMediaCache().GetMediaNameByIDOfType( theID, mMediaType ).c_str()];
			fileName = [NSString stringWithUTF8String: mDocument->GetMediaCache().GetMediaURLByIDOfType( theID, mMediaType ).c_str()];
			isBuiltIn = mDocument->GetMediaCache().GetMediaIsBuiltInByIDOfType( theID, mMediaType );
			
			sibi.name = theName;
			sibi.filename = fileName;
			sibi.pictureID = theID;
			sibi.isBuiltIn = isBuiltIn;
			
			[mIcons addObject: sibi];
		}
		
		[mIconListView setAllowsEmptySelection: NO];
		[mIconListView reloadData];
	}
}


-(void)	setSelectedIconID: (ObjectID)theID
{
	[self ensureIconListExists];
	
	NSInteger		x = 0;
	for( WILDSimpleImageBrowserItem* sibi in mIcons )
	{
		if( sibi.pictureID == theID )
		{
			[mIconListView setSelectionIndexes: [NSIndexSet indexSetWithIndex: x] byExtendingSelection: NO];
			[mIconListView scrollIndexToVisible: x];
			break;
		}
		x++;
	}
}


-(ObjectID)	selectedIconID
{
	NSInteger	selectedIndex = [[mIconListView selectionIndexes] firstIndex];
	return [[mIcons objectAtIndex: selectedIndex] pictureID];
}


-(NSUInteger) numberOfItemsInImageBrowser: (IKImageBrowserView *)aBrowser
{
	[self ensureIconListExists];
	
	return [mIcons count];
}


-(id /*IKImageBrowserItem*/) imageBrowser: (IKImageBrowserView *) aBrowser itemAtIndex: (NSUInteger)idx
{
	[self ensureIconListExists];
	
	return [mIcons objectAtIndex: idx];
}


-(void)	imageBrowserSelectionDidChange: (IKImageBrowserView *)aBrowser
{
	NSInteger							selectedIndex = [[mIconListView selectionIndexes] firstIndex];
	if( selectedIndex != NSNotFound )
	{
		WILDSimpleImageBrowserItem		*	theItem = [mIcons objectAtIndex: selectedIndex];
		NSString						*	thePath = theItem.isBuiltIn ? [[NSBundle mainBundle] bundlePath] : [[theItem filename] stringByDeletingLastPathComponent];
		NSString*							theName = [[NSFileManager defaultManager] displayNameAtPath: thePath];
		NSString*							statusMsg = @"No Icon";
		if( theName && [theItem pictureID] != 0 )
			statusMsg = [NSString stringWithFormat: @"ID = %lld, from %@", [theItem pictureID], theName];
		[mImagePathField setStringValue: statusMsg];
	}
	
	if( [mDelegate respondsToSelector: @selector(iconListDataSourceSelectionDidChange:)] )
		[mDelegate iconListDataSourceSelectionDidChange: self];
}


-(IBAction)	paste: (id)sender
{
	ObjectID		iconToSelect = 0;
	NSPasteboard*	thePastie = [NSPasteboard generalPasteboard];
	NSArray*		images = [thePastie readObjectsForClasses: [NSArray arrayWithObject: [NSImage class]] options: [NSDictionary dictionary]];
	for( NSImage* theImg in images )
	{
		NSString*	pictureName = [theImg name];
		if( !pictureName )
			pictureName = @"From Clipboard";
		ObjectID	pictureID = mDocument->GetMediaCache().GetUniqueIDForMedia();
		
		std::string	filePath = mDocument->GetMediaCache().AddMediaWithIDTypeNameSuffixHotSpotIsBuiltInReturningURL( pictureID, mMediaType, [pictureName UTF8String], "png" );
		NSString*	imgFileURLStr = [NSString stringWithUTF8String: filePath.c_str()];
		NSURL*		imgFileURL = [NSURL URLWithString: imgFileURLStr];
		
		[theImg lockFocus];
			NSBitmapImageRep	*	bir = [[NSBitmapImageRep alloc] initWithFocusedViewRect: NSMakeRect(0,0,theImg.size.width,theImg.size.height)];
		[theImg unlockFocus];
		NSData	*	pngData = [bir representationUsingType: NSPNGFileType properties: @{}];
		[pngData writeToURL: imgFileURL atomically: YES];
		
		WILDSimpleImageBrowserItem	*sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
		sibi.name = pictureName;
		sibi.filename = imgFileURLStr;
		sibi.pictureID = pictureID;
		sibi.image = theImg;
		sibi.owner = self;
		[mIcons addObject: sibi];
		iconToSelect = pictureID;
	}
	[mIconListView reloadData];
	if( iconToSelect != 0 )
		[self setSelectedIconID: iconToSelect];
}


//-(void)	delete:(id)sender
//{
//	
//}


- (NSDragOperation)draggingEntered: (id <NSDraggingInfo>)sender
{
	return [self draggingUpdated: sender];
}


- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSPasteboard*	pb = [sender draggingPasteboard];
	if( [pb canReadObjectForClasses: [NSArray arrayWithObject: [NSURL class]] options: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], NSPasteboardURLReadingFileURLsOnlyKey, [NSArray arrayWithObject: @"public.image"], NSPasteboardURLReadingContentsConformToTypesKey, nil]] )
	{
		[mIconListView setDropIndex: -1 dropOperation: IKImageBrowserDropOn];
		
		return NSDragOperationCopy;
	}
	else
		return NSDragOperationNone;
}


- (BOOL)performDragOperation: (id <NSDraggingInfo>)sender
{
	ObjectID			iconToSelect = 0;
	NSPasteboard*		pb = [sender draggingPasteboard];
	NSArray	*		urls = [pb readObjectsForClasses: [NSArray arrayWithObject: [NSURL class]] options: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], NSPasteboardURLReadingFileURLsOnlyKey, [NSArray arrayWithObject: @"public.image"], NSPasteboardURLReadingContentsConformToTypesKey, nil]];
	
	if( urls.count > 0 )
	{
		for( NSURL* theImgFile in urls )
		{
			NSImage *		theImg = [[[NSImage alloc] initWithContentsOfURL: theImgFile] autorelease];
			NSString*		pictureName = [[NSFileManager defaultManager] displayNameAtPath: [theImgFile path]];
			ObjectID	pictureID = mDocument->GetMediaCache().GetUniqueIDForMedia();
			
			std::string	filePath = mDocument->GetMediaCache().AddMediaWithIDTypeNameSuffixHotSpotIsBuiltInReturningURL( pictureID, mMediaType, [pictureName UTF8String], "png" );
			NSString*	imgFileURLStr = [NSString stringWithUTF8String: filePath.c_str()];
			NSURL*		imgFileURL = [NSURL URLWithString: imgFileURLStr];
			
			[theImg lockFocus];
				NSBitmapImageRep	*	bir = [[NSBitmapImageRep alloc] initWithFocusedViewRect: NSMakeRect(0,0,theImg.size.width,theImg.size.height)];
			[theImg unlockFocus];
			NSData	*	pngData = [bir representationUsingType: NSPNGFileType properties: @{}];
			[pngData writeToURL: imgFileURL atomically: YES];
			
			WILDSimpleImageBrowserItem	*sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
			sibi.name = pictureName;
			sibi.filename = imgFileURLStr;
			sibi.pictureID = pictureID;
			sibi.image = theImg;
			sibi.owner = self;
			[mIcons addObject: sibi];
			iconToSelect = pictureID;
		}
	}
	else
	{
		NSArray*		images = [pb readObjectsForClasses: [NSArray arrayWithObject: [NSImage class]] options:[NSDictionary dictionary]];
		for( NSImage* theImg in images )
		{
			NSString*		pictureName = @"Dropped Image";
			ObjectID	pictureID = mDocument->GetMediaCache().GetUniqueIDForMedia();
			
			std::string	filePath = mDocument->GetMediaCache().AddMediaWithIDTypeNameSuffixHotSpotIsBuiltInReturningURL( pictureID, mMediaType, [pictureName UTF8String], "png" );
			NSString*	imgFileURLStr = [NSString stringWithUTF8String: filePath.c_str()];
			NSURL*		imgFileURL = [NSURL URLWithString: imgFileURLStr];
			
			[theImg lockFocus];
				NSBitmapImageRep	*	bir = [[NSBitmapImageRep alloc] initWithFocusedViewRect: NSMakeRect(0,0,theImg.size.width,theImg.size.height)];
			[theImg unlockFocus];
			NSData	*	pngData = [bir representationUsingType: NSPNGFileType properties: @{}];
			[pngData writeToURL: imgFileURL atomically: YES];
			
			WILDSimpleImageBrowserItem	*sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
			sibi.name = pictureName;
			sibi.filename = imgFileURLStr;
			sibi.pictureID = pictureID;
			sibi.image = theImg;
			sibi.owner = self;
			[mIcons addObject: sibi];
			iconToSelect = pictureID;
		}
	}
	[mIconListView reloadData];
	if( iconToSelect != 0 )
		[self setSelectedIconID: iconToSelect];
	
	return( urls != 0 && [urls count] > 0 );
}

@end
