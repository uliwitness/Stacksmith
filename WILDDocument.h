//
//  WILDDocument.h
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@class WILDStack;


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
}

-(void)			addFont: (NSString*)fontName withID: (NSInteger)fontID;
-(void)			addStyleFormatWithID: (NSInteger)styleID forFontName: (NSString*)fontName size: (NSInteger)fontSize styles: (NSArray *)fontStyles;

-(NSInteger)	uniqueIDForStack;
-(NSInteger)	uniqueIDForMedia;

-(NSString*)	fontNameForID: (NSInteger)fontID;
-(void)			provideStyleFormatWithID: (NSInteger)oneBasedIdx font: (NSString**)outFontName
						size: (NSInteger*)outFontSize styles: (NSArray**)outFontStyles;

-(NSImage*)		imageNamed: (NSString*)theName;
-(NSURL*)		URLForImageNamed: (NSString*)theName;
-(NSImage*)		imageForPatternAtIndex: (NSInteger)idx;

-(void)	loadStandardResourceTableReturningError: (NSError**)outError;
-(void)	addMediaFile: (NSString*)fileName withType: (NSString*)type
			name: (NSString*)iconName andID: (NSInteger)iconID hotSpot: (NSPoint)pos
			imageOrCursor: (id)imgOrCursor;
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

@end
