//
//  WILDIconPickerViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 01.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDIconPickerViewController.h"
#import "WILDPart.h"
#import "WILDStack.h"
#import "WILDNotifications.h"


@implementation WILDIconPickerViewController

@synthesize iconListDataSource;

-(id)	initWithPart: (WILDPart*)inPart
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
	[iconListDataSource setDocument: [[part stack] document]];
	[iconListDataSource setSelectedIconID: [part iconID]];
}


-(void)	iconListDataSourceSelectionDidChange:(WILDIconListDataSource *)inSender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"icon", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setIconID: [iconListDataSource selectedIconID]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}

@end
