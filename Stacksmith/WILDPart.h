//
//  WILDPart.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "WILDScriptContainer.h"
#import "WILDSearchContext.h"
#import "WILDObjectID.h"
#import "LEOValue.h"
#import "ForgeWILDObjectValue.h"


@class WILDStack;
@class WILDLayer;
@class WILDCard;
@class WILDBackground;
@class WILDPartContents;


@interface WILDPart : NSObject <WILDScriptContainer,WILDSearchable,WILDObject>
{
	WILDObjectID		mID;
	NSRect				mRectangle;
	NSString*			mName;
	NSString*			mMediaPath;
	NSString*			mScript;
	struct LEOScript*	mScriptObject;
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
	BOOL				mControllerVisible;
	BOOL				mHasHorizontalScroller;
	BOOL				mHasVerticalScroller;
	BOOL				mClickableInInactiveWindow;
	QTTime				mCurrentTime;
	NSMutableIndexSet*	mSelectedLines;				// The indexes into the contents' list items array of the selected items.
	NSTextAlignment		mTextAlignment;
	NSString*			mTextFontName;
	NSInteger			mTextFontSize;
	NSArray*			mTextStyles;
	NSInteger			mTextHeight;
	NSInteger			mTitleWidth;
	WILDObjectID		mIconID;
	NSInteger			mFamily;
	NSColor*			mFillColor;
	NSColor*			mLineColor;
	NSColor*			mShadowColor;
	NSSize				mShadowOffset;
	CGFloat				mShadowBlurRadius;
	CGFloat				mLineWidth;
	NSInteger			mBevel;
	WILDLayer*			mOwner;					// Layer that this part belongs to.
	WILDStack*			mStack;					// Stack this part belongs to.
	
	LEOObjectID				mIDForScripts;			// The ID Leonie uses to refer to this object.
	LEOObjectSeed			mSeedForScripts;		// The seed value to go with mIDForScripts.
	struct LEOValueObject	mValueForScripts;		// A LEOValue so scripts can reference us (see mIDForScripts).
}

@property (assign,nonatomic) BOOL			dontWrap;
@property (assign,nonatomic) BOOL			autoTab;
@property (assign,nonatomic) BOOL			dontSearch;
@property (assign,nonatomic) BOOL			lockText;
@property (assign,nonatomic) BOOL			wideMargins;
@property (assign,nonatomic) BOOL			fixedLineHeight;
@property (assign,nonatomic) BOOL			showLines;
@property (assign,nonatomic) BOOL			sharedText;
@property (assign,nonatomic) BOOL			controllerVisible;
@property (assign,nonatomic) BOOL			hasHorizontalScroller;
@property (assign,nonatomic) BOOL			hasVerticalScroller;
@property (assign,nonatomic) BOOL			clickableInInactiveWindow;
@property (copy,nonatomic) NSString*		mediaPath;
@property (assign,nonatomic) QTTime			currentTime;
@property (retain,nonatomic) NSColor*		lineColor;
@property (retain,nonatomic) NSColor*		fillColor;
@property (retain,nonatomic) NSColor*		shadowColor;
@property (assign,nonatomic) NSSize			shadowOffset;
@property (assign,nonatomic) CGFloat		shadowBlurRadius;
@property (assign,nonatomic) CGFloat		lineWidth;
@property (assign,nonatomic) WILDStack*		stack;	// Stack owns us, don't retain back pointer.


-(id)			initWithXMLElement: (NSXMLElement*)elem forStack: (WILDStack*)inStack;

-(void)			setFlippedRectangle: (NSRect)theBox;
-(NSRect)		flippedRectangle;
-(void)			setRectangle: (NSRect)theBox;
-(NSRect)		rectangle;

-(void)			setName: (NSString*)theStr;
-(NSString*)	name;

-(NSString*)	partStyle;
-(void)			setPartStyle: (NSString*)theStyle;
-(NSString*)	partType;
-(void)			setPartType: (NSString*)partType;
-(WILDObjectID)	partID;
-(void)			setPartID: (WILDObjectID)inID;	// If you set this, make sure it is a unique ID not used by another part in the same background/card!
-(NSInteger)	partNumber;

-(void)			setPartLayer: (NSString*)theLayer;
-(NSString*)	partLayer;
-(void)			setPartOwner: (WILDLayer*)cardOrBg;
-(WILDLayer*)	partOwner;

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
-(WILDObjectID)	iconID;
-(void)			setIconID: (WILDObjectID)theID;
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

-(CGFloat)		titleWidth;
-(void)			setTitleWidth: (CGFloat)inWidth;
-(BOOL)			canHaveTitleWidth;

-(BOOL)			fixedLineHeight;
-(NSInteger)	textHeight;

-(NSString*)	xmlString;

-(WILDStack*)	stack;
-(void)			updateChangeCount: (NSDocumentChangeType)inChange;

-(WILDPartContents*)	currentPartContentsAndBackgroundContents: (WILDPartContents**)outBgContents create: (BOOL)inDoCreate onCard: (WILDCard*)inCard forBackgroundEditing: (BOOL)isBgEditing;

-(void)	updateViewOnClick: (NSView*)sender withCard: (WILDCard*)inCard background: (WILDBackground*)inBackground;

@end
