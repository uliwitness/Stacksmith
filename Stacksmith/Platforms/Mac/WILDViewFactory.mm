//
//  WILDViewFactory.m
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "WILDViewFactory.h"
#import "WILDButtonView.h"
#import "WILDTextView.h"
#import "WILDTableView.h"
#import "WILDScrollView.h"


static WILDViewFactory*		sViewFactory = nil;

@interface WILDViewFactory ()

@property (assign,nonatomic) IBOutlet WILDButtonView* systemButton;
@property (assign,nonatomic) IBOutlet WILDButtonView* shapeButton;
@property (assign,nonatomic) IBOutlet WILDScrollView* textViewInContainer;
@property (assign,nonatomic) IBOutlet NSPopUpButton* popUpButton;
@property (assign,nonatomic) IBOutlet WILDScrollView* tableViewInContainer;

@property (retain, nonatomic) NSNib* systemButtonNib;
@property (retain, nonatomic) NSNib* shapeButtonNib;
@property (retain, nonatomic) NSNib* popUpButtonNib;
@property (retain, nonatomic) NSNib* textViewInContainerNib;
@property (retain, nonatomic) NSNib* tableViewInContainerNib;

@end


@implementation WILDViewFactory

+(WILDViewFactory*)	sharedViewFactory
{
	if( !sViewFactory )
	{
		sViewFactory = [[WILDViewFactory alloc] init];
	}
	return sViewFactory;
}


-(id) init
{
	self = [super init];
	if( self )
	{
		@try
		{
			_systemButtonNib = [[NSNib alloc] initWithNibNamed: @"WILDViewFactorySystemButton" bundle: [NSBundle bundleForClass: self.class]];
			_shapeButtonNib = [[NSNib alloc] initWithNibNamed: @"WILDViewFactoryShapeButton" bundle: [NSBundle bundleForClass: self.class]];
			_popUpButtonNib = [[NSNib alloc] initWithNibNamed: @"WILDViewFactoryPopUpButton" bundle: [NSBundle bundleForClass: self.class]];
			_textViewInContainerNib = [[NSNib alloc] initWithNibNamed: @"WILDViewFactoryTextViewInContainer" bundle: [NSBundle bundleForClass: self.class]];
			_tableViewInContainerNib = [[NSNib alloc] initWithNibNamed: @"WILDViewFactoryTableViewInContainer" bundle: [NSBundle bundleForClass: self.class]];
		}
		@catch(NSException* localException)
		{
			NSLog(@"exception loading XIB: %@", localException);
		}
	}
	return self;
}


+(WILDButtonView*)	systemButton
{
	NSArray* topLevelObjects = nil;
	[self.sharedViewFactory.systemButtonNib instantiateWithOwner: self.sharedViewFactory topLevelObjects: &topLevelObjects];
	WILDButtonView* result = [[self.sharedViewFactory.systemButton retain] autorelease];
	return result;
}


+(WILDButtonView*)	shapeButton
{
	NSArray* topLevelObjects = nil;
	[self.sharedViewFactory.shapeButtonNib instantiateWithOwner: self.sharedViewFactory topLevelObjects: &topLevelObjects];
	WILDButtonView* result = [[self.sharedViewFactory.shapeButton retain] autorelease];
	return result;
}


+(WILDTextView*)		textViewInContainer
{
	NSArray* topLevelObjects = nil;
	[self.sharedViewFactory.textViewInContainerNib instantiateWithOwner: self.sharedViewFactory topLevelObjects: &topLevelObjects];
	NSScrollView* result = [[self.sharedViewFactory.textViewInContainer retain] autorelease];
	return result.documentView;
}


+(NSPopUpButton*)	popUpButton
{
	NSArray* topLevelObjects = nil;
	[self.sharedViewFactory.popUpButtonNib instantiateWithOwner: self.sharedViewFactory topLevelObjects: &topLevelObjects];
	NSPopUpButton* result = [[self.sharedViewFactory.popUpButton retain] autorelease];
	return result;
}

+(WILDTableView*)	tableViewInContainer
{
	NSArray* topLevelObjects = nil;
	[self.sharedViewFactory.tableViewInContainerNib instantiateWithOwner: self.sharedViewFactory topLevelObjects: &topLevelObjects];
	NSScrollView* result = [[self.sharedViewFactory.tableViewInContainer retain] autorelease];
	return result.documentView;
}

@end
