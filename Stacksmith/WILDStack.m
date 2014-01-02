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
#import "WILDRecentCardsList.h"
#import "WILDNotifications.h"
#import <QTKit/QTKit.h>
#import "UKHelperMacros.h"
#import "WILDDocument.h"


NSString		*		WILDErrorDomain = @"WILDErrorDomain";



@implementation WILDStack

@synthesize resizable = mResizable;

-(id)	initWithDocument: (WILDDocument*)theDocument
{
	if(( self = [super init] ))
	{
		mID = [theDocument uniqueIDForStack];
		
		mUserLevel = 5;
		
		mCantModify = NO;
		mCantDelete = NO;
		mPrivateAccess = NO;
		mCantAbort = NO;
		mCantPeek = NO;
		
		mDocument = theDocument;
		
		mCardSize = NSMakeSize( 512, 342 );
		
		ASSIGN(mScript,@"");
		
		mCardIDSeed = 3000;
		
		WILDBackground*		firstBg = [[[WILDBackground alloc] initForStack: self] autorelease];
		mBackgrounds = [[NSMutableArray alloc] initWithObjects: firstBg, nil];
		WILDCard*			firstCard = [[[WILDCard alloc] initForStack: self] autorelease];
		[firstCard setOwningBackground: firstBg];
		[firstBg addCard: firstCard];
		
		mCards = [[NSMutableArray alloc] initWithObjects: firstCard, nil];
		mMarkedCards = [[NSMutableSet alloc] init];
		
		mName = [@"Untitled" retain];
	}
	
	return self;
}


-(id)	initWithXMLDocument: (NSXMLDocument*)theDoc document: (WILDDocument*)theDocument error: (NSError**)outError
{
	if(( self = [super init] ))
	{
		NSXMLElement*	elem = [theDoc rootElement];
		
		mID = WILDIntegerFromSubElementInElement( @"id", elem );
		mName = [WILDStringFromSubElementInElement( @"name", elem ) retain];
		if( !mName )
			mName = [@"Untitled" retain];
		
		mUserLevel = WILDIntFromSubElementInElement( @"userLevel", elem );
		
		mCantModify = WILDBoolFromSubElementInElement( @"cantModify", elem, NO );
		mCantDelete = WILDBoolFromSubElementInElement( @"cantDelete", elem, NO );
		mPrivateAccess = WILDBoolFromSubElementInElement( @"privateAccess", elem, NO );
		mCantAbort = WILDBoolFromSubElementInElement( @"cantAbort", elem, NO );
		mCantPeek = WILDBoolFromSubElementInElement( @"cantPeek", elem, NO );
		mResizable = WILDBoolFromSubElementInElement( @"resizable", elem, NO );
		
		mCardSize = WILDSizeFromSubElementInElement( @"cardSize", elem );
		if( mCardSize.width < 1 || mCardSize.height < 1 )
			mCardSize = NSMakeSize(512,342);
		
		ASSIGN(mScript, WILDStringFromSubElementInElement( @"script", elem ));

		NSError *	err = nil;
		NSArray	*	userPropsNodes = [elem nodesForXPath: @"userProperties" error: &err];
		if( userPropsNodes.count > 0 )
		{
			NSString		*	lastKey = nil;
			NSString		*	lastValue = nil;
			NSXMLElement	*	userPropsNode = [userPropsNodes objectAtIndex: 0];
			for( NSXMLElement* currChild in userPropsNode.children )
			{
				if( [currChild.name isEqualToString: @"name"] )
					lastKey = currChild.stringValue;
				if( !lastValue && [currChild.name isEqualToString: @"value"] )
					lastValue = currChild.stringValue;
				if( lastKey && lastValue )
				{
					if( !mUserProperties )
						mUserProperties = [[NSMutableDictionary alloc] init];
					[mUserProperties setObject: lastValue forKey: lastKey];
					lastValue = lastKey = nil;
				}
				if( lastValue && !lastKey )
					lastValue = nil;
			}
		}
		
		mDocument = theDocument;
		
		mBackgrounds = [[NSMutableArray alloc] init];
		mCards = [[NSMutableArray alloc] init];
		mMarkedCards = [[NSMutableSet alloc] init];

		// Load backgrounds:
		NSArray			*	backgrounds = [elem elementsForName: @"background"];
		for( NSXMLElement* theBgElem in backgrounds )
		{
			NSXMLNode*				theFileAttrNode = [theBgElem attributeForName: @"file"];
			NSString*				theFileAttr = [theFileAttrNode stringValue];
			NSURL*					theFileAttrURL = [[mDocument fileURL] URLByAppendingPathComponent: theFileAttr];
			if( theFileAttrURL != nil )
			{
				NSError*				theError = nil;
				NSXMLDocument*			bgDoc = [[NSXMLDocument alloc] initWithContentsOfURL: theFileAttrURL options: 0
																	error: &theError];
				if( !bgDoc && theError )
				{
					if( outError )
					{
						*outError = [NSError errorWithDomain: WILDErrorDomain code: WILDErrorInvalidXMLOnBackground userInfo: @{ NSLocalizedDescriptionKey: [NSString stringWithFormat: @"Could not load background: %@", theError], NSUnderlyingErrorKey: theError }];
					}
					[self autorelease];
					return nil;
				}
				WILDBackground*	theBg = [[WILDBackground alloc] initWithXMLDocument: bgDoc forStack: self error: outError];
				
				[self addBackground: theBg];
				
				[bgDoc release];
				[theBg release];
			}
		}

		// Load cards:
		NSArray			*	cards = [elem elementsForName: @"card"];
		for( NSXMLElement* theCdElem in cards )
		{
			NSXMLNode*				theFileAttrNode = [theCdElem attributeForName: @"file"];
			NSXMLNode*				theMarkedAttrNode = [theCdElem attributeForName: @"marked"];
			BOOL					isMarked = [[theMarkedAttrNode stringValue] isEqualToString: @"true"];
			NSString*				theFileAttr = [theFileAttrNode stringValue];
			NSURL*					theFileAttrURL = [[mDocument fileURL] URLByAppendingPathComponent: theFileAttr];
			if( theFileAttrURL )
			{
				NSError*				theError = nil;
				NSXMLDocument*			cdDoc = [[NSXMLDocument alloc] initWithContentsOfURL: theFileAttrURL options: 0
																	error: &theError];
				if( !cdDoc && theError )
				{
					if( outError )
					{
						*outError = [NSError errorWithDomain: WILDErrorDomain code: WILDErrorInvalidXMLOnCard userInfo: @{ NSLocalizedDescriptionKey: [NSString stringWithFormat: @"Could not load card: %@", theError], NSUnderlyingErrorKey: theError }];
					}
					[self autorelease];
					return nil;
				}
				WILDCard*	theCd = [[WILDCard alloc] initWithXMLDocument: cdDoc forStack: self error: outError];
				[self addCard: theCd];
				[theCd setMarked: isMarked];	// Eventually calls setMarked:forCard: on us.
				
				[cdDoc release];
				[theCd release];
			}
		}
		
		mCardIDSeed = 3000;
	}
	
	return self;
}


