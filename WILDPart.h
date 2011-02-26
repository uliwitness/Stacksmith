//
//  WILDPart.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDScriptContainer.h"
#import "WILDSearchContext.h"


@class WILDStack;
@class WILDBackground;


@interface WILDPart : NSObject <WILDScriptContainer,WILDSearchable>
{
	NSInteger			mID;
	NSRect				mRectangle;
	NSString*			mName;
	NSString*			mScript;
	NSString*			mStyle;
	NSString*			mType;
	NSString*			mLayer;
	BOOL				mVisible;					// Draw and hit-test this part?
	BOOL				mDontWrap;					// Don't wrap text in this field.
	BOOL				mDontSearch;				// Don't include this part when searching.
	BOOL				mSharedText;				// If this is a background part, ask the background for its contents, not the card.
	BOOL				mFixedLineHeight;
	BOOL				mAutoTab;
	BOOL				mLockText;
	BOOL				mAutoSelect;
	BOOL				mShowLines;
	BOOL				mAutoHighlight;
	BOOL				mHighlight;
	BOOL				mSharedHighlight;
	BOOL				mWideMargins;
	BOOL				mMultipleLines;
	BOOL				mShowName;
	BOOL				mEnabled;
	BOOL				mHighlightedForTracking;	// For most buttons same as highlight.
	NSMutableIndexSet*	mSelectedLines;				// The indexes into the contents' list items array of the selected items.
	NSTextAlignment		mTextAlignment;
	NSString*			mTextFontName;
	NSInteger			mTextFontSize;
	NSArray*			mTextStyles;
	NSInteger			mTextHeight;
	NSInteger			mTitleWidth;
	NSInteger			mIconID;
	NSInteger			mFamily;
	NSColor*			mFillColor;
	NSInteger			mBevel;
	WILDBackground*		mOwner;					// Layer that this part belongs to.
	WILDStack*			mStack;					// Stack this part belongs to.
}

@property (assign) BOOL		dontWrap;
@property (assign) BOOL		autoTab;
@property (assign) BOOL		dontSearch;
@property (assign) BOOL		lockText;
@property (assign) BOOL		wideMargins;
@property (assign) BOOL		fixedLineHeight;
@property (assign) BOOL		showLines;
@property (assign) BOOL		sharedText;


-(id)			initWithXMLElement: (NSXMLElement*)elem forStack: (WILDStack*)inStack;

-(void)			setFlippedRectangle: (NSRect)theBox;
-(NSRect)		flippedRectangle;
-(NSRect)		rectangle;

-(void)			setName: (NSString*)theStr;
-(NSString*)	name;

-(NSString*)	style;
-(void)			setStyle: (NSString*)theStyle;
-(NSString*)	partType;
-(void)			setPartType: (NSString*)partType;
-(NSInteger)	partID;
-(void)			setPartID: (NSInteger)inID;	// If you set this, make sure it is a unique ID not used by another part in the same background/card!
-(NSInteger)	partNumber;
-(NSInteger)	partNumberAmongPartsOfType: (NSString*)partType;

-(void)						setPartLayer: (NSString*)theLayer;
-(NSString*)				partLayer;
-(void)						setPartOwner: (WILDBackground*)cardOrBg;
-(WILDBackground*)	partOwner;

-(NSFont*)				textFont;
-(NSMutableDictionary*)	textAttributes;
-(NSTextAlignment)		textAlignment;

-(BOOL)			showName;
-(void)			setShowName: (BOOL)theState;
-(BOOL)			isEnabled;
-(void)			setEnabled: (BOOL)theState;
-(BOOL)			visible;
-(void)			setVisible: (BOOL)theState;
-(BOOL)			wideMargins;
-(NSInteger)	popupTitleWidth;
-(NSInteger)	iconID;
-(void)			setIconID: (NSInteger)theID;
-(NSImage*)		iconImage;
-(void)			setHighlighted: (BOOL)inState;
-(BOOL)			highlighted;
-(void)			setAutoHighlight: (BOOL)inState;
-(BOOL)			autoHighlight;
-(BOOL)			sharedText;
-(BOOL)			sharedHighlight;
-(void)			setSharedHighlight: (BOOL)inState;
-(void)			setHighlightedForTracking: (BOOL)inState;
-(BOOL)			highlightedForTracking;
-(BOOL)			toggleHighlightAfterTracking;
-(NSInteger)	family;
-(void)			setFamily: (NSInteger)inFamilyNumber;
-(BOOL)			showLines;

-(void)			setFillColor: (NSColor*)theColor;
-(NSColor*)		fillColor;

-(void)			setBevel: (NSInteger)theBevel;
-(NSInteger)	bevel;

-(NSString*)	script;
-(void)			setScript: (NSString*)theScript;

-(BOOL)			autoSelect;
-(void)			setAutoSelect: (BOOL)inState;
-(BOOL)			canSelectMultipleLines;
-(void)			setCanSelectMultipleLines: (BOOL)inState;

-(NSIndexSet*)	selectedListItemIndexes;
-(void)			setSelectedListItemIndexes: (NSIndexSet*)newSelection;

-(NSInteger)	titleWidth;

-(BOOL)			fixedLineHeight;
-(NSInteger)	textHeight;

-(NSString*)	xmlString;

-(WILDStack*)	stack;

-(void)	updateOnClick: (NSButton*)thePart;

@end
