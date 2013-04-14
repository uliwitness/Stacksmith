//
//  WILDBackgroundInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDBackgroundInfoViewController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardView.h"
#import "WILDBackground.h"


@implementation WILDBackgroundInfoViewController

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


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	[mIDField setIntegerValue: [mLayer backgroundID]];
	
	NSArray	*		cards = [(WILDBackground*)mLayer cards];
	unsigned long	numOfCards = [cards count];
	[mNumberField setStringValue: [NSString stringWithFormat: @"Background shared by %1$ld cards", numOfCards]];
}

@end
