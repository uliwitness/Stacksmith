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
#import "Forge.h"
#import <QTKit/QTKit.h>


@implementation WILDStack

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
		
		mScript = [@"" retain];
		
		mCardIDSeed = 3000;
		
		WILDBackground*		firstBg = [[[WILDBackground alloc] initForStack: self] autorelease];
		mBackgrounds = [[NSMutableArray alloc] initWithObjects: firstBg, nil];
		WILDCard*			firstCard = [[[WILDCard alloc] initForStack: self] autorelease];
		[firstCard setOwningBackground: firstBg];
		[firstBg addCard: firstCard];
		
		mCards = [[NSMutableArray alloc] initWithObjects: firstCard, nil];
		mMarkedCards = [[NSMutableSet alloc] init];
		
		mName = [@"Untitled" retain];
		
		mIDForScripts = kLEOObjectIDINVALID;
	}
	
	return self;
}


-(id)	initWithXMLDocument: (NSXMLDocument*)theDoc document: (WILDDocument*)theDocument
{
	if(( self = [super init] ))
	{
		NSXMLElement*	elem = [theDoc rootElement];
		
		mID = WILDIntegerFromSubElementInElement( @"id", elem );
		mName = [WILDStringFromSubElementInElement( @"name", elem ) retain];
		if( !mName )
			mName = [@"Untitled" retain];
		
		mUserLevel = WILDIntegerFromSubElementInElement( @"userLevel", elem );
		
		mCantModify = WILDBoolFromSubElementInElement( @"cantModify", elem, NO );
		mCantDelete = WILDBoolFromSubElementInElement( @"cantDelete", elem, NO );
		mPrivateAccess = WILDBoolFromSubElementInElement( @"privateAccess", elem, NO );
		mCantAbort = WILDBoolFromSubElementInElement( @"cantAbort", elem, NO );
		mCantPeek = WILDBoolFromSubElementInElement( @"cantPeek", elem, NO );
		
		mCardSize = WILDSizeFromSubElementInElement( @"cardSize", elem );
		if( mCardSize.width < 1 || mCardSize.height < 1 )
			mCardSize = NSMakeSize(512,342);
		
		mScript = [WILDStringFromSubElementInElement( @"script", elem ) retain];
		
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
					NSLog(@"Could not load background: %@", theError);
				WILDBackground*	theBg = [[WILDBackground alloc] initWithXMLDocument: bgDoc forStack: self];
				
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
																	error: nil];
				if( !cdDoc && theError )
					NSLog(@"Could not load background: %@", theError);
				WILDLayer*	theCd = [[WILDCard alloc] initWithXMLDocument: cdDoc forStack: self];
				[self addCard: theCd];
				[self setMarked: isMarked forCard: theCd];
				
				[cdDoc release];
				[theCd release];
			}
		}
		
		mCardIDSeed = 3000;
		
		mIDForScripts = kLEOObjectIDINVALID;
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
	DESTROY_DEALLOC(mScript);
	DESTROY_DEALLOC(mName);
	
	if( mScriptObject )
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
	
	[super dealloc];
}


-(void)	addCard: (WILDCard*)theCard
{
	[mCards addObject: theCard];
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
	[inCard setMarked: isMarked];
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


-(NSSize)	cardSize
{
	return mCardSize;
}


-(void)	setCardSize: (NSSize)inSize
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDStackWillChangeNotification object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"cardSize", WILDAffectedPropertyKey, nil]];
	mCardSize = inSize;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDStackDidChangeNotification object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"cardSize", WILDAffectedPropertyKey, nil]];
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
	if( mScriptObject )
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
}


-(struct LEOScript*)	scriptObjectShowingErrorMessage: (BOOL)showError
{
	if( !mScriptObject )
	{
		const char*		scriptStr = [mScript UTF8String];
		LEOParseTree*	parseTree = LEOParseTreeCreateFromUTF8Characters( scriptStr, strlen(scriptStr), [[self displayName] UTF8String] );
		if( LEOParserGetLastErrorMessage() == NULL )
		{
			if( mIDForScripts == kLEOObjectIDINVALID )
			{
				LEOInitWILDObjectValue( &mValueForScripts, self, kLEOInvalidateReferences, NULL );
				mIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( [[self document] contextGroup], &mValueForScripts );
				mSeedForScripts = LEOContextGroupGetSeedForObjectID( [[self document] contextGroup], mIDForScripts );
			}
			mScriptObject = LEOScriptCreateForOwner( mIDForScripts, mSeedForScripts, LEOForgeScriptGetParentScript );
			LEOScriptCompileAndAddParseTree( mScriptObject, [[self document] contextGroup], parseTree );
			
			#if REMOTE_DEBUGGER
			LEORemoteDebuggerAddFile( [[self displayName] UTF8String], scriptStr, mScriptObject );
			
			// Set a breakpoint on the mouseUp handler:
			LEOHandlerID handlerName = LEOContextGroupHandlerIDForHandlerName( [[self document] contextGroup], "mouseup" );
			LEOHandler* theHandler = LEOScriptFindCommandHandlerWithID( mScriptObject, handlerName );
			if( theHandler )
				LEORemoteDebuggerAddBreakpoint( theHandler->instructions );
			#endif
		}
		if( LEOParserGetLastErrorMessage() )
		{
			if( showError )
				NSRunAlertPanel( @"Script Error", @"%@", @"OK", @"", @"", [NSString stringWithCString: LEOParserGetLastErrorMessage() encoding: NSUTF8StringEncoding] );
			if( mScriptObject )
			{
				LEOScriptRelease( mScriptObject );
				mScriptObject = NULL;
			}
		}
	}
	
	return mScriptObject;
}


