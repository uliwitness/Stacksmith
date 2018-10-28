//
//  WILDTemplateProjectPickerController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-01-25.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "WILDTemplateProjectPickerController.h"
#import <Quartz/Quartz.h>
#import "UKHelperMacros.h"


@interface WILDSimpleTemplateProjectBrowserItem : NSObject
{
	NSImage*					mImage;
	NSString*					mName;
	NSString*					mFileName;
}

@property (retain) NSImage*							image;
@property (retain) NSString*						name;
@property (retain) NSString*						filename;

@end

@implementation WILDSimpleTemplateProjectBrowserItem

@synthesize image = mImage;
@synthesize name = mName;
@synthesize filename = mFileName;

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
	return mFileName;
}

-(NSString *) imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;
}

-(id) imageRepresentation
{
	if( !mImage )
	{
		mImage = [[[NSWorkspace sharedWorkspace] iconForFile: mFileName] retain];
	}
	return mImage;
}

-(NSString *) imageTitle
{
	return mName;
}

@end


@implementation WILDTemplateProjectPickerController

@synthesize iconListView;
@synthesize callbackHandler;

-(id)	init
{
	self = [super initWithWindowNibName: NSStringFromClass(self.class) owner: self];
	if( self )
	{
		
	}
	return self;
}


-(void)	dealloc
{
	DESTROY(items);
	DESTROY(callbackHandler);
	
	[super dealloc];
}


-(void)	ensureItemsListExists
{
	if( !items )
	{
		items = [[NSMutableArray alloc] init];
		groups = [[NSMutableArray alloc] init];
		
		NSError	*	err = nil;
		NSString*	templatesPath = [[NSBundle mainBundle] pathForResource: @"Project Templates" ofType: @""];
		NSArray*	subfolderpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: templatesPath error: &err];
		if( !subfolderpaths && err )
		{
			[[NSApplication sharedApplication] presentError: err];
		}
		
		for( NSString* currSubfolderSubPath in subfolderpaths )
		{
			NSString	*	currSubfolderPath = [templatesPath stringByAppendingPathComponent: currSubfolderSubPath];
			NSArray*		subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: currSubfolderPath error: &err];
			
			
			if( !subpaths )
			{
				continue;
			}
			
			NSMutableArray<WILDSimpleTemplateProjectBrowserItem *> *groupContents = [NSMutableArray new];
			
			[groups addObject: @{ @"name": currSubfolderSubPath, @"contents": groupContents } ];

			for( NSString* currSubPath in subpaths )
			{
				NSString	*	currPath = [currSubfolderPath stringByAppendingPathComponent: currSubPath];
				WILDSimpleTemplateProjectBrowserItem	*	tbi = [[[WILDSimpleTemplateProjectBrowserItem alloc] init] autorelease];
				tbi.filename = currPath;
				tbi.name = [[currPath lastPathComponent] stringByDeletingPathExtension];
				[groupContents addObject: tbi];
			}
		}
	}
}


-(void)	windowDidLoad
{
    [super windowDidLoad];
	
	[self ensureItemsListExists];
	
	[iconListView reloadData];
}


- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	[self ensureItemsListExists];
	
	NSDictionary *group = groups[ section ];
	return [(NSArray *)group[@"contents"] count];
}


- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
	[self ensureItemsListExists];
	
	NSDictionary *group = groups[ [indexPath indexAtPosition:0] ];
	
	NSCollectionViewItem *theItem = [collectionView makeItemWithIdentifier: @"StandardItem" forIndexPath: indexPath];
	
	theItem.representedObject = group[@"contents"][ [indexPath indexAtPosition: 1] ];
	
	return theItem;
}


- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
	return groups.count;
}


-(IBAction)	doOK: (id)sender
{
	[self close];
	
	NSInteger	selectedItemIndex = [iconListView selectionIndexes].firstIndex;
	callbackHandler( [items[selectedItemIndex] filename] );
}


-(IBAction)	doCancel: (id)sender
{
	[self close];
}

@end
