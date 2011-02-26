//
//  WILDCard.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDCard.h"
#import "WILDXMLUtils.h"
#import "WILDStack.h"


@implementation WILDCard

-(id)	initForStack: (WILDStack*)theStack
{
	if(( self = [super initForStack: theStack] ))
	{
		
	}
	
	return self;
}


-(id)	initWithXMLDocument: (NSXMLDocument*)theDoc forStack: (WILDStack*)theStack
{
	if(( self = [super initWithXMLDocument: theDoc forStack: theStack] ))
	{
		NSXMLElement*	elem = [theDoc rootElement];
		
		// mID is set by the superclass already.
		NSInteger bkgdID = WILDIntegerFromSubElementInElement( @"owner", elem );
		mOwner = [theStack backgroundWithID: bkgdID];
	}
	
	return self;
}


-(NSInteger)	backgroundID
{
	return [mOwner backgroundID];
}


-(WILDBackground*)	owningBackground
{
	return mOwner;
}


-(void)	setOwningBackground: (WILDBackground*)theBg
{
	mOwner = theBg;
}


-(NSInteger)	cardID
{
	return mID;
}


-(WILDPartContents*)	contentsForPart: (WILDPart*)thePart
{
	WILDPartContents*	contents = [super contentsForPart: thePart];
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


-(BOOL)	searchForPattern: (NSString*)inPattern withContext: (WILDSearchContext*)inContext
			flags: (WILDSearchFlags)inFlags
{
	WILDPart*	partToSearch = (inContext.currentCard) == self ? inContext.currentPart : nil;
	if( !partToSearch )
	{
		inContext.currentCard = self;
		if( inFlags & WILDSearchBackwards )
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
			if( inFlags & WILDSearchBackwards )
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
			
			if( inFlags & WILDSearchBackwards )
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


-(void)	appendInnerXmlToString: (NSMutableString*)theString
{
	[super appendInnerXmlToString: theString];
	
	[theString appendFormat: @"<owner>%ld</owner>\n", [mOwner backgroundID]];
}

@end
