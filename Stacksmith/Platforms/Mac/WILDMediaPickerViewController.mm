//
//  WILDMediaPickerViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 01.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDMediaPickerViewController.h"
#import "CButtonPart.h"
#import "CStack.h"


using namespace Carlson;


@implementation WILDMediaPickerViewController

@synthesize iconListDataSource;

-(id)	initWithPart: (CButtonPart*)inPart
{
    self = [super initWithNibName: NSStringFromClass([self class]) bundle: [NSBundle bundleForClass: [self class]]];
    if (self)
	{
		part = inPart;
    }
    
    return self;
}


-(void)	loadView
{
	[super loadView];
	
	[iconListDataSource setDelegate: self];
	[iconListDataSource setDocument: part->GetStack()->GetDocument()];
	[iconListDataSource setSelectedIconID: part->GetIconID()];
}


-(void)	setMediaType: (TMediaType)inType
{
	[iconListDataSource setMediaType: inType];
}


-(TMediaType)	mediaType
{
	return [iconListDataSource mediaType];
}


-(void)	iconListDataSourceSelectionDidChange:(WILDMediaListDataSource *)inSender
{
	part->SetIconID( [iconListDataSource selectedIconID] );
}

@end
