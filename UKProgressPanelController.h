//
//  UKProgressPanelController.h
//  Propaganda
//
//  Created by Uli Kusterer on 25.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UKProgressPanelController : NSObject
{
	IBOutlet NSProgressIndicator*	progress;
	IBOutlet NSTextField*			statusField;
}

+(UKProgressPanelController*)	sharedProgressController;

-(void)	show;

-(void)	setIndeterminate: (BOOL)inState;

-(void)	setDoubleValue: (double)currValue;
-(void)	setMinValue: (double)minValue;
-(void)	setMaxValue: (double)maxValue;

-(void)	setStringValue: (NSString*)inStatus;

-(void)	hide;

@end
