//
//  UKProgressPanelController.m
//  Propaganda
//
//  Created by Uli Kusterer on 25.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKProgressPanelController.h"


static UKProgressPanelController*	sSharedProgressController = nil;


@implementation UKProgressPanelController

+(UKProgressPanelController*)sharedProgressController
{
	return sSharedProgressController;
}


-(id)	init
{
	if(( self = [super init] ))
	{
		if( !sSharedProgressController )
			sSharedProgressController = [self retain];
	}
	
	return sSharedProgressController;
}


-(void)	show
{
	[[progress window] makeKeyAndOrderFront: self];
}


-(void)	setIndeterminate: (BOOL)inState
{
	[progress setIndeterminate: inState];
	[progress setUsesThreadedAnimation: YES];
}


-(void)	setDoubleValue: (double)currValue
{
	[progress setDoubleValue: currValue];
	[progress display];
}


-(void)	setMinValue: (double)minValue;
{
	[progress setMinValue: minValue];
}


-(void)	setMaxValue: (double)maxValue;
{
	[progress setMaxValue: maxValue];
}


-(void)	setStringValue: (NSString*)inStatus
{
	[statusField setStringValue: inStatus];
	[progress display];
}


-(void)	hide
{
	[[progress window] orderOut: self];
	[progress setIndeterminate: YES];
	[statusField setStringValue: @""];
}

@end
