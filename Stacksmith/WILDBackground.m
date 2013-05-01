//
//  WILDBackground.m
//  Stacksmith
//
//  Created by Uli Kusterer on 17.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDBackground.h"
#import "WILDNotifications.h"
#import "WILDStack.h"


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
					forStack: (WILDStack*)theStack error: (NSError**)outError
{
    self = [super initWithXMLDocument: elem forStack: theStack error: outError];
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


-(NSArray*)	cards
{
	return mCards;
}


-(NSString*)	textContents
{
	return nil;
}


-(BOOL)	setTextContents: (NSString*)inString
{
	return NO;
}


-(id<WILDObject>)	parentObject
{
	return mStack;
}


-(BOOL)	goThereInNewWindow: (BOOL)inNewWindow
{
	return [mCards[0] goThereInNewWindow: inNewWindow];
}


-(NSInteger)	backgroundNumber
{
	return [[mStack backgrounds] indexOfObject: self] +1;
}


PROPERTY_MAP_START
PROPERTY_MAPPING(name,"name",kLeoValueTypeString)
PROPERTY_MAPPING(name,"short name",kLeoValueTypeString)
PROPERTY_MAPPING(parentObject,"owner",kLeoValueTypeWILDObject)
PROPERTY_MAPPING(backgroundID,"id",kLeoValueTypeInteger)
PROPERTY_MAPPING(backgroundNumber,"number",kLeoValueTypeInteger)
PROPERTY_MAP_END

@end
