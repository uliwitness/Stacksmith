//
//  WILDStack.m
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDStack.h"
#import "WILDXMLUtils.h"
#import "WILDBackground.h"
#import "WILDCard.h"
#import "WILDStack.h"
#import "UKRandomInteger.h"
#import <QTKit/QTKit.h>


@implementation WILDStack

-(id)	initWithDocument: (WILDDocument*)theDocument
{
	if(( self = [super init] ))
	{
		mUserLevel = 5;
		
		mCantModify = NO;
		mCantDelete = NO;
		mPrivateAccess = NO;
		mCantAbort = NO;
		mCantPeek = NO;
		
		mDocument = theDocument;
		
//		NSString*	appVersion = [NSString stringWithFormat: @"Stacksmith %@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]];
//		mCreatedByVersion = [appVersion retain];
//		mLastCompactedVersion = [appVersion retain];
//		mFirstEditedVersion = [appVersion retain];
//		mLastEditedVersion = [appVersion retain];
		
		mCardSize = NSMakeSize( 512, 342 );
		
		mScript = [@"" retain];
		
		WILDBackground*		firstBg = [[[WILDBackground alloc] initForStack: self] autorelease];
		mBackgrounds = [[NSMutableArray alloc] initWithObjects: firstBg, nil];
		WILDCard*			firstCard = [[[WILDCard alloc] initForStack: self] autorelease];
		[firstCard setOwningBackground: firstBg];
		
		mCards = [[NSMutableArray alloc] initWithObjects: firstCard, nil];
	}
	
	return self;
}


-(id)	initWithXMLDocument: (NSXMLDocument*)theDoc document: (WILDDocument*)theDocument
{
	if(( self = [super init] ))
	{
		NSXMLElement*	elem = [theDoc rootElement];
		
		mUserLevel = WILDIntegerFromSubElementInElement( @"userLevel", elem );
		
		mCantModify = WILDBoolFromSubElementInElement( @"cantModify", elem );
		mCantDelete = WILDBoolFromSubElementInElement( @"cantDelete", elem );
		mPrivateAccess = WILDBoolFromSubElementInElement( @"privateAccess", elem );
		mCantAbort = WILDBoolFromSubElementInElement( @"cantAbort", elem );
		mCantPeek = WILDBoolFromSubElementInElement( @"cantPeek", elem );
		
//		mCreatedByVersion = [WILDStringFromSubElementInElement( @"createdByVersion", elem ) retain];
//		mLastCompactedVersion = [WILDStringFromSubElementInElement( @"lastCompactedVersion", elem ) retain];
//		mFirstEditedVersion = [WILDStringFromSubElementInElement( @"firstEditedVersion", elem ) retain];
//		mLastEditedVersion = [WILDStringFromSubElementInElement( @"lastEditedVersion", elem ) retain];
		
		mCardSize = WILDSizeFromSubElementInElement( @"cardSize", elem );
		
		mScript = [WILDStringFromSubElementInElement( @"script", elem ) retain];
		
		mDocument = theDocument;
		
		mCards = [[NSMutableArray alloc] init];
		mBackgrounds = [[NSMutableArray alloc] init];

		// Load backgrounds:
		NSArray			*	backgrounds = [elem elementsForName: @"background"];
		for( NSXMLElement* theBgElem in backgrounds )
		{
			NSXMLNode*				theFileAttrNode = [theBgElem attributeForName: @"file"];
			NSString*				theFileAttr = [theFileAttrNode stringValue];
			NSURL*					theFileAttrURL = [[mDocument fileURL] URLByAppendingPathComponent: theFileAttr];
			NSXMLDocument*			bgDoc = [[NSXMLDocument alloc] initWithContentsOfURL: theFileAttrURL options: 0
																error: nil];
			WILDBackground*	theBg = [[WILDBackground alloc] initWithXMLDocument: bgDoc forStack: self];
			
			[self addBackground: theBg];
			
			[bgDoc release];
			[theBg release];
		}

		// Load cards:
		NSArray			*	cards = [elem elementsForName: @"card"];
		for( NSXMLElement* theCdElem in cards )
		{
			NSXMLNode*				theFileAttrNode = [theCdElem attributeForName: @"file"];
			NSString*				theFileAttr = [theFileAttrNode stringValue];
			NSURL*					theFileAttrURL = [[mDocument fileURL] URLByAppendingPathComponent: theFileAttr];
			NSXMLDocument*			cdDoc = [[NSXMLDocument alloc] initWithContentsOfURL: theFileAttrURL options: 0
																error: nil];
			WILDBackground*	theCd = [[WILDCard alloc] initWithXMLDocument: cdDoc forStack: self];
			
			[self addCard: theCd];
			
			[cdDoc release];
			[theCd release];
		}
	}
	
	return self;
}