-(id<WILDObject>)	parentObject
{
	return nil;
}


-(struct LEOContextGroup*)	scriptContextGroupObject
{
	return [[self document] contextGroup];
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
	
	[theString appendFormat: @"\t<id>%ld</id>\n", mID];
	[theString appendFormat: @"\t<name>%l@</name>\n", WILDStringEscapedForXML(mName)];
	
	[theString appendFormat: @"\t<userLevel>%d</userLevel>\n", mUserLevel];
	[theString appendFormat: @"\t<cantModify>%@</cantModify>\n", mCantModify ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<cantDelete>%@</cantDelete>\n", mCantDelete ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<privateAccess>%@</privateAccess>\n", mPrivateAccess ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<cantAbort>%@</cantAbort>\n", mCantAbort ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<cantPeek>%@</cantPeek>\n", mCantPeek ? @"<true />" : @"<false />"];

	[theString appendFormat: @"\t<cardSize>\n\t\t<width>%d</width>\n\t\t<height>%d</height>\n\t</cardSize>\n", (int)mCardSize.width, (int)mCardSize.height];
	[theString appendFormat: @"\t<script>%@</script>\n", WILDStringEscapedForXML(mScript)];
	
	// Write out backgrounds and add entries for them:
	for( WILDBackground * currBg in mBackgrounds )
	{
		NSString*	bgFileName = [NSString stringWithFormat: @"background_%ld.xml", [currBg backgroundID]];
		NSURL	*	bgURL = [packageURL URLByAppendingPathComponent: bgFileName];
		if( ![[currBg xmlStringForWritingToURL: packageURL forSaveOperation: saveOperation originalContentsURL: absoluteOriginalContentsURL error: outError] writeToURL: bgURL atomically: YES encoding: NSUTF8StringEncoding error: outError] )
			return nil;
		[theString appendFormat: @"\t<background id=\"%ld\" file=\"%@\" />\n", [currBg backgroundID], WILDStringEscapedForXML(bgFileName)];
	}
	
	// Write out cards and add entries for them:
	for( WILDCard * currCd in mCards )
	{
		NSString*	cdFileName = [NSString stringWithFormat: @"card_%ld.xml", [currCd cardID]];
		NSURL	*	cdURL = [packageURL URLByAppendingPathComponent: cdFileName];
		if( ![[currCd xmlStringForWritingToURL: packageURL forSaveOperation: saveOperation originalContentsURL: absoluteOriginalContentsURL error: outError] writeToURL: cdURL atomically: YES encoding: NSUTF8StringEncoding error: outError] )
			return nil;
		[theString appendFormat: @"\t<card id=\"%ld\" file=\"%@\" marked=\"%@\" />\n",
							[currCd cardID], WILDStringEscapedForXML(cdFileName),
		 					([mMarkedCards containsObject: currCd] ? @"true" : @"false")];
	}
	
	[theString appendString: @"</stack>\n"];
	
	return theString;
}


-(void)	updateChangeCount: (NSDocumentChangeType)inChange
{
	[mDocument updateChangeCount: inChange];
}


-(NSString*)	name
{
	NSString	*stackName = [[[mDocument fileName] lastPathComponent] stringByDeletingPathExtension];
	if( stackName == nil )
		stackName = mName;
	return stackName;
}


-(void)		setName: (NSString*)inName
{
	if( ![inName hasSuffix: @".xstk"] )	// TODO: Get suffix from Info.plist for standalones.
		inName = [inName stringByAppendingPathExtension: @"xstk"];
	if( [mDocument fileName] == nil )
	{
		ASSIGN(mName,[inName lastPathComponent]);
	}
	else
	{
		[mDocument setFileName: [[[mDocument fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent: inName]];
	}
}


-(NSString*)	textContents
{
	return nil;
}


-(BOOL)	setTextContents: (NSString*)inString
{
	return NO;
}

-(BOOL)	goThereInNewWindow: (BOOL)inNewWindow
{
	if( [[mDocument windowControllers] count] == 0 )
		[mDocument makeWindowControllers];
	[[[mDocument windowControllers] objectAtIndex: 0] showWindow: self];	// TODO: Look up the right window for this stack.
	return YES;
}


-(id)	valueForWILDPropertyNamed: (NSString*)inPropertyName
{
	if( [inPropertyName isEqualToString: @"short name"] || [inPropertyName isEqualToString: @"name"] )
	{
		return [self name];
	}
	else
		return nil;
}


-(BOOL)		setValue: (id)inValue forWILDPropertyNamed: (NSString*)inPropertyName
{
	BOOL	propExists = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDStackWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: inPropertyName
															forKey: WILDAffectedPropertyKey]];
	if( [inPropertyName isEqualToString: @"short name"] || [inPropertyName isEqualToString: @"name"] )
		[self setName: inValue];
	else
		propExists = NO;

	[[NSNotificationCenter defaultCenter] postNotificationName: WILDStackDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: inPropertyName
															forKey: WILDAffectedPropertyKey]];
	if( propExists )
		[self updateChangeCount: NSChangeDone];
	
	return propExists;
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
