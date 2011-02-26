//
//  WILDBackground.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDBackground.h"
#import "WILDPart.h"
#import "WILDPartContents.h"
#import "WILDXMLUtils.h"
#import "UKMultiMap.h"
#import "WILDStack.h"
#import "WILDNotifications.h"
#import "UKRandomInteger.h"


@implementation WILDBackground

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
		mButtonFamilies = [[UKMultiMap alloc] init];

		mParts = [[NSMutableArray alloc] init];
		mAddColorParts = [[NSMutableArray alloc] init];
		mContents = [[NSMutableDictionary alloc] init];
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
		mButtonFamilies = [[UKMultiMap alloc] init];
		
		NSArray*		parts = [elem elementsForName: @"part"];
		mParts = [[NSMutableArray alloc] initWithCapacity: [parts count]];
		for( NSXMLElement* currPart in parts )
		{
			WILDPart*	newPart = [[[WILDPart alloc] initWithXMLElement: currPart forStack: theStack] autorelease];
			[newPart setPartLayer: [self partLayer]];
			[newPart setPartOwner: self];
			[mParts addObject: newPart];
			if( [newPart family] > 0 )
				[mButtonFamilies addObject: newPart forKey: [NSNumber numberWithInteger: [newPart family]]];
		}
		
		mAddColorParts = [[NSMutableArray alloc] init];
		NSArray*		contents = [elem elementsForName: @"content"];
		mContents = [[NSMutableDictionary alloc] initWithCapacity: [contents count]];
		for( NSXMLElement* currContent in contents )
		{
			WILDPartContents*	newCont = [[[WILDPartContents alloc] initWithXMLElement: currContent forStack: theStack] autorelease];
			NSString*					theKey = [NSString stringWithFormat: @"%@:%d", [newCont partLayer], [newCont partID]];
			[mContents setObject: newCont forKey: theKey];
		}
		
		[self loadAddColorObjects: elem];
	}
	
	return self;
}


-(void)	dealloc
{
	DESTROY(mButtonFamilies);
	DESTROY(mName);
	DESTROY(mScript);
	DESTROY(mPicture);
	DESTROY(mParts);
	DESTROY(mAddColorParts);
	
	mStack = nil;
	
	[super dealloc];
}


-(NSInteger)	backgroundID
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
	NSString*	theKey = [NSString stringWithFormat: @"%@:%d", [thePart partLayer], [thePart partID]];
	return [mContents objectForKey: theKey];
}


-(WILDPart*)	partWithID: (NSInteger)theID
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


-(void)	updatePartOnClick: (WILDPart*)thePart
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
			//NSLog( @"Family: Setting highlight of %@ to %s", [currPart displayName], newState?"true":"false" );
		}
	}
}


-(void)	loadAddColorObjects: (NSXMLElement*)theElem
{
	NSArray*	theObjects = [theElem elementsForName: @"addcolorobject"];
	
	for( NSXMLElement* theObject in theObjects )
	{
		NSInteger	objectID = WILDIntegerFromSubElementInElement( @"id", theObject );
		NSInteger	objectBevel = WILDIntegerFromSubElementInElement( @"bevel", theObject );
		NSString*	objectType = WILDStringFromSubElementInElement( @"type", theObject );
		NSString*	objectName = WILDStringFromSubElementInElement( @"name", theObject );
		BOOL		objectTransparent = WILDBoolFromSubElementInElement( @"transparent", theObject );
		BOOL		objectVisible = WILDBoolFromSubElementInElement( @"visible", theObject );
		NSRect		objectRect = WILDRectFromSubElementInElement( @"rect", theObject );
		NSColor*	objectColor = WILDColorFromSubElementInElement( @"color", theObject );
		
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


-(NSInteger)	uniqueIDForPart
{
	NSInteger	partID = UKRandomInteger();
	BOOL		notUnique = YES;
	
	while( notUnique )
	{
		notUnique = NO;
		
		for( WILDPart* currPart in mParts )
		{
			if( [currPart partID] == partID )
			{
				notUnique = YES;
				partID = UKRandomInteger();
				break;
			}
		}
	}
	
	return partID;
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerDidAddPartNotification
						object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys: newPart, WILDAffectedPartKey,
							nil]];
}


-(WILDStack*)	stack
{
	return mStack;
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
		return [NSString stringWithFormat: @"background “%1$@” (ID %2$d)", mName, mID];
	else
		return [NSString stringWithFormat: @"background ID %1$d", mID];
}


-(NSImage*)	displayIcon
{
	return [NSImage imageNamed: @"BackgroundIconSmall"];
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ {\nid = %d\nname = %@\nparts = %@\n}", [self class], mID, mName, mParts];
}

@end
