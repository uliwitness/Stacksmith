//
//  WILDLayer.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDScriptContainer.h"
#import "WILDObjectID.h"
#import "LEOValue.h"


@class ULIMultiMap;
@class WILDStack;
@class WILDPart;
@class WILDPartContents;
@class WILDCard;
@class WILDBackground;


@interface WILDLayer : NSObject <WILDScriptContainer>
{
	WILDObjectID				mID;				// Unique ID number of this background/card.
	NSString*					mName;				// Name of this background/card.
	NSString*					mScript;			// Script text.
	struct LEOScript*			mScriptObject;		// Compiled script.
	BOOL						mShowPict;			// Should we draw mPicture or not?
	BOOL						mDontSearch;		// Do not include this card in searches.
	BOOL						mCantDelete;		// Prevent scripts from deleting this card?
	NSString*					mPictureName;		// Card/background picture's file name.
	NSImage*					mPicture;			// Card/background picture.
	NSMutableArray*				mParts;				// Array of parts on this card.
	NSMutableArray*				mAddColorParts;		// Array of parts for which we have AddColor color information. May contain parts that are already in mParts.
	NSMutableDictionary*		mContents;			// Dictionary of part ID -> contents mappings
	ULIMultiMap*				mButtonFamilies;	// Family ID as key, and arrays of button parts belonging to these families.
	WILDStack*					mStack;
	
	WILDObjectID				mPartIDSeed;
	
	LEOObjectID					mIDForScripts;			// The ID Leonie uses to refer to this object.
	LEOObjectSeed				mSeedForScripts;		// The seed value to go with mIDForScripts.
	struct LEOValueObject		mValueForScripts;		// A LEOValue so scripts can reference us (see mIDForScripts).
}

@property (copy) NSString*	name;
@property (assign) BOOL		dontSearch;
@property (assign) BOOL		cantDelete;

-(id)							initForStack: (WILDStack*)theStack;
-(id)							initWithXMLDocument: (NSXMLDocument*)elem
										forStack: (WILDStack*)theStack;

-(void)							loadAddColorObjects: (NSXMLElement*)theElem;

-(WILDObjectID)					backgroundID;

-(NSImage*)						picture;
-(void)							setPicture: (NSImage*)inImage;
-(BOOL)							showPicture;

-(NSArray*)						parts;
-(NSArray*)						addColorParts;
-(WILDPartContents*)			contentsForPart: (WILDPart*)thePart;
-(WILDPart*)					partWithID: (WILDObjectID)theID;
-(WILDObjectID)					uniqueIDForPart;

-(NSInteger)					numberOfPartsOfType: (NSString*)inPartType;
-(WILDPart*)					partAtIndex: (NSUInteger)inPartIndex ofType: (NSString*)inPartType;
-(WILDPart*)					partNamed: (NSString*)inPartName ofType: (NSString*)inPartType;

-(void)							updatePartOnClick: (WILDPart*)thePart withCard: (WILDCard*)inCard background: (WILDBackground*)inBackground;

-(NSString*)					partLayer;

-(void)							createNewButton: (id)sender;
-(void)							createNewField: (id)sender;
-(void)							addNewPartFromXMLTemplate: (NSURL*)xmlFile;

-(void)							bringPartCloser: (WILDPart*)inPart;
-(void)							sendPartFarther: (WILDPart*)inPart;

-(WILDStack*)					stack;
-(void)							updateChangeCount: (NSDocumentChangeType)inChange;

-(NSString*)					script;
-(void)							setScript: (NSString*)theScript;

-(NSString*)					xmlStringForWritingToURL: (NSURL*)packageURL forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error: (NSError**)outError;
-(void)							appendInnerAddColorObjectXmlToString: (NSMutableString*)theString;
-(void)							appendInnerXmlToString: (NSMutableString*)theString;	// Hook-in point for subclasses like WILDCard.

-(void)							getID: (LEOObjectID*)outID seedForScripts: (LEOObjectSeed*)outSeed;

@end