-(void)	dealloc
{
	for( WILDCard * currCard in mCards )
	{
		[[WILDRecentCardsList sharedRecentCardsList] removeCard: currCard];
	}

	DESTROY_DEALLOC(mBackgrounds);
	DESTROY_DEALLOC(mCards);
	DESTROY_DEALLOC(mMarkedCards);
	
	[super dealloc];
}


PROPERTY_MAP_START
PROPERTY_MAPPING(name,"name",kLeoValueTypeString)
PROPERTY_MAPPING(name,"short name",kLeoValueTypeString)
PROPERTY_MAPPING(script,"script",kLeoValueTypeString)
PROPERTY_MAPPING(stackID,"id",kLeoValueTypeInteger)
PROPERTY_MAPPING(sizeDictionary,"size",kLeoValueTypeArray)
PROPERTY_MAPPING(resizable,"resizable",kLeoValueTypeBoolean)
PROPERTY_MAP_END


-(void)	addCard: (WILDCard*)theCard
{
	[mCards addObject: theCard];
	if( [theCard marked] )
		[self setMarked: YES forCard: theCard];
}


-(void)	insertCard: (WILDCard*)theCard atIndex: (NSUInteger)desiredIndex
{
	[mCards insertObject: theCard atIndex: desiredIndex];
	if( [theCard marked] )
		[self setMarked: YES forCard: theCard];
}


-(void)	removeCard: (WILDCard*)theCard
{
	[mCards removeObject: theCard];
	[mMarkedCards removeObject: theCard];
}


-(void)	setMarked: (BOOL)isMarked forCard: (WILDCard*)inCard
{
	if( isMarked )
		[mMarkedCards addObject: inCard];
	else
		[mMarkedCards removeObject: inCard];
}


