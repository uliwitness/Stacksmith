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


-(id)	valueForWILDPropertyNamed: (NSString*)inPropertyName ofRange: (NSRange)byteRange
{
	if( [inPropertyName isEqualToString: @"owner"] )
	{
		return [self stack];
	}
	else
		return [super valueForWILDPropertyNamed: inPropertyName ofRange:byteRange];
}


-(LEOValueTypePtr)	typeForWILDPropertyNamed: (NSString*)inPropertyName
{
	if( [inPropertyName isEqualToString: @"owner"] )
		return &kLeoValueTypeWILDObject;
	else
		return [super typeForWILDPropertyNamed: inPropertyName];
}

-(BOOL)	deleteWILDObject
{
	if( self.cantDelete )
		return NO;
	
	[[self stack] removeBackground: self];
	
	return YES;
}

@end
