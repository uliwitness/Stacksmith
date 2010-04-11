//
//  UKPropagandaBackground.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaBackground.h"
#import "UKPropagandaPart.h"
#import "UKPropagandaPartContents.h"
#import "UKPropagandaXMLUtils.h"
#import "UKMultiMap.h"
#import "UKPropagandaStack.h"


@implementation UKPropagandaBackground

-(id)	initForStack: (UKPropagandaStack*)theStack
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
		mContents = [[NSMutableArray alloc] init];
	}
	
	return self;
}


-(id)	initWithXMLElement: (NSXMLElement*)elem forStack: (UKPropagandaStack*)theStack
{
	if(( self = [super init] ))
	{
		mID = UKPropagandaIntegerFromSubElementInElement( @"id", elem );
		mName = [UKPropagandaStringFromSubElementInElement( @"name", elem ) retain];
		
		mShowPict = UKPropagandaBoolFromSubElementInElement( @"showPict", elem );
		mCantDelete = UKPropagandaBoolFromSubElementInElement( @"cantDelete", elem );
		mDontSearch = UKPropagandaBoolFromSubElementInElement( @"dontSearch", elem );
		
		mStack = theStack;
		mPicture = [UKPropagandaStringFromSubElementInElement( @"bitmap", elem ) retain];
		
		mScript = [UKPropagandaStringFromSubElementInElement( @"script", elem ) retain];
		mButtonFamilies = [[UKMultiMap alloc] init];
		
		NSArray*		parts = [elem elementsForName: @"part"];
		mParts = [[NSMutableArray alloc] initWithCapacity: [parts count]];
		for( NSXMLElement* currPart in parts )
		{
			UKPropagandaPart*	newPart = [[[UKPropagandaPart alloc] initWithXMLElement: currPart forStack: theStack] autorelease];
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
			UKPropagandaPartContents*	newCont = [[[UKPropagandaPartContents alloc] initWithXMLElement: currContent forStack: theStack] autorelease];
			NSString*					theKey = [NSString stringWithFormat: @"%@:%d", [newCont partLayer], [newCont partID]];
			[mContents setObject: newCont forKey: theKey];
		}
		
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
	
	NSImage*	img = [mStack imageNamed: (NSString*)mPicture];
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


-(UKPropagandaPartContents*)	contentsForPart: (UKPropagandaPart*)thePart
{
	NSString*	theKey = [NSString stringWithFormat: @"%@:%d", [thePart partLayer], [thePart partID]];
	return [mContents objectForKey: theKey];
}


-(UKPropagandaPart*)	partWithID: (NSInteger)theID
{
	for( UKPropagandaPart* thePart in mParts )
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


-(void)	updatePartOnClick: (UKPropagandaPart*)thePart
{
	if( [thePart family] == 0 )
	{
		if( [thePart autoHighlight] && ([[thePart style] isEqualToString: @"radiobutton"] || [[thePart style] isEqualToString: @"checkbox"]) )
			[thePart setHighlighted: ![thePart highlighted]];
		return;
	}
	
	NSNumber*	theNum = [NSNumber numberWithInteger: [thePart family]];
	NSArray*	peers = [mButtonFamilies objectsForKey: theNum];
	
	for( UKPropagandaPart* currPart in peers )
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
		NSInteger	objectID = UKPropagandaIntegerFromSubElementInElement( @"id", theObject );
		NSInteger	objectBevel = UKPropagandaIntegerFromSubElementInElement( @"bevel", theObject );
		NSString*	objectType = UKPropagandaStringFromSubElementInElement( @"type", theObject );
		NSString*	objectName = UKPropagandaStringFromSubElementInElement( @"name", theObject );
		BOOL		objectTransparent = UKPropagandaBoolFromSubElementInElement( @"transparent", theObject );
		BOOL		objectVisible = UKPropagandaBoolFromSubElementInElement( @"visible", theObject );
		NSRect		objectRect = UKPropagandaRectFromSubElementInElement( @"rect", theObject );
		NSColor*	objectColor = UKPropagandaColorFromSubElementInElement( @"color", theObject );
		
		if( [objectType isEqualToString: @"button"] )
		{
			UKPropagandaPart*	thePart = [self partWithID: objectID];
			[thePart setFillColor: objectColor];
			[thePart setBevel: objectBevel];
			[mAddColorParts addObject: thePart];
		}
		else if( [objectType isEqualToString: @"field"] )
		{
			UKPropagandaPart*	thePart = [self partWithID: objectID];
			[thePart setFillColor: objectColor];
			[thePart setBevel: objectBevel];
			[mAddColorParts addObject: thePart];
		}
		else if( [objectType isEqualToString: @"rectangle"] )
		{
			UKPropagandaPart*	thePart = [[[UKPropagandaPart alloc] initWithXMLElement: nil forStack: mStack] autorelease];
			[thePart setRectangle: objectRect];
			[thePart setFillColor: objectColor];
			[thePart setBevel: objectBevel];
			[thePart setPartType: @"rectangle"];
			[thePart setStyle: @"opaque"];
			[thePart setVisible: objectVisible];
			[mAddColorParts addObject: thePart];
		}
		else if( [objectType isEqualToString: @"picture"] )
		{
			UKPropagandaPart*	thePart = [[[UKPropagandaPart alloc] initWithXMLElement: nil forStack: mStack] autorelease];
			[thePart setRectangle: objectRect];
			[thePart setName: objectName];
			[thePart setPartType: @"picture"];
			[thePart setStyle: objectTransparent ? @"transparent" : @"opaque"];
			[thePart setVisible: objectVisible];
			[mAddColorParts addObject: thePart];
		}
	}
}


-(UKPropagandaStack*)	stack
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

@end
