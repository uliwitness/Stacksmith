//
//  WILDBackgroundInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDBackgroundInfoViewController.h"
#import "CBackground.h"
#import "CStack.h"


using namespace Carlson;


@implementation WILDBackgroundInfoViewController

-(id)	initWithConcreteObject: (CBackground*)inBackground
{
	if(( self = [super initWithLayer: inBackground] ))
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
	
	[mIDField setIntegerValue: mLayer->GetID()];
	
	size_t	numOfCards = mLayer->GetStack()->GetNumCardsWithBackground( (CBackground*)mLayer );
	[mNumberField setStringValue: [NSString stringWithFormat: @"Background shared by %1$zu cards", numOfCards]];
}


-(void)	setLayerFieldCount: (unsigned long)numFields buttonCount: (unsigned long)numButtons
{
	[mFieldCountField setStringValue: [NSString stringWithFormat: @"Contains %ld background fields", numFields]];
	[mButtonCountField setStringValue: [NSString stringWithFormat: @"Contains %ld background buttons", numButtons]];
}

@end
