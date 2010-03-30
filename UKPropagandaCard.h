//
//  UKPropagandaCard.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKPropagandaBackground.h"
#import "UKPropagandaSearchContext.h"


@interface UKPropagandaCard : UKPropagandaBackground <UKPropagandaSearchable>
{
	UKPropagandaBackground	*	mOwner;
}

-(id)						initWithXMLElement: (NSXMLElement*)elem forStack: (UKPropagandaStack*)theStack;

-(NSInteger)				backgroundID;	// ID of *owning* background.
-(UKPropagandaBackground*)	owningBackground;

-(NSInteger)				cardID;			// ID of this card block.

-(NSInteger)				cardNumber;

@end
