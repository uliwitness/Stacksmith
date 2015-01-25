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


@interface WILDTemplateProjectPickerController ()

@end

@interface WILDSimpleTemplateProjectBrowserItem : NSObject // IKImageBrowserItem
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
		
		NSInteger		groupCount = 0;
		NSInteger		itemCount = 0;
		
		for( NSString* currSubfolderSubPath in subfolderpaths )
		{
			NSString	*	currSubfolderPath = [templatesPath stringByAppendingPathComponent: currSubfolderSubPath];
			NSArray*		subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: currSubfolderPath error: &err];
			
			NSUInteger	startItemCount = itemCount;
			
			for( NSString* currSubPath in subpaths )
			{
				NSString	*	currPath = [currSubfolderPath stringByAppendingPathComponent: currSubPath];
				WILDSimpleTemplateProjectBrowserItem	*	tbi = [[[WILDSimpleTemplateProjectBrowserItem alloc] init] autorelease];
				tbi.filename = currPath;
				tbi.name = [[currPath lastPathComponent] stringByDeletingPathExtension];
				[items addObject: tbi];
				
				itemCount++;
			}
			
			if( subpaths )
			{
				groupCount++;
				
				[groups addObject: @{ IKImageBrowserGroupRangeKey: [NSValue valueWithRange: (NSRange){ startItemCount, itemCount -startItemCount }], IKImageBrowserGroupTitleKey: currSubfolderSubPath, IKImageBrowserGroupStyleKey: @(IKGroupDisclosureStyle) } ];
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


-(NSUInteger) numberOfItemsInImageBrowser: (IKImageBrowserView *)aBrowser
{
	[self ensureItemsListExists];
	
	return [items count];
}


-(id /*IKImageBrowserItem*/) imageBrowser: (IKImageBrowserView *) aBrowser itemAtIndex: (NSUInteger)idx
{
	[self ensureItemsListExists];
	
	return [items objectAtIndex: idx];
}


- (NSUInteger) numberOfGroupsInImageBrowser:(IKImageBrowserView *) aBrowser
{
	return groups.count;
}


/*!
	@method imageBrowser:groupAtIndex:
	@abstract Returns the group at index 'index'
	@discussion A group is defined by a dictionay. Keys for this dictionary are defined below.
*/
- (NSDictionary *) imageBrowser:(IKImageBrowserView *) aBrowser groupAtIndex:(NSUInteger) index
{
	return groups[index];
}


-(void)	imageBrowserSelectionDidChange: (IKImageBrowserView *)aBrowser
{
	
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
