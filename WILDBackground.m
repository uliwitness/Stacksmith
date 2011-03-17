//
//  WILDBackground.m
//  Stacksmith
//
//  Created by Uli Kusterer on 17.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDBackground.h"


@implementation WILDBackground

-(id)	initForStack: (WILDStack*)theStack
{
    self = [super initForStack: theStack];
    if( self )
	{
        mCards = [[NSMutableArray alloc] init];
    }
    
    return self;
}


-(id)	initWithXMLDocument: (NSXMLDocument*)elem
					forStack: (WILDStack*)theStack
{
    self = [super initWithXMLDocument: elem forStack: theStack];
    if( self )
	{
        mCards = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
	[mCards release];
	mCards = nil;
	
    [super dealloc];
}


-(void)	addCard: (WILDCard*)theCard
{
	[mCards addObject: theCard];
}


-(void)	removeCard: (WILDCard*)theCard
{
	[mCards removeObject: theCard];
}


-(BOOL)	hasCards
{
	return( [mCards count] > 0 );
}

@end
