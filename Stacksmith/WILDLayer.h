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
#import "WILDObjectValue.h"


@class ULIMultiMap;
@class WILDStack;
@class WILDPart;
@class WILDPartContents;
@class WILDCard;
@class WILDBackground;


@interface WILDLayer : NSObject <WILDScriptContainer,WILDObject>
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
	NSMutableDictionary		*	mUserProperties;
	
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
										forStack: (WILDStack*)theStack error: (NSError**)outError;

-(void)							loadAddColorObjects: (NSXMLElement*)theElem;

-(WILDObjectID)					backgroundID;

-(NSImage*)						picture;
-(void)							setPicture: (NSImage*)inImage;
-(BOOL)							showPicture;

-(NSArray*)						parts;
-(NSArray*)						addColorParts;
-(WILDPartContents*)			contentsForPart: (WILDPart*)thePart;
-(WILDPartContents*)			contentsForPart: (WILDPart*)thePart create: (BOOL)createIfNeeded;
-(void)							addContents: (WILDPartContents*)inContents;
-(WILDPart*)					partWithID: (WILDObjectID)theID;
-(WILDObjectID)					uniqueIDForPart;

-(NSUInteger)					numberOfPartsOfType: (NSString*)inPartType;
-(WILDPart*)					partAtIndex: (NSUInteger)inPartIndex ofType: (NSString*)inPartType;
-(NSUInteger)					indexOfPart: (WILDPart*)inPart asType: (NSString*)inPartType;
-(WILDPart*)					partNamed: (NSString*)inPartName ofType: (NSString*)inPartType;
-(void)							movePart: (WILDPart*)inPart toIndex: (NSUInteger)inNewIndex asType: (NSString*)inPartType;

-(void)							updatePartOnClick: (WILDPart*)thePart withCard: (WILDCard*)inCard background: (WILDBackground*)inBackground;

-(NSString*)					partLayer;

-(WILDPart*)					createNewButtonNamed: (NSString*)inName;
-(WILDPart*)					createNewButton: (id)sender;

-(WILDPart*)					createNewFieldNamed: (NSString*)inName;
-(WILDPart*)					createNewField: (id)sender;

-(WILDPart*)					createNewMoviePlayerNamed: (NSString*)inName;
-(WILDPart*)					createNewMoviePlayer: (id)sender;

-(WILDPart*)					createNewBrowserNamed: (NSString*)inName;
-(WILDPart*)					createNewBrowser: (id)sender;

-(WILDPart*)					addNewPartFromXMLTemplate: (NSURL*)xmlFile;
-(void)							addPart: (WILDPart*)newPart;
-(void)							deletePart: (WILDPart*)inPart;

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
