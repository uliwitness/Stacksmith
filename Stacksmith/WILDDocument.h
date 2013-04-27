//
//  WILDDocument.h
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//


/*!
	@header WILDDocument
	Stacksmith's main document class.
*/


#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "WILDObjectID.h"
#import "WILDVisibleObject.h"

@class WILDStack;
@class WILDCard;


/*!
	@class WILDDocument
	A document referencing the Stacksmith file on disk, containing one or more stacks, plus any information global to the file.
*/


@interface WILDDocument : NSDocument
{
	NSMutableArray		*	mErrorsAndWarnings;	//! Errors and warnings when opening old documents, or stacks imported from HyperCard.
	NSMutableDictionary	*	mFontIDTable;		//! Font ID --> name mappings. Needed to read imported HyperCard stacks.
	NSMutableDictionary	*	mTextStyles;		//! STBL-extracted text/style info. Needed to read imported HyperCard stacks. Array of WILDStyleEntry objects
	NSMutableArray		*	mMediaList;			//! Pictures, movies, sounds etc. contained in this stack. Array of WILDMediaEntry objects.
	NSMutableArray		*	mStacks;				//! Array of WILDStack objects loaded from this document.
	NSString			*	mCreatedByVersion;		//! Version string of the version of Stacksmith (or HyperCard) that created this stack, includes the host app's name.
	NSString			*	mLastCompactedVersion;	//! Version string of the last version of Stacksmith (or HyperCard) that compacted this stack, includes the host app's name. (currently only initialized and set, but Stacksmith doesn't compact stacks)
	NSString			*	mFirstEditedVersion;	//! Version string of the first version of Stacksmith (or HyperCard) that edited this stack, includes the host app's name. (Initialized by Stacksmith for new files, maintained for imported stacks, but otherwise unused)
	NSString			*	mLastEditedVersion;		//! Version string of the most recent version of Stacksmith (or HyperCard) that edited this stack, includes the host app's name.
	struct LEOContextGroup*	mContextGroup;			//! The context group needed for the Leonie interpreter to compile and run scripts. This holds global variables etc.
	
	WILDObjectID			mMediaIDSeed;			//! ID number for next new icon etc. (unless already taken, then we'll add to it until we hit a free one)
	WILDObjectID			mStackIDSeed;			//! ID number for next new stack in document (unless already taken, then we'll add to it until we hit a free one).
}

-(void)			addFont: (NSString*)fontName withID: (WILDObjectID)fontID;
-(void)			addStyleFormatWithID: (WILDObjectID)styleID forFontName: (NSString*)fontName size: (NSInteger)fontSize styles: (NSArray *)fontStyles;

-(WILDStack*)	stackNamed: (NSString*)inName;
-(WILDStack*)	stackWithID: (WILDObjectID)inID;
-(WILDStack*)	mainStack;

-(WILDObjectID)	uniqueIDForStack;
-(WILDObjectID)	uniqueIDForMedia;

-(NSString*)	fontNameForID: (WILDObjectID)fontID;
-(void)			provideStyleFormatWithID: (NSInteger)oneBasedIdx font: (NSString**)outFontName
						size: (NSInteger*)outFontSize styles: (NSArray**)outFontStyles;

-(NSImage*)		imageNamed: (NSString*)theName;
-(NSURL*)		URLForImageNamed: (NSString*)theName;
//-(NSImage*)		imageForPatternAtIndex: (NSInteger)idx;

-(BOOL)			loadStandardResourceTableReturningError: (NSError**)outError;
-(void)			addMediaFile: (NSString*)fileName withType: (NSString*)type
					name: (NSString*)iconName andID: (WILDObjectID)iconID hotSpot: (NSPoint)pos
					imageOrCursor: (id)imgOrCursor isBuiltIn: (BOOL)isBuiltIn;
-(NSImage*)		pictureOfType: (NSString*)typ name: (NSString*)theName;
-(NSImage*)		pictureOfType: (NSString*)typ id: (WILDObjectID)theID;
-(NSInteger)	numberOfPictures;
-(NSImage*)		pictureAtIndex: (NSInteger)idx;
-(void)			infoForPictureAtIndex: (NSInteger)idx name: (NSString**)outName id: (WILDObjectID*)outID
						image: (NSImage**)outImage fileName: (NSString**)outFileName isBuiltIn: (BOOL*)isBuiltIn;

-(NSCursor*)	cursorWithName: (NSString*)theName;
-(NSCursor*)	cursorWithID: (WILDObjectID)theID;

-(QTMovie*)		movieOfType: (NSString*)typ name: (NSString*)theName;	// Movies & sounds.
-(QTMovie*)		movieOfType: (NSString*)typ id: (WILDObjectID)theID;	// Movies & sounds.

-(NSURL*)		URLForMediaOfType: (NSString*)typ name: (NSString*)theName;

-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind;

-(struct LEOContextGroup*)	scriptContextGroupObject;

-(WILDCard*)	currentCard;

+(WILDStack*)	frontStackNamed: (NSString*)stackName;	// If name is NIL, it grabs the main stack of that document.
+(WILDStack*)	openStackNamed: (NSString*)stackName;

@end
