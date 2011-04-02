//
//  WILDCardInfoWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDCardInfoWindowController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardView.h"


@implementation WILDCardInfoWindowController

@synthesize markedSwitch = mMarkedSwitch;

-(id)	initWithCard: (WILDCard*)inCard ofCardView: (WILDCardView*)owningView
{
	if(( self = [super initWithLayer: inCard ofCardView: owningView] ))
	{
	}
	
	return self;
}

-(void)	dealloc
{
	DESTROY( mMarkedSwitch );
	
	[super dealloc];
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	[mIDField setIntegerValue: [mLayer cardID]];

	[mMarkedSwitch setState: [(WILDCard*)mLayer marked] ? NSOnState : NSOffState];
	[mIDField setIntegerValue: [(WILDCard*)mLayer cardID]];
	
	NSArray	*		cards = [[mLayer stack] cards];
	unsigned long	cardNum = [cards indexOfObject: mLayer] +1;
	unsigned long	numOfCards = [cards count];
	[mNumberField setStringValue: [NSString stringWithFormat: @"%1$ld out of %2$ld", cardNum, numOfCards]];
}


-(IBAction)	doOKButton: (id)sender
{
	[(WILDCard*)mLayer setMarked: [mMarkedSwitch state] == NSOnState];
	
	[super doOKButton: sender];
}

@end
