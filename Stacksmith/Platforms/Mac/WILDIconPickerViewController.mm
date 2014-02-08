//
//  WILDIconPickerViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 01.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDIconPickerViewController.h"
#import "CButtonPart.h"
#import "CStack.h"


using namespace Carlson;


@implementation WILDIconPickerViewController

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


-(void)	iconListDataSourceSelectionDidChange:(WILDIconListDataSource *)inSender
{
	part->SetIconID( [iconListDataSource selectedIconID] );
}

@end
