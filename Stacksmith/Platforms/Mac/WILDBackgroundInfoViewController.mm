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

-(id)	initWithBackground: (CBackground*)inBackground
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

@end
