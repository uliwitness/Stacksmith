//
//  WILDLayer.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDLayer.h"
#import "WILDPart.h"
#import "WILDPartContents.h"
#import "WILDXMLUtils.h"
#import "ULIMultiMap.h"
#import "WILDStack.h"
#import "WILDNotifications.h"
#import "UKRandomInteger.h"


@implementation WILDLayer

-(id)	initForStack: (WILDStack*)theStack
{
	if(( self = [super init] ))
	{
		mStack = theStack;
		
		mID = [mStack uniqueIDForCardOrBackground];
		mName = [@"" retain];

		mShowPict = YES;
		mCantDelete = NO;
		mDontSearch = NO;
		
		mScript = [@"" retain];
		mButtonFamilies = [[ULIMultiMap alloc] init];

		mParts = [[NSMutableArray alloc] init];
		mAddColorParts = [[NSMutableArray alloc] init];
		mContents = [[NSMutableDictionary alloc] init];
		
		mPartIDSeed = 1;
	}
	
	return self;
}


-(id)	initWithXMLDocument: (NSXMLDocument*)theDoc forStack: (WILDStack*)theStack
{
	if(( self = [super init] ))
	{
		NSXMLElement*	elem = [theDoc rootElement];
		
		mID = WILDIntegerFromSubElementInElement( @"id", elem );
		mName = [WILDStringFromSubElementInElement( @"name", elem ) retain];
		
		mShowPict = WILDBoolFromSubElementInElement( @"showPict", elem );
		mCantDelete = WILDBoolFromSubElementInElement( @"cantDelete", elem );
		mDontSearch = WILDBoolFromSubElementInElement( @"dontSearch", elem );
		
		mStack = theStack;
		mPicture = [WILDStringFromSubElementInElement( @"bitmap", elem ) retain];
		
		mScript = [WILDStringFromSubElementInElement( @"script", elem ) retain];
		mButtonFamilies = [[ULIMultiMap alloc] init];
		
		NSArray*		parts = [elem elementsForName: @"part"];
		mParts = [[NSMutableArray alloc] initWithCapacity: [parts count]];
		for( NSXMLElement* currPart in parts )
		{
			WILDPart*	newPart = [[[WILDPart alloc] initWithXMLElement: currPart forStack: theStack] autorelease];
			[newPart setPartLayer: [self partLayer]];
			[newPart setPartOwner: self];
			[mParts addObject: newPart];
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partDidChange:) name:WILDPartDidChangeNotification object: newPart];
			if( [newPart family] > 0 )
				[mButtonFamilies addObject: newPart forKey: [NSNumber numberWithInteger: [newPart family]]];
		}
		
		mAddColorParts = [[NSMutableArray alloc] init];
		NSArray*		contents = [elem elementsForName: @"content"];
		mContents = [[NSMutableDictionary alloc] initWithCapacity: [contents count]];
		for( NSXMLElement* currContent in contents )
		{
			WILDPartContents*	newCont = [[[WILDPartContents alloc] initWithXMLElement: currContent forStack: theStack] autorelease];
			NSString*					theKey = [NSString stringWithFormat: @"%@:%ld", [newCont partLayer], [newCont partID]];
			[mContents setObject: newCont forKey: theKey];
		}
		
		[self loadAddColorObjects: elem];
		
		mPartIDSeed = 1;
	}
	
	return self;
}


-(void)	dealloc
{
	for( WILDPart* currPart in mParts )
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self name: WILDPartDidChangeNotification object: currPart];
	}
	
	DESTROY(mButtonFamilies);
	DESTROY(mName);
	DESTROY(mScript);
	DESTROY(mPicture);
	DESTROY(mParts);
	DESTROY(mAddColorParts);
	
	mStack = nil;
	
	[super dealloc];
}


-(WILDObjectID)	backgroundID
{
	return mID;
}


-(NSImage*)		picture
{
	if( !mPicture )
		return nil;
	
	if( [mPicture isKindOfClass: [NSImage class]] )
		return mPicture;
	
	NSImage*	img = [[mStack document] imageNamed: (NSString*)mPicture];
	ASSIGN(mPicture,img);
	
	return img;
}


-(NSArray*)	parts
{
	return mParts;
}


-(NSArray*)	addColorParts
{
	return mAddColorParts;
}

-(WILDPartContents*)	contentsForPart: (WILDPart*)thePart
{
	return [self contentsForPart: thePart create: NO];
}


-(WILDPartContents*)	contentsForPart: (WILDPart*)thePart create: (BOOL)createIfNeeded
{
	NSString*	theKey = [NSString stringWithFormat: @"%@:%ld", [thePart partLayer], [thePart partID]];
	WILDPartContents*	contents = [mContents objectForKey: theKey];
	if( !contents && createIfNeeded )
	{
		contents = [[[WILDPartContents alloc] initWithWILDObjectID: thePart.partID layer: thePart.partLayer] autorelease];
		[mContents setObject: contents forKey: theKey];
	}
	return contents;
}


