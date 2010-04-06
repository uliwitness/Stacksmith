//
//  UKPropagandaStack.h
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKPropagandaScriptContainer.h"
#import "UKPropagandaSearchContext.h"


@class UKPropagandaBackground;
@class UKPropagandaCard;
@class UKPropagandaCardView;
@class QTMovie;


@interface UKPropagandaStack : NSObject <UKPropagandaScriptContainer,UKPropagandaSearchable>
{
	NSMutableArray*			mBackgrounds;		// List of all backgrounds in this stack.
	NSMutableArray*			mCards;				// List of all cards in this stack.
	NSMutableArray*			mPatterns;			// (Possibly customized) patterns for drawing using paint tools.
	NSString*				mScript;			// Script of this stack.
	NSSize					mCardSize;			// Size of cards in this stack.
	NSString*				mCreatedByVersion;
	NSString*				mLastCompactedVersion;
	NSString*				mFirstEditedVersion;
	NSString*				mLastEditedVersion;
	BOOL					mCantPeek;			// Do we prevent "peeking" of button rects using Cmd-Option?
	BOOL					mCantAbort;			// Do we prohibit Cmd-. from canceling scripts?
	BOOL					mPrivateAccess;		// Do we require a password before opening this stack?
	BOOL					mCantDelete;		// Are scripts allowed to delete this stack?
	BOOL					mCantModify;		// Is this stack write-protected?
	NSInteger				mUserLevel;			// Maximum user level for this stack.
	NSString*				mPath;				// Path of our package.
	NSMutableDictionary*	mFontIDTable;		// Font ID --> name mappings
	NSMutableDictionary*	mTextStyles;		// STBL-extracted text/style info.
	NSMutableArray*			mPictures;			// Media.
}

-(id)			initWithXMLElement: (NSXMLElement*)elem path: (NSString*)thePath;

-(void)			addCard: (UKPropagandaCard*)theCard;
-(void)			addBackground: (UKPropagandaBackground*)theBg;
-(void)			addFont: (NSString*)fontName withID: (NSInteger)fontID;
-(void)			addStyleFormatWithID: (NSInteger)styleID forFontID: (NSInteger)fontID size: (NSInteger)fontSize styles: (NSArray *)fontStyles;

-(NSInteger)				uniqueIDForCardOrBackground;

-(NSArray*)					cards;
-(void)						setCards: (NSArray*)theCards;	// For use by loading code to generate an ordered card list.
-(UKPropagandaCard*)		cardWithID: (NSInteger)theID;

-(void)						setBackgrounds: (NSArray*)theBkgds;
-(UKPropagandaBackground*)	backgroundWithID: (NSInteger)theID;

-(NSString*)				fontNameForID: (NSInteger)fontID;
-(void)			provideStyleFormatWithID: (NSInteger)oneBasedIdx font: (NSString**)outFontName
						size: (NSInteger*)outFontSize styles: (NSArray**)outFontStyles;

-(NSImage*)		imageNamed: (NSString*)theName;
-(NSImage*)		imageForPatternAtIndex: (NSInteger)idx;

-(NSSize)		cardSize;

-(void)	addMediaFile: (NSString*)fileName withType: (NSString*)type
			name: (NSString*)iconName andID: (NSInteger)iconID hotSpot: (NSPoint)pos;
-(NSImage*)		pictureOfType: (NSString*)typ name: (NSString*)theName;
-(NSImage*)		pictureOfType: (NSString*)typ id: (NSInteger)theID;
-(NSInteger)	numberOfPictures;
-(NSImage*)		pictureAtIndex: (NSInteger)idx;
-(void)			infoForPictureAtIndex: (NSInteger)idx name: (NSString**)outName id: (NSInteger*)outID
						image: (NSImage**)outImage fileName: (NSString**)outFileName;

-(NSCursor*)	cursorWithName: (NSString*)theName;
-(NSCursor*)	cursorWithID: (NSInteger)theID;

-(QTMovie*)		movieOfType: (NSString*)typ name: (NSString*)theName;	// Movies & sounds.
-(QTMovie*)		movieOfType: (NSString*)typ id: (NSInteger)theID;		// Movies & sounds.

+(NSColor*)		peekOutlineColor;

@end