-(void)	dealloc
{
	DESTROY(mBackgrounds);
	DESTROY(mCards);
//	DESTROY(mCreatedByVersion);
//	DESTROY(mLastCompactedVersion);
//	DESTROY(mFirstEditedVersion);
//	DESTROY(mLastEditedVersion);
	DESTROY(mScript);
	
	[super dealloc];
}


-(void)	addCard: (WILDCard*)theCard
{
	[mCards addObject: theCard];
}


-(void)	addBackground: (WILDBackground*)theBg
{
	[mBackgrounds addObject: theBg];
}


-(NSArray*)	cards
{
	return mCards;
}


-(void)	setCards: (NSArray*)theCards
{
	ASSIGNMUTABLECOPY(mCards,theCards);
}


-(WILDCard*)	cardWithID: (NSInteger)theID
{
	for( WILDCard* theCd in mCards )
	{
		if( [theCd cardID] == theID )
			return theCd;
	}
	
	return nil;
}


-(NSInteger)	uniqueIDForCardOrBackground
{
	NSInteger	cardID = UKRandomInteger();
	BOOL		notUnique = YES;
	
	while( notUnique )
	{
		notUnique = NO;
		
		for( WILDCard* currCard in mCards )
		{
			if( [currCard cardID] == cardID )
			{
				notUnique = YES;
				cardID = UKRandomInteger();
				break;
			}
		}

		if( !notUnique )
		{
			for( WILDBackground* currBkgd in mBackgrounds )
			{
				if( [currBkgd backgroundID] == cardID )
				{
					notUnique = YES;
					cardID = UKRandomInteger();
					break;
				}
			}
		}
	}
	
	return cardID;
}


-(void)	setBackgrounds: (NSArray*)theBkgds
{
	ASSIGNMUTABLECOPY(mBackgrounds,theBkgds);
}


-(WILDBackground*)	backgroundWithID: (NSInteger)theID
{
	for( WILDBackground* theBg in mBackgrounds )
	{
		if( [theBg backgroundID] == theID )
			return theBg;
	}
	
	return nil;
}


-(NSSize)	cardSize
{
	return mCardSize;
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ {\ncardSize = %@\nbackgrounds = %@\ncards = %@\nscript = %@\n}", [self class], NSStringFromSize(mCardSize), mBackgrounds, mCards, mScript];
}


-(NSString*)	script
{
	return mScript;
}


-(void)	setScript: (NSString*)theScript
{
	ASSIGN(mScript,theScript);
}


-(NSString*)	displayName
{
	return [NSString stringWithFormat: @"Stack “%@”", [[[mDocument fileURL] lastPathComponent] stringByDeletingPathExtension]];
}


-(NSImage*)	displayIcon
{
	return [[NSWorkspace sharedWorkspace] iconForFileType: @"xstk"];
}


-(BOOL)	searchForPattern: (NSString*)inPattern withContext: (WILDSearchContext*)inContext
			flags: (WILDSearchFlags)inFlags
{
	WILDCard*	cardToSearch = inContext.currentCard;
	if( !cardToSearch )
		cardToSearch = inContext.startCard;
	BOOL		foundSomething = NO;
	
	while( YES )
	{
		//NSLog( @"===== Searching %@ =====", [cardToSearch displayName] );
		
		foundSomething = [cardToSearch searchForPattern: inPattern withContext: inContext flags: inFlags];
		if( foundSomething )
		{
			//NSLog( @"Found something in %@", [cardToSearch displayName] );
			break;	// Yaay! we're done!
		}
		
		// Nothing found on this card? Try next card:
		NSInteger	currCardIdx = [mCards indexOfObject: cardToSearch];
		if( inFlags & WILDSearchBackwards )
		{
			currCardIdx -= 1;
			if( currCardIdx < 0 )
				currCardIdx = [mCards count] -1;
		}
		else
		{
			currCardIdx += 1;
			if( currCardIdx >= [mCards count] )
				currCardIdx = 0;
		}
		
		cardToSearch = [mCards objectAtIndex: currCardIdx];
		if( cardToSearch == inContext.startCard )	// Back at first card we searched? Nothing more to search through, exit!
		{
			//NSLog( @"End of search, back at %@", [cardToSearch displayName] );
			break;
		}
	}
	
	return foundSomething;
}


-(WILDDocument*)	document
{
	return mDocument;
}


+(NSColor*)		peekOutlineColor
{
	return [NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_22.pbm"]];
}

@end