-(WILDPart*)	partWithID: (WILDObjectID)theID
{
	for( WILDPart* thePart in mParts )
	{
		if( [thePart partID] == theID )
			return thePart;
	}
	
	return nil;
}


-(NSString*)	partLayer
{
	return @"background";
}


-(BOOL)	showPicture
{
	return mShowPict;
}


-(void)	updatePartOnClick: (WILDPart*)thePart withCard: (WILDCard*)inCard background: (WILDBackground*)inBackground
{
	if( [thePart family] == 0 )
	{
		if( [thePart autoHighlight] && ([[thePart style] isEqualToString: @"radiobutton"] || [[thePart style] isEqualToString: @"checkbox"]) )
			[thePart setHighlighted: ![thePart highlighted]];
		return;
	}
	
	NSNumber*	theNum = [NSNumber numberWithInteger: [thePart family]];
	NSArray*	peers = [mButtonFamilies objectsForKey: theNum];
	
	for( WILDPart* currPart in peers )
	{
		BOOL	newState = (currPart == thePart);
		if( [currPart highlighted] != newState
			|| currPart == thePart )	// Whack the clicked part over the head, in case NSButton turned something off we don't wanna, or if it's a non-toggling type of button we need to toggle manually.
		{
			[currPart setHighlighted: newState];
			if( [currPart.partLayer isEqualToString: @"background"] && ![currPart sharedHighlight] )
			{
				[[inCard contentsForPart: currPart create: YES] setHighlighted: newState];
			}
			//NSLog( @"Family: Setting highlight of %@ to %s", [currPart displayName], newState?"true":"false" );
		}
	}
}


-(void)	loadAddColorObjects: (NSXMLElement*)theElem
{
	NSArray*	theObjects = [theElem elementsForName: @"addcolorobject"];
	
	for( NSXMLElement* theObject in theObjects )
	{
		WILDObjectID	objectID = WILDIntegerFromSubElementInElement( @"id", theObject );
		NSInteger		objectBevel = WILDIntegerFromSubElementInElement( @"bevel", theObject );
		NSString*		objectType = WILDStringFromSubElementInElement( @"type", theObject );
		NSString*		objectName = WILDStringFromSubElementInElement( @"name", theObject );
		BOOL			objectTransparent = WILDBoolFromSubElementInElement( @"transparent", theObject );
		BOOL			objectVisible = WILDBoolFromSubElementInElement( @"visible", theObject );
		NSRect			objectRect = WILDRectFromSubElementInElement( @"rect", theObject );
		NSColor*		objectColor = WILDColorFromSubElementInElement( @"color", theObject );
		
		if( [objectType isEqualToString: @"button"] )
		{
			WILDPart*	thePart = [self partWithID: objectID];
			if( thePart )
			{
				[thePart setFillColor: objectColor];
				[thePart setBevel: objectBevel];
				[mAddColorParts addObject: thePart];
			}
		}
		else if( [objectType isEqualToString: @"field"] )
		{
			WILDPart*	thePart = [self partWithID: objectID];
			if( thePart )
			{
				[thePart setFillColor: objectColor];
				[thePart setBevel: objectBevel];
				[mAddColorParts addObject: thePart];
			}
		}
		else if( [objectType isEqualToString: @"rectangle"] )
		{
			WILDPart*	thePart = [[[WILDPart alloc] initWithXMLElement: nil forStack: mStack] autorelease];
			[thePart setFlippedRectangle: objectRect];
			[thePart setFillColor: objectColor];
			[thePart setBevel: objectBevel];
			[thePart setPartType: @"rectangle"];
			[thePart setStyle: @"opaque"];
			[thePart setVisible: objectVisible];
			[mAddColorParts addObject: thePart];
		}
		else if( [objectType isEqualToString: @"picture"] )
		{
			WILDPart*	thePart = [[[WILDPart alloc] initWithXMLElement: nil forStack: mStack] autorelease];
			[thePart setFlippedRectangle: objectRect];
			[thePart setName: objectName];
			[thePart setPartType: @"picture"];
			[thePart setStyle: objectTransparent ? @"transparent" : @"opaque"];
			[thePart setVisible: objectVisible];
			[mAddColorParts addObject: thePart];
		}
	}
}


-(NSURL*)	URLForPartTemplate: (NSString*)inName
{
	return [[NSBundle mainBundle] URLForResource: inName withExtension:@"xml" subdirectory: @"WILDObjectTemplates"];
}


-(void)	createNewButton: (id)sender
{
	[self addNewPartFromXMLTemplate: [self URLForPartTemplate:@"ButtonPartTemplate"]];
}


