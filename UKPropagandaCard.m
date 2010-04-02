//
//  UKPropagandaCard.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaCard.h"
#import "UKPropagandaXMLUtils.h"
#import "UKPropagandaStack.h"


@implementation UKPropagandaCard

-(id)	initForStack: (UKPropagandaStack*)theStack
{
	if(( self = [super initForStack: theStack] ))
	{
		
	}
	
	return self;
}


-(id)	initWithXMLElement: (NSXMLElement*)elem forStack: (UKPropagandaStack*)theStack
{
	if(( self = [super initWithXMLElement: elem forStack: theStack] ))
	{
		// mID is set by the superclass already.
		
		NSInteger bkgdID = UKPropagandaIntegerFromSubElementInElement( @"owner", elem );
		mOwner = [theStack backgroundWithID: bkgdID];
	}
	
	return self;
}


-(NSInteger)	backgroundID
{
	return [mOwner backgroundID];
}


-(UKPropagandaBackground*)	owningBackground
{
	return mOwner;
}


-(void)	setOwningBackground: (UKPropagandaBackground*)theBg
{
	mOwner = theBg;
}


-(NSInteger)	cardID
{
	return mID;
}


-(UKPropagandaPartContents*)	contentsForPart: (UKPropagandaPart*)thePart
{
	UKPropagandaPartContents*	contents = [super contentsForPart: thePart];
	if( !contents )	// We have no per-card contents?
		contents = [mOwner contentsForPart: thePart];	// Maybe bg has shared contents?
	return contents;
}


-(NSString*)	partLayer
{
	return @"card";
}


-(NSInteger)	cardNumber
{
	return [[mStack cards] indexOfObject: self];
}


-(NSString*)	displayName
{
	if( mName && [mName length] > 0 )
		return [NSString stringWithFormat: @"card “%1$@” (ID %2$d)", mName, mID];
	else
		return [NSString stringWithFormat: @"card ID %1$d", mID];
}


-(NSImage*)	displayIcon
{
	return [NSImage imageNamed: @"CardIconSmall"];
}


-(BOOL)	searchForPattern: (NSString*)inPattern withContext: (UKPropagandaSearchContext*)inContext
			flags: (UKPropagandaSearchFlags)inFlags
{
	UKPropagandaPart*	partToSearch = (inContext.currentCard) == self ? inContext.currentPart : nil;
	if( !partToSearch )
	{
		inContext.currentCard = self;
		if( inFlags & UKPropagandaSearchBackwards )
			partToSearch = [mParts lastObject];
		else
		{
			partToSearch = ([[mOwner parts] count] > 0) ? [[mOwner parts] objectAtIndex: 0] : nil;
			if( !partToSearch )
				partToSearch = ([mParts count] > 0) ? [mParts objectAtIndex: 0] : nil;
		}
	}
	if( !partToSearch )
	{
		//NSLog( @"No part found." );
		return NO;
	}
	else
		;//NSLog( @"Searching %@", [partToSearch displayName] );
	
	BOOL		foundSomething = NO;
	
	while( YES )
	{
		foundSomething = [partToSearch searchForPattern: inPattern withContext: inContext flags: inFlags];
		if( foundSomething )
		{
			//NSLog( @"Found something in %@", [partToSearch displayName] );
			break;	// Yaay! we're done!
		}
		
		// Nothing found in this part? Try next part:
		NSInteger	currPartIdx = [mParts indexOfObject: partToSearch];
		if( currPartIdx != NSNotFound )	// Current part is a card part?
		{
			if( inFlags & UKPropagandaSearchBackwards )
			{
				currPartIdx -= 1;
				if( currPartIdx < 0 )	// This was first card part?
					partToSearch = [[mOwner parts] lastObject];	// Proceed going backwards through bg parts now.
				else
					partToSearch = [mParts objectAtIndex: currPartIdx];
			}
			else
			{
				currPartIdx += 1;
				if( currPartIdx >= [mParts count] )	// Last card part? We're done with bg parts & cd parts, return failure.
				{
					//NSLog( @"Done with cd/bg parts." );
					break;
				}
				else
					partToSearch = [mParts objectAtIndex: currPartIdx];
			}
		}
		else	// Current part is a bg part?
		{
			currPartIdx = [[mOwner parts] indexOfObject: partToSearch];
			if( currPartIdx == NSNotFound )	// No cd or bg part?
			{
				//NSLog( @"No parts on this card." );
				break;
			}
			
			if( inFlags & UKPropagandaSearchBackwards )
			{
				currPartIdx -= 1;
				if( currPartIdx < 0 )	// This was first bg part? We're done with cd parts & bg parts, return failure.
				{
					//NSLog( @"Done with bg parts." );
					break;
				}
				else
					partToSearch = [[mOwner parts] objectAtIndex: currPartIdx];
			}
			else
			{
				currPartIdx += 1;
				if( currPartIdx >= [[mOwner parts] count] )	// This was last bg part?
				{
					if( [mParts count] > 0 )
						partToSearch = [mParts objectAtIndex: 0];	// Proceed going forwards through cd parts now.
					else
					{
						//NSLog( @"Done with bg parts, no cd parts." );
						break;		// Last bg part and no cd parts? We're done!
					}
				}
				else
					partToSearch = [[mOwner parts] objectAtIndex: currPartIdx];
			}
		}
		
		//NSLog( @"Searching %@", [partToSearch displayName] );
	}
	
	return foundSomething;
}

@end
