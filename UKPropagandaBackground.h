//
//  UKPropagandaBackground.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKPropagandaScriptContainer.h"


@class UKMultiMap;
@class UKPropagandaStack;
@class UKPropagandaPart;
@class UKPropagandaPartContents;


@interface UKPropagandaBackground : NSObject <UKPropagandaScriptContainer>
{
	NSInteger					mID;				// Unique ID number of this background/card.
	NSString*					mName;				// Name of this background/card.
	NSString*					mScript;			// Script text.
	BOOL						mShowPict;			// Should we draw mPicture or not?
	BOOL						mDontSearch;		// Do not include this card in searches.
	BOOL						mCantDelete;		// Prevent scripts from deleting this card?
	NSImage*					mPicture;			// Card/background picture.
	NSMutableArray*				mParts;				// Array of parts on this card.
	NSMutableArray*				mAddColorParts;		// Array of parts for which we have AddColor color information. May contain parts that are already in mParts.
	NSMutableDictionary*		mContents;			// Dictionary of part ID -> contents mappings
	UKMultiMap*					mButtonFamilies;	// Family ID as key, and arrays of button parts belonging to these families.
	UKPropagandaStack*			mStack;
}

-(id)							initForStack: (UKPropagandaStack*)theStack;
-(id)							initWithXMLElement: (NSXMLElement*)elem
										forStack: (UKPropagandaStack*)theStack;

-(void)							loadAddColorObjects: (NSXMLElement*)theElem;

-(NSInteger)					backgroundID;

-(NSImage*)						picture;
-(BOOL)							showPicture;

-(NSArray*)						parts;
-(NSArray*)						addColorParts;
-(UKPropagandaPartContents*)	contentsForPart: (UKPropagandaPart*)thePart;
-(UKPropagandaPart*)			partWithID: (NSInteger)theID;

-(void)							updatePartOnClick: (UKPropagandaPart*)thePart;

-(NSString*)					partLayer;

-(UKPropagandaStack*)			stack;

-(NSString*)					script;
-(void)							setScript: (NSString*)theScript;

@end
