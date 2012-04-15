//
//  WILDBackgroundInfoWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDBackgroundInfoWindowController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardView.h"


@implementation WILDBackgroundInfoWindowController

-(id)	initWithBackground: (WILDBackground*)inBackground ofCardView: (WILDCardView*)owningView
{
	if(( self = [super initWithLayer: inBackground ofCardView: owningView] ))
	{
	}
	
	return self;
}

-(void)	dealloc
{
	
	
	[super dealloc];
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	[mIDField setIntegerValue: [mLayer backgroundID]];
	
	NSArray	*		cards = [(WILDBackground*)mLayer cards];
	unsigned long	numOfCards = [cards count];
	[mNumberField setStringValue: [NSString stringWithFormat: @"Background shared by %1$ld cards", numOfCards]];
}

@end
