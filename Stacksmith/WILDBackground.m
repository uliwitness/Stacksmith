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
	if( [inPropertyName isEqualToString: @"short name"] || [inPropertyName isEqualToString: @"name"] )
	{
		return [self name];
	}
	else
		return nil;
}


-(BOOL)		setValue: (id)inValue forWILDPropertyNamed: (NSString*)inPropertyName inRange: (NSRange)byteRange
{
	BOOL	propExists = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: inPropertyName
															forKey: WILDAffectedPropertyKey]];
	if( [inPropertyName isEqualToString: @"short name"] || [inPropertyName isEqualToString: @"name"] )
		[self setName: inValue];
	else
		propExists = NO;

	[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: inPropertyName
															forKey: WILDAffectedPropertyKey]];
	if( propExists )
		[self updateChangeCount: NSChangeDone];
	
	return propExists;
}


-(LEOValueTypePtr)	typeForWILDPropertyNamed: (NSString*)inPropertyName;
{
	return &kLeoValueTypeString;
}

@end
