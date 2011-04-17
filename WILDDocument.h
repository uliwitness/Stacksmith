//
//  WILDDocument.h
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "WILDObjectID.h"
#import "WILDVisibleObject.h"

@class WILDStack;
@class WILDCard;


@interface WILDDocument : NSDocument
{
	NSMutableArray		*	mErrorsAndWarnings;	// Errors and warnings when opening old documents, or stacks imported from HyperCard.
	NSMutableDictionary	*	mFontIDTable;		// Font ID --> name mappings
	NSMutableDictionary	*	mTextStyles;		// STBL-extracted text/style info.
	NSMutableArray		*	mMediaList;			// Media.
	NSMutableArray		*	mStacks;			// List of stacks in this document.
	NSString			*	mCreatedByVersion;
	NSString			*	mLastCompactedVersion;
	NSString			*	mFirstEditedVersion;
	NSString			*	mLastEditedVersion;
	struct LEOContextGroup*	mContextGroup;
	
	WILDObjectID			mMediaIDSeed;		// ID number for next new icon etc. (unless already taken, then we'll add to it until we hit a free one).
	WILDObjectID			mStackIDSeed;		// ID number for next new stack in document (unless already taken, then we'll add to it until we hit a free one).
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
-(NSImage*)		imageForPatternAtIndex: (NSInteger)idx;

-(void)			loadStandardResourceTableReturningError: (NSError**)outError;
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

-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind;

-(struct LEOContextGroup*)	contextGroup;

-(WILDCard*)	currentCard;

+(WILDStack*)	frontStackNamed: (NSString*)stackName;	// If name is NIL, it grabs the main stack of that document.
+(WILDStack*)	openStackNamed: (NSString*)stackName;

@end
