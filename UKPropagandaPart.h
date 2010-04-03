//
//  UKPropagandaPart.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKPropagandaScriptContainer.h"
#import "UKPropagandaSearchContext.h"


@class UKPropagandaStack;
@class UKPropagandaBackground;


@interface UKPropagandaPart : NSObject <UKPropagandaScriptContainer,UKPropagandaSearchable>
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
	UKPropagandaBackground*	mOwner;					// Layer that this part belongs to.
	UKPropagandaStack*		mStack;					// Stack this part belongs to.
}

-(id)			initWithXMLElement: (NSXMLElement*)elem forStack: (UKPropagandaStack*)inStack;

-(void)			setRectangle: (NSRect)theBox;
-(NSRect)		rectangle;
-(NSRect)		flippedRectangle;

-(void)			setName: (NSString*)theStr;
-(NSString*)	name;

-(NSString*)	style;
-(void)			setStyle: (NSString*)theStyle;
-(NSString*)	partType;
-(void)			setPartType: (NSString*)partType;
-(NSInteger)	partID;

-(void)						setPartLayer: (NSString*)theLayer;
-(NSString*)				partLayer;
-(void)						setPartOwner: (UKPropagandaBackground*)cardOrBg;
-(UKPropagandaBackground*)	partOwner;

-(NSFont*)				textFont;
-(NSMutableDictionary*)	textAttributes;
-(NSTextAlignment)		textAlignment;

-(BOOL)			showName;
-(BOOL)			isEnabled;
-(BOOL)			visible;
-(void)			setVisible: (BOOL)theState;
-(BOOL)			wideMargins;
-(NSInteger)	popupTitleWidth;
-(NSInteger)	iconID;
-(NSImage*)		iconImage;
-(void)			setHighlighted: (BOOL)inState;
-(BOOL)			highlighted;
-(void)			setAutoHighlight: (BOOL)inState;
-(BOOL)			autoHighlight;
-(BOOL)			sharedText;
-(void)			setHighlightedForTracking: (BOOL)inState;
-(BOOL)			highlightedForTracking;
-(BOOL)			toggleHighlightAfterTracking;
-(NSInteger)	family;
-(BOOL)			textLocked;
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

-(UKPropagandaStack*)	stack;

-(void)	updateOnClick: (NSButton*)thePart;

@end
