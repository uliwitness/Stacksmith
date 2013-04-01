//
//  WILDStack.h
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDScriptContainer.h"
#import "WILDSearchContext.h"
#import "WILDObjectID.h"
#import "ForgeWILDObjectValue.h"


@class WILDBackground;
@class WILDCard;
@class WILDCardView;
@class WILDDocument;
@class QTMovie;


@interface WILDStack : NSObject <WILDScriptContainer,WILDSearchable,WILDObject>
{
	NSMutableArray*			mBackgrounds;		// List of all backgrounds in this stack.
	NSMutableArray*			mCards;				// List of all cards in this stack.
	NSMutableSet*			mMarkedCards;		// List of all cards whose "marked" property has been set.
	NSString*				mScript;			// Script of this stack.
	NSSize					mCardSize;			// Size of cards in this stack.
	BOOL					mCantPeek;			// Do we prevent "peeking" of button rects using Cmd-Option?
	BOOL					mCantAbort;			// Do we prohibit Cmd-. from canceling scripts?
	BOOL					mPrivateAccess;		// Do we require a password before opening this stack?
	BOOL					mCantDelete;		// Are scripts allowed to delete this stack?
	BOOL					mCantModify;		// Is this stack write-protected?
	int						mUserLevel;			// Maximum user level for this stack.
	WILDDocument*			mDocument;			// Our owner, NOT RETAINED!
	WILDObjectID			mID;				// Unique ID number of this stack in the document.
	
	WILDObjectID			mCardIDSeed;		// ID number for next new card/background (unless already taken, then we'll add to it until we hit a free one).
	struct LEOScript*		mScriptObject;		// Compiled script, lazily created/recreated on changes.
	NSString	*			mName;				// Name of this stack, for finding it inside the stack file.
	
	LEOObjectID					mIDForScripts;			// The ID Leonie uses to refer to this object.
	LEOObjectSeed				mSeedForScripts;		// The seed value to go with mIDForScripts.
	struct LEOValueObject		mValueForScripts;		// A LEOValue so scripts can reference us (see mIDForScripts).
}

-(id)				initWithXMLDocument: (NSXMLDocument*)theDoc document: (WILDDocument*)owner;
-(id)				initWithDocument: (WILDDocument*)owner;

-(void)				addCard: (WILDCard*)theCard;
-(void)				removeCard: (WILDCard*)theCard;
-(void)				setMarked: (BOOL)isMarked forCard: (WILDCard*)inCard;
-(void)				addBackground: (WILDBackground*)theBg;
-(void)				removeBackground: (WILDBackground*)theBg;

-(WILDObjectID)		stackID;

-(WILDObjectID)		uniqueIDForCardOrBackground;

-(NSArray*)			cards;
-(WILDCard*)		cardWithID: (WILDObjectID)theID;
-(WILDCard*)		cardNamed: (NSString*)cardName;
-(WILDCard*)		currentCard;

-(NSArray*)			backgrounds;
-(WILDBackground*)	backgroundWithID: (WILDObjectID)theID;
-(WILDBackground*)	backgroundNamed: (NSString*)cardName;

-(NSSize)			cardSize;
-(void)				setCardSize: (NSSize)inSize;

+(NSColor*)			peekOutlineColor;

-(WILDDocument*)	document;
-(void)				updateChangeCount: (NSDocumentChangeType)inChange;

-(NSString*)		xmlStringForWritingToURL: (NSURL*)packageURL forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error: (NSError**)outError;

-(NSString*)		name;
-(void)				setName: (NSString*)inName;

@end
