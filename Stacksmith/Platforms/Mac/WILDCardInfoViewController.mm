//
//  WILDCardInfoViewController.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDCardInfoViewController.h"
#import "UKHelperMacros.h"
#include "CCard.h"
#include "CStack.h"


using namespace Carlson;


@implementation WILDCardInfoViewController

@synthesize markedSwitch = mMarkedSwitch;

-(id)	initWithConcreteObject: (CCard*)inCard
{
	if(( self = [super initWithLayer: inCard] ))
	{
	}
	
	return self;
}

-(void)	dealloc
{
	DESTROY_DEALLOC( mMarkedSwitch );
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	[mIDField setIntegerValue: ((CCard*)mLayer)->GetID()];

	[mMarkedSwitch setState: ((CCard*)mLayer)->IsMarked() ? NSControlStateValueOn : NSControlStateValueOff];
	
	size_t		cardNum = mLayer->GetStack()->GetIndexOfCard( (CCard*) mLayer ) +1;
	size_t		numOfCards = mLayer->GetStack()->GetNumCards();
	[mNumberField setStringValue: [NSString stringWithFormat: @"%1$zu out of %2$zu", cardNum, numOfCards]];
}


-(IBAction)	doMarkedSwitchChanged: (id)sender
{
	((CCard*)mLayer)->SetMarked( [mMarkedSwitch state] == NSControlStateValueOn );
}

@end