-(void)	createNewField: (id)sender
{
	[self addNewPartFromXMLTemplate: [self URLForPartTemplate:@"FieldPartTemplate"]];
}


-(WILDObjectID)	uniqueIDForPart
{
	BOOL				notUnique = YES;
	
	while( notUnique )
	{
		notUnique = NO;
		
		for( WILDPart* currPart in mParts )
		{
			if( [currPart partID] == mPartIDSeed )
			{
				notUnique = YES;
				mPartIDSeed++;
				break;
			}
		}
	}
	
	return mPartIDSeed;
}


-(void)	addNewPartFromXMLTemplate: (NSURL*)xmlFile
{
	NSError			*	outError = nil;
	NSXMLDocument	*	templateDocument = [[NSXMLDocument alloc] initWithContentsOfURL: xmlFile options: 0 error: &outError];
	if( !templateDocument && outError )
	{
		UKLog(@"Couldn't load XML template for part: %@",outError);
		return;
	}
	
	NSXMLElement	*	theElement = [templateDocument rootElement];
	WILDPart		*	newPart = [[[WILDPart alloc] initWithXMLElement: theElement forStack: mStack] autorelease];
	
	[newPart setPartID: [self uniqueIDForPart]];
	[newPart setPartLayer: [self partLayer]];
	[newPart setPartOwner: self];
	[mParts addObject: newPart];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partDidChange:) name:WILDPartDidChangeNotification object: newPart];
	
	[self updateChangeCount: NSChangeDone];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerDidAddPartNotification
						object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys: newPart, WILDAffectedPartKey,
							nil]];
}


-(WILDStack*)	stack
{
	return mStack;
}


-(void)	appendInnerAddColorObjectXmlToString: (NSMutableString*)theString
{
	// TODO: Implement writing of AddColor data.
}


-(void)	appendInnerXmlToString: (NSMutableString*)theString
{
	[theString appendFormat: @"\t<id>%lld</id>\n", mID];
	[theString appendFormat: @"\t<name>%@</name>\n", WILDStringEscapedForXML(mName)];
	[theString appendFormat: @"\t<showPict>%@</showPict>\n", mShowPict ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<cantDelete>%@</cantDelete>\n", mCantDelete ? @"<true />" : @"<false />"];
	[theString appendFormat: @"\t<dontSearch>%@</dontSearch>\n", mDontSearch ? @"<true />" : @"<false />"];
	if( mPicture )
		[theString appendFormat: @"\t<bitmap>%@</bitmap>\n", mPicture];	// TODO: Get bitmap from media and reference it from there.
	[theString appendFormat: @"\t<script>%@</script>\n", WILDStringEscapedForXML(mScript)];
	
	for( WILDPart* currPart in mParts )
	{
		[theString appendString: [currPart xmlString]];
	}
	
	for( WILDPartContents* currContents in [mContents allObjects] )
	{
		[theString appendString: [currContents xmlString]];
	}
	
	[self appendInnerAddColorObjectXmlToString: theString];
}


-(NSString*)	xmlStringForWritingToURL: (NSURL*)packageURL error: (NSError**)outError
{
	NSMutableString	*	theString = [NSMutableString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
												"<!DOCTYPE %1$@ PUBLIC \"-//Apple, Inc.//DTD %1$@ V 2.0//EN\" \"\" >\n"
																		"<%1$@>\n", [self partLayer]];
	
	[self appendInnerXmlToString: theString];	// Hook-in point for subclasses (like WILDCard).
	
	[theString appendFormat: @"</%@>\n", [self partLayer]];
	
	return theString;
}


-(void)	updateChangeCount: (NSDocumentChangeType)inChange
{
	[[mStack document] updateChangeCount: inChange];
}


-(void)	partDidChange: (NSNotification*)notif
{
	WILDPart	*	thePart = [notif object];
	NSString	*	propName = [[notif userInfo] objectForKey: WILDAffectedPropertyKey];
	SEL				theAction = NSSelectorFromString( [propName stringByAppendingString: @"PropertyDidChangeOfPart:"] );
	if( [self respondsToSelector: theAction] )
		[self performSelector: theAction withObject: thePart];
}


-(void)	familyPropertyDidChangeOfPart: (WILDPart*)thePart
{
	[mButtonFamilies removeObject: thePart];
	[mButtonFamilies addObject: thePart forKey: [NSNumber numberWithInteger: [thePart family]]];
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
	if( mName && [mName length] > 0 )
		return [NSString stringWithFormat: @"background “%1$@” (ID %2$lld)", mName, mID];
	else
		return [NSString stringWithFormat: @"background ID %1$lld", mID];
}


-(NSImage*)	displayIcon
{
	return [NSImage imageNamed: @"BackgroundIconSmall"];
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ {\nid = %lld\nname = %@\nparts = %@\n}", [self class], mID, mName, mParts];
}

@end
