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
#import "WILDCardWindowController.h"
#import "WILDNotifications.h"
#import "WILDRecentCardsList.h"


@implementation WILDCard

@synthesize marked = mMarked;

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
		[mOwner addCard: self];
		
		mMarked = WILDBoolFromSubElementInElement( @"marked", elem, NO );	// Only used for copy/paste. In the file, the canonical copy of the marked state is kept in the stack's card list!
	}
	
	return self;
}


-(WILDObjectID)	backgroundID
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


-(WILDObjectID)	cardID
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
		return [NSString stringWithFormat: @"card “%1$@” (ID %2$lld)", mName, mID];
	else
		return [NSString stringWithFormat: @"card ID %1$lld", mID];
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
		NSUInteger	currPartIdx = [mParts indexOfObject: partToSearch];
		if( currPartIdx != NSNotFound )	// Current part is a card part?
		{
			if( inFlags & WILDSearchBackwards )
			{
				if( currPartIdx == 0 )	// This is first card part?
					partToSearch = [[mOwner parts] lastObject];	// Proceed going backwards through bg parts now.
				else
				{
					currPartIdx -= 1;
					partToSearch = [mParts objectAtIndex: currPartIdx];
				}
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
				if( currPartIdx == 0 )	// This was first bg part? We're done with cd parts & bg parts, return failure.
				{
					//NSLog( @"Done with bg parts." );
					break;
				}
				else
				{
					currPartIdx -= 1;
					partToSearch = [[mOwner parts] objectAtIndex: currPartIdx];
				}
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
	
	[theString appendFormat: @"\t<owner>%lld</owner>\n", [mOwner backgroundID]];
	[theString appendFormat: @"\t<marked>%@</marked>\n", (mMarked ? @"<true />" : @"<false />")];	// Only used for copy/paste. The canonical value for the "marked" property is kept in the stack's card list.
}


-(NSString*)	textContents
{
	return nil;
}


-(BOOL)	setTextContents: (NSString*)inString
{
	return NO;
}


-(void)	setTransitionType: (NSString*)inType subtype: (NSString*)inSubtype
{
	WILDDocument	*	theDoc = [[self stack] document];
	if( [[theDoc windowControllers] count] == 0 )
		[theDoc makeWindowControllers];
	WILDCardWindowController*	theWC = [[theDoc windowControllers] objectAtIndex: 0];
	[theWC setTransitionType: inType subtype: inSubtype];
}


-(id<WILDObject>)	parentObject
{
	return mOwner;
}


-(BOOL)	goThereInNewWindow: (BOOL)inNewWindow
{
	WILDDocument	*	theDoc = [[self stack] document];
	if( [[theDoc windowControllers] count] == 0 )
		[theDoc makeWindowControllers];
	WILDCardWindowController*	theWC = [[theDoc windowControllers] objectAtIndex: 0];
	[theWC goToCard: self];
	[theWC showWindow: self];	// TODO: Look up the right window for this stack.
	
	return YES;
}


-(id)	valueForWILDPropertyNamed: (NSString*)inPropertyName ofRange: (NSRange)byteRange
{
	if( [inPropertyName isEqualToString: @"owner"] )
	{
		return [self owningBackground];
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
	
	WILDCard		*	theCard = [self retain];
	WILDBackground	*	theOwner = [mOwner retain];
	NSUInteger			numCds = theOwner.cards.count;
	if( numCds == 1 && theOwner.cantDelete )	// Last card in bg, and bkgnd is delete-protected?
	{
		[theOwner release];
		[theCard release];
		return NO;	// Can't delete last cd of protected bg.
	}
	else if( numCds == 1 && theOwner.stack.backgrounds.count == 1 )	// Last card in stack?
	{
		[theOwner release];
		[theCard release];
		return NO;	// Can't delete last cd in stack.
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDCardWillGoAwayNotification object: theCard];
	
	[[WILDRecentCardsList sharedRecentCardsList] removeCard: theCard];
	[theCard setOwningBackground: nil];
	[theOwner removeCard: theCard];
	[theOwner.stack removeCard: theCard];
	
	if( numCds == 1 )	// Was last cd in bg?
		[theOwner.stack removeBackground: theOwner];	// Delete bg as well.
	
	[theOwner release];
	[theCard release];
	
	return YES;
}

@end