-(void)	addBackground: (WILDBackground*)theBg
{
	[mBackgrounds addObject: theBg];
}


-(void)	removeBackground: (WILDBackground*)theBg
{
	[mBackgrounds removeObject: theBg];
}

-(NSArray*)	cards
{
	return mCards;
}


-(WILDCard*)	cardWithID: (WILDObjectID)theID
{
	for( WILDCard* theCd in mCards )
	{
		if( [theCd cardID] == theID )
			return theCd;
	}
	
	return nil;
}


-(WILDCard*)	cardNamed: (NSString*)cardName
{
	for( WILDCard* theCd in mCards )
	{
		if( [[theCd name] caseInsensitiveCompare: cardName] == NSOrderedSame )
			return theCd;
	}
	
	return nil;
}


-(WILDObjectID)	uniqueIDForCardOrBackground
{
	BOOL			notUnique = YES;
	
	while( notUnique )
	{
		notUnique = NO;
		
		for( WILDCard* currCard in mCards )
		{
			if( [currCard cardID] == mCardIDSeed )
			{
				notUnique = YES;
				mCardIDSeed++;
				break;
			}
		}

		if( !notUnique )
		{
			for( WILDBackground* currBkgd in mBackgrounds )
			{
				if( [currBkgd backgroundID] == mCardIDSeed )
				{
					notUnique = YES;
					mCardIDSeed++;
					break;
				}
			}
		}
	}
	
	return mCardIDSeed;
}


-(NSArray*)	backgrounds
{
	return mBackgrounds;
}


-(WILDBackground*)	backgroundWithID: (WILDObjectID)theID
{
	for( WILDBackground* theBg in mBackgrounds )
	{
		if( [theBg backgroundID] == theID )
			return theBg;
	}
	
	return nil;
}


-(WILDBackground*)	backgroundNamed: (NSString*)cardName
{
	for( WILDBackground* theCd in mBackgrounds )
	{
		if( [[theCd name] caseInsensitiveCompare: cardName] == NSOrderedSame )
			return theCd;
	}
	
	return nil;
}


-(NSDictionary*)	sizeDictionary
{
	return @{ @"width": @(mCardSize.width), @"height": @(mCardSize.height) };
}


-(void)	setSizeDictionary: (NSDictionary*)inDict
{
	mCardSize.width = [inDict[@"width"] integerValue];
	mCardSize.height = [inDict[@"height"] integerValue];
}


-(NSSize)	cardSize
{
	return mCardSize;
}


-(void)	setCardSize: (NSSize)inSize
{
	mCardSize = inSize;
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ {\ncardSize = %@\nbackgrounds = %@\ncards = %@\nscript = %@\n}", [self class], NSStringFromSize(mCardSize), mBackgrounds, mCards, mScript];
}


