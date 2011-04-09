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


@class WILDBackground;
@class WILDCard;
@class WILDCardView;
@class WILDDocument;
@class QTMovie;


@interface WILDStack : NSObject <WILDScriptContainer,WILDSearchable>
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
	NSInteger				mUserLevel;			// Maximum user level for this stack.
	WILDDocument*			mDocument;			// Our owner, NOT RETAINED!
	WILDObjectID			mID;				// Unique ID number of this stack in the document.
	
	WILDObjectID			mCardIDSeed;		// ID number for next new card/background (unless already taken, then we'll add to it until we hit a free one).
	struct LEOScript*		mScriptObject;		// Compiled script, lazily created/recreated on changes.
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
-(WILDObjectID)		uniqueIDForMedia;

-(NSArray*)			cards;
-(WILDCard*)		cardWithID: (WILDObjectID)theID;

-(NSArray*)			backgrounds;
-(WILDBackground*)	backgroundWithID: (WILDObjectID)theID;

-(NSSize)			cardSize;
-(void)				setCardSize: (NSSize)inSize;

+(NSColor*)			peekOutlineColor;

-(WILDDocument*)	document;
-(void)				updateChangeCount: (NSDocumentChangeType)inChange;

-(NSString*)		xmlStringForWritingToURL: (NSURL*)packageURL error: (NSError**)outError;

-(NSString*)		name;
-(void)				setName: (NSString*)inName;

@end
