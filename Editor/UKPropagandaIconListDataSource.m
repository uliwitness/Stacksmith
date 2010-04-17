//
//  UKPropagandaIconListDataSource.m
//  Stacksmith
//
//  Created by Uli Kusterer on 05.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "UKPropagandaIconListDataSource.h"
#import "UKPropagandaStack.h"
#import <Quartz/Quartz.h>


@interface UKPropagandaSimpleImageBrowserItem : NSObject // IKImageBrowserItem
{
	NSImage*						mImage;
	NSString*						mName;
	NSString*						mFileName;
	NSInteger						mID;
	UKPropagandaIconListDataSource*	mOwner;	
}

@property (retain) NSImage*							image;
@property (retain) NSString*						name;
@property (retain) NSString*						filename;
@property (assign) NSInteger						pictureID;
@property (assign) UKPropagandaIconListDataSource*	owner;

@end


@implementation UKPropagandaSimpleImageBrowserItem

@synthesize image = mImage;
@synthesize name = mName;
@synthesize filename = mFileName;
@synthesize pictureID = mID;
@synthesize owner = mOwner;

-(void)	dealloc
{
	[mImage release];
	mImage = nil;
	[mName release];
	mName = nil;
	[mFileName release];
	mFileName = nil;
	
	[super dealloc];
}


-(NSString *)  imageUID
{
	return [NSString stringWithFormat: @"%d", mID];
}

-(NSString *) imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;
}

-(id) imageRepresentation
{
	if( !mImage )
		mImage = [[[mOwner stack] pictureOfType: @"icon" id: mID] retain];
	
	return mImage;
}

-(NSString *) imageTitle
{
	return mName;
}

@end


@implementation UKPropagandaIconListDataSource

@synthesize stack = mStack;

-(id)	initWithStack: (UKPropagandaStack*)inStack
{
	if(( self = [super init] ))
	{
		mStack = inStack;
	}
	
	return self;
}


-(void)	dealloc
{
	[mIcons release];
	mIcons = nil;
	
	[super dealloc];
}


-(void)	ensureIconListExists
{
	if( !mIcons )
	{
		mIcons = [[NSMutableArray alloc] init];

		UKPropagandaSimpleImageBrowserItem	*sibi = [[[UKPropagandaSimpleImageBrowserItem alloc] init] autorelease];
		sibi.name = @"No Icon";
		sibi.filename = nil;
		sibi.pictureID = 0;
		sibi.image = [NSImage imageNamed: @"NoIcon"];
		sibi.owner = self;
		[mIcons addObject: sibi];

		NSInteger	x = 0, count = [mStack numberOfPictures];
		for( x = 0; x < count; x++ )
		{
			NSString*	theName = nil;
			NSInteger	theID = 0;
			NSString*	fileName = nil;
			sibi = [[[UKPropagandaSimpleImageBrowserItem alloc] init] autorelease];
			
			[mStack infoForPictureAtIndex: x name: &theName id: &theID
					image: nil fileName: &fileName];
			
			sibi.name = theName;
			sibi.filename = fileName;
			sibi.pictureID = theID;
			sibi.owner = self;
			
			[mIcons addObject: sibi];
		}
		
		[mIconListView setAllowsEmptySelection: NO];
		[mIconListView reloadData];
	}
}


-(void)	setSelectedIconID: (NSInteger)theID
{
	[self ensureIconListExists];
	
	NSInteger		x = 0;
	for( UKPropagandaSimpleImageBrowserItem* sibi in mIcons )
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


-(NSInteger)	selectedIconID
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
		UKPropagandaSimpleImageBrowserItem*	theItem = [mIcons objectAtIndex: selectedIndex];
		NSString*							thePath = [[theItem filename] stringByDeletingLastPathComponent];
		NSString*							resPath = [[NSBundle mainBundle] resourcePath];
		if( [thePath hasPrefix:	resPath] )
			thePath = [[NSBundle mainBundle] bundlePath];
		NSString*							theName = [[NSFileManager defaultManager] displayNameAtPath: thePath];
		NSString*							statusMsg = @"No Icon";
		if( theName )
			statusMsg = [NSString stringWithFormat: @"From %@", theName];
		[mImagePathField setStringValue: statusMsg];
	}
}


-(IBAction)	paste: (id)sender
{
	NSInteger		iconToSelect = 0;
	NSPasteboard*	thePastie = [NSPasteboard generalPasteboard];
	NSArray*		images = [thePastie readObjectsForClasses: [NSArray arrayWithObject: [NSImage class]] options:[NSDictionary dictionary]];
	for( NSImage* theImg in images )
	{
		NSString*		pictureName = @"From Clipboard";
		NSInteger		pictureID = [mStack uniqueIDForMedia];
		[mStack addMediaFile: nil withType: @"icon" name: pictureName
			andID: pictureID
			hotSpot: NSZeroPoint 
			imageOrCursor: theImg];
		
		UKPropagandaSimpleImageBrowserItem	*sibi = [[[UKPropagandaSimpleImageBrowserItem alloc] init] autorelease];
		sibi.name = pictureName;
		sibi.filename = nil;
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

@end