-(NSString*)	displayName
{
	return [NSString stringWithFormat: @"Stack “%@”", [self name]];
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
		NSUInteger	currCardIdx = [mCards indexOfObject: cardToSearch];
		if( inFlags & WILDSearchBackwards )
		{
			if( currCardIdx == 0 )
				currCardIdx = [mCards count] -1;
			else
				currCardIdx -= 1;
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


-(WILDObjectID)	stackID
{
	return mID;
}


-(NSString*)	xmlStringForWritingToURL: (NSURL*)packageURL forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error: (NSError**)outError
{
	NSMutableString	*	theString = [NSMutableString stringWithString:
											@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
												"<!DOCTYPE stack PUBLIC \"-//Apple, Inc.//DTD stack V 2.0//EN\" \"\" >\n"
												"<stack>\n"];
	
	[theString appendFormat: @"\t<id>%lld</id>\n", mID];
	NSString	*binaryAttribute = @"";
	NSString	*escapedName = WILDStringEscapedForXML( mName, &binaryAttribute );
	[theString appendFormat: @"\t<name%@>%@</name>\n", binaryAttribute, escapedName];
	
	[theString appendFormat: @"\t<userLevel>%d</userLevel>\n", mUserLevel];
	[theString appendFormat: @"\t<cantModify>%@</cantModify>\n", mCantModify ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<cantDelete>%@</cantDelete>\n", mCantDelete ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<privateAccess>%@</privateAccess>\n", mPrivateAccess ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<cantAbort>%@</cantAbort>\n", mCantAbort ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<cantPeek>%@</cantPeek>\n", mCantPeek ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<resizable>%@</resizable>\n", mResizable ? @"<true />" : @"<false />"];

	[theString appendFormat: @"\t<cardSize>\n\t\t<width>%d</width>\n\t\t<height>%d</height>\n\t</cardSize>\n", (int)mCardSize.width, (int)mCardSize.height];
	binaryAttribute = @"";
	NSString	*escapedScript = WILDStringEscapedForXML( mScript, &binaryAttribute );
	[theString appendFormat: @"\t<script%@>%@</script>\n", binaryAttribute, escapedScript];
	
	[theString appendString: @"\t<userProperties>\n"];
	for( NSString *userPropName in [[mUserProperties allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)] )
	{
		WILDAppendStringXML( theString, 2, userPropName, @"name" );
		WILDAppendStringXML( theString, 2, mUserProperties[userPropName], @"value" );
	}
	[theString appendString: @"\t</userProperties>\n"];
	
	// Write out backgrounds and add entries for them:
	for( WILDBackground * currBg in mBackgrounds )
	{
		NSString*	bgFileName = [NSString stringWithFormat: @"background_%lld.xml", [currBg backgroundID]];
		NSURL	*	bgURL = [packageURL URLByAppendingPathComponent: bgFileName];
		if( ![[currBg xmlStringForWritingToURL: packageURL forSaveOperation: saveOperation originalContentsURL: absoluteOriginalContentsURL error: outError] writeToURL: bgURL atomically: YES encoding: NSUTF8StringEncoding error: outError] )
			return nil;
		[theString appendFormat: @"\t<background id=\"%lld\" file=\"%@\" name=\"%@\" />\n", [currBg backgroundID], WILDStringEscapedForXMLAttribute(bgFileName), WILDStringEscapedForXMLAttribute(currBg.name)];
	}
	
	// Write out cards and add entries for them:
	for( WILDCard * currCd in mCards )
	{
		NSString*	cdFileName = [NSString stringWithFormat: @"card_%lld.xml", [currCd cardID]];
		NSURL	*	cdURL = [packageURL URLByAppendingPathComponent: cdFileName];
		if( ![[currCd xmlStringForWritingToURL: packageURL forSaveOperation: saveOperation originalContentsURL: absoluteOriginalContentsURL error: outError] writeToURL: cdURL atomically: YES encoding: NSUTF8StringEncoding error: outError] )
			return nil;
		[theString appendFormat: @"\t<card id=\"%lld\" file=\"%@\" name=\"%@\" marked=\"%@\" />\n",
							[currCd cardID], WILDStringEscapedForXMLAttribute(cdFileName), WILDStringEscapedForXMLAttribute(currCd.name),
		 					([mMarkedCards containsObject: currCd] ? @"true" : @"false")];
	}
	
	[theString appendString: @"</stack>\n"];
	
	return theString;
}


-(NSString*)	name
{
	NSString	*stackName = [[[mDocument fileURL] lastPathComponent] stringByDeletingPathExtension];
	if( stackName == nil )
		stackName = mName;
	return stackName;
}


-(void)		setName: (NSString*)inName
{
	if( ![inName hasSuffix: @".xstk"] )	// TODO: Get suffix from Info.plist for standalones.
		inName = [inName stringByAppendingPathExtension: @"xstk"];
	if( [mDocument fileURL] == nil )
	{
		ASSIGN(mName,[inName lastPathComponent]);
	}
	else
	{
		[mDocument setFileURL: [[[mDocument fileURL] URLByDeletingLastPathComponent] URLByAppendingPathComponent: inName]];
	}
}


-(BOOL)	goThereInNewWindow: (BOOL)inNewWindow
{
	if( [[mDocument windowControllers] count] == 0 )
		[mDocument makeWindowControllers];
	[[[mDocument windowControllers] objectAtIndex: 0] showWindow: self];	// TODO: Look up the right window for this stack.
	return YES;
}


-(NSString*)	propertyWillChangeNotificationName
{
	return WILDStackWillChangeNotification;
}


-(NSString*)	propertyDidChangeNotificationName
{
	return WILDStackDidChangeNotification;
}


-(WILDStack*)	stack
{
	return self;
}


-(WILDCard*)	currentCard
{
	WILDDocument	*	theDoc = [self document];
	if( [[theDoc windowControllers] count] == 0 )
		[theDoc makeWindowControllers];
	return [theDoc currentCard];
}


+(NSColor*)		peekOutlineColor
{
	return [NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_22.pbm"]];
}

@end
