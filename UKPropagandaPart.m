//
//  UKPropagandaPart.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaPart.h"
#import "UKPropagandaXMLUtils.h"
#import "UKPropagandaBackground.h"
#import "UKPropagandaStack.h"
#import "UKPropagandaPartContents.h"
#import "UKPropagandaNotifications.h"


static NSInteger UKMinimum( NSInteger a, NSInteger b )
{
	return ((a < b) ? a : b);
}


static NSInteger UKMaximum( NSInteger a, NSInteger b )
{
	return ((a > b) ? a : b);
}


@implementation UKPropagandaPart

-(id)	initWithXMLElement: (NSXMLElement*)elem forStack: (UKPropagandaStack*)inStack
{
	if(( self = [super init] ))
	{
		mStack = inStack;
		mID = UKPropagandaIntegerFromSubElementInElement( @"id", elem );
		mRectangle = UKPropagandaRectFromSubElementInElement( @"rect", elem );
		mName = [UKPropagandaStringFromSubElementInElement( @"name", elem ) retain];
		mScript = [UKPropagandaStringFromSubElementInElement( @"script", elem ) retain];
		mStyle = [UKPropagandaStringFromSubElementInElement( @"style", elem ) retain];
		mType = [UKPropagandaStringFromSubElementInElement( @"type", elem ) retain];
		mVisible = (!elem) ? YES : UKPropagandaBoolFromSubElementInElement( @"visible", elem );
		mDontWrap = UKPropagandaBoolFromSubElementInElement( @"dontWrap", elem );
		mDontSearch = UKPropagandaBoolFromSubElementInElement( @"dontSearch", elem );
		mSharedText = UKPropagandaBoolFromSubElementInElement( @"sharedText", elem );
		mFixedLineHeight = UKPropagandaBoolFromSubElementInElement( @"fixedLineHeight", elem );
		mAutoTab = UKPropagandaBoolFromSubElementInElement( @"autoTab", elem );
		mLockText = UKPropagandaBoolFromSubElementInElement( @"lockText", elem );
		mAutoSelect = UKPropagandaBoolFromSubElementInElement( @"autoSelect", elem );
		mShowLines = UKPropagandaBoolFromSubElementInElement( @"showLines", elem );
		mAutoHighlight = UKPropagandaBoolFromSubElementInElement( @"autoHighlight", elem );
		mWideMargins = UKPropagandaBoolFromSubElementInElement( @"wideMargins", elem );
		mMultipleLines = UKPropagandaBoolFromSubElementInElement( @"multipleLines", elem );
		mShowName = UKPropagandaBoolFromSubElementInElement( @"showName", elem );
		mSelectedLines = [UKPropagandaIndexSetFromSubElementInElement( @"selectedLines", elem, -1 ) retain];
		mTitleWidth = UKPropagandaIntegerFromSubElementInElement( @"titleWidth", elem );
		mHighlight = UKPropagandaBoolFromSubElementInElement( @"highlight", elem );
		mSharedHighlight = UKPropagandaBoolFromSubElementInElement( @"sharedHighlight", elem );
		mEnabled = UKPropagandaBoolFromSubElementInElement( @"enabled", elem );
		mFamily = UKPropagandaIntegerFromSubElementInElement( @"family", elem );
		
		NSString*		alignStr = UKPropagandaStringFromSubElementInElement( @"textAlign", elem );
		if( [alignStr isEqualToString: @"forceLeft"] )
			mTextAlignment = NSLeftTextAlignment;
		else if( [alignStr isEqualToString: @"center"] )
			mTextAlignment = NSCenterTextAlignment;
		else if( [alignStr isEqualToString: @"right"] )
			mTextAlignment = NSRightTextAlignment;
		else if( [alignStr isEqualToString: @"justified"] )	// Not available in HC.
			mTextAlignment = NSJustifiedTextAlignment;
		else //if( [alignStr isEqualToString: @"left"] )
			mTextAlignment = NSNaturalTextAlignment;
		
		NSInteger	textFontID = UKPropagandaIntegerFromSubElementInElement( @"textFontID", elem );
		mTextFontName = [[mStack fontNameForID: textFontID] retain];
		
		mTextFontSize = UKPropagandaIntegerFromSubElementInElement( @"textSize", elem );
		mTextHeight = UKPropagandaIntegerFromSubElementInElement( @"textHeight", elem );
		mTextStyles = [UKPropagandaStringsFromSubElementInElement( @"textStyle", elem ) retain];
		mIconID = UKPropagandaIntegerFromSubElementInElement( @"icon", elem );
	}
	
	return self;
}


-(void)	dealloc
{
	[mName release];
	mName = nil;
	[mScript release];
	mScript = nil;
	[mStyle release];
	mStyle = nil;
	[mType release];
	mType = nil;
	[mLayer release];
	mLayer = nil;
	[mTextFontName release];
	mTextFontName = nil;
	[mTextStyles release];
	mTextStyles = nil;
	[mFillColor release];
	mFillColor = nil;
	
	mStack = nil;
	
	[super dealloc];
}


-(BOOL)	toggleHighlightAfterTracking
{
	return [mStyle isEqualToString: @"checkbox"] || [mStyle isEqualToString: @"radiobutton"]
			 || mFamily != 0;
}


-(void)	setRectangle: (NSRect)theBox
{
	mRectangle = theBox;
}


-(NSRect)	flippedRectangle
{
	return mRectangle;
}


-(NSRect)	rectangle
{
	NSRect		resultRect = mRectangle;
	resultRect.origin.y = [mStack cardSize].height -NSMaxY( mRectangle );
	return resultRect;
}


-(void)	setName: (NSString*)theStr
{
	if( mName != theStr )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"name"
																forKey: UKPropagandaAffectedPropertyKey]];
		[mName release];
		mName = [theStr retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"name"
																forKey: UKPropagandaAffectedPropertyKey]];
	}
}


-(NSString*)	name
{
	return mName;
}


-(NSString*)	style
{
	return mStyle;
}


-(void)	setStyle: (NSString*)theStyle
{
	if( mStyle != theStyle )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"style"
																forKey: UKPropagandaAffectedPropertyKey]];
		[mStyle release];
		mStyle = [theStyle retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"style"
																forKey: UKPropagandaAffectedPropertyKey]];
	}
}


-(NSString*)	partType
{
	return mType;
}


-(void)	setPartType: (NSString*)partType
{
	if( mType != partType )
	{
		[mType release];
		mType = [partType retain];
	}
}


-(NSInteger)	partID
{
	return mID;
}


-(void)		setPartLayer: (NSString*)theLayer
{
	if( theLayer != mLayer )
	{
		[mLayer release];
		mLayer = [theLayer retain];
	}
}

-(NSString*)	partLayer
{
	return mLayer;
}


-(void)	setPartOwner: (UKPropagandaBackground*)cardOrBg
{
	mOwner = cardOrBg;
}


-(UKPropagandaBackground*)	partOwner
{
	return mOwner;
}


-(NSFont*)	textFont
{
	NSFont*		theFont = [NSFont fontWithName: mTextFontName size: mTextFontSize];
	if( !theFont && ([mTextFontName isEqualToString: @"Chicago"] || [mTextFontName isEqualToString: @"Charcoal"]) )
		theFont = [NSFont boldSystemFontOfSize: mTextFontSize];
	if( !theFont )
		theFont = [NSFont fontWithName: @"Geneva" size: mTextFontSize];
	if( !theFont )
		theFont = [NSFont userFontOfSize: mTextFontSize];

	if( [mTextStyles containsObject: @"bold"] )
	{
		NSFont*	boldFont = [[NSFontManager sharedFontManager] convertWeight: YES ofFont: theFont];
		if( boldFont )
			theFont = boldFont;
	}

	if( [mTextStyles containsObject: @"italic"] )
	{
		NSFont*	italicFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSItalicFontMask];
		if( italicFont )
			theFont = italicFont;
	}

	if( [mTextStyles containsObject: @"condense"] )
	{
		NSFont*	condensedFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSCondensedFontMask];
		if( condensedFont )
			theFont = condensedFont;
	}

	if( [mTextStyles containsObject: @"extend"] )
	{
		NSFont*	expandedFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSExpandedFontMask];
		if( expandedFont )
			theFont = expandedFont;
	}
	
	return theFont;
}


-(NSMutableDictionary*)	textAttributes
{
	NSMutableDictionary*	attrs = [NSMutableDictionary dictionary];
	if( [mTextStyles containsObject: @"shadow"] )
	{
		NSShadow*	theShadow = [[[NSShadow alloc] init] autorelease];
		[theShadow setShadowColor: [NSColor grayColor]];
		[theShadow setShadowBlurRadius: 1.0];
		[theShadow setShadowOffset: NSMakeSize(0.0,-1.0)];
		[attrs setObject: theShadow forKey: NSShadowAttributeName];
		[attrs setObject: [NSNumber numberWithInt: 1.0] forKey: NSStrokeWidthAttributeName];
		[attrs setObject: [NSColor clearColor] forKey: NSForegroundColorAttributeName];
	}
	else if( [mTextStyles containsObject: @"outline"] )
	{
		[attrs setObject: [NSNumber numberWithInt: 1.0] forKey: NSStrokeWidthAttributeName];
		[attrs setObject: [NSColor clearColor] forKey: NSForegroundColorAttributeName];
	}
	else if( [mTextStyles containsObject: @"underline"] )
	{
		[attrs setObject: [NSNumber numberWithInt: NSUnderlineStyleSingle] forKey: NSUnderlineStyleAttributeName];
	}
	else if( [mTextStyles containsObject: @"group"] )
	{
		[attrs setObject: [NSNumber numberWithInt: NSUnderlineStyleThick] forKey: NSUnderlineStyleAttributeName];
		[attrs setObject: [NSColor grayColor] forKey: NSUnderlineColorAttributeName];
	}
	
	NSMutableParagraphStyle*	paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paraStyle setAlignment: mTextAlignment];
	if( mFixedLineHeight )
	{
		[paraStyle setMinimumLineHeight: mTextHeight];
		[paraStyle setMaximumLineHeight: mTextHeight];
	}
	[attrs setObject: paraStyle forKey: NSParagraphStyleAttributeName];
	
	[attrs setObject: [self textFont] forKey: NSFontAttributeName];
	
	return attrs;
}


-(NSTextAlignment)	textAlignment
{
	return mTextAlignment;
}


-(BOOL)	showName
{
	return mShowName;
}


-(BOOL)	isEnabled
{
	return mEnabled;
}


-(BOOL)	visible
{
	return mVisible;
}


-(void)		setVisible: (BOOL)theState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"visible"
															forKey: UKPropagandaAffectedPropertyKey]];
	mVisible = theState;
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"visible"
															forKey: UKPropagandaAffectedPropertyKey]];
}


-(NSInteger)	popupTitleWidth
{
	return mTitleWidth;
}

-(NSInteger)	iconID
{
	return mIconID;
}


-(NSImage*)	iconImage
{
	if( [mType isEqualToString: @"picture"] )
		return [mStack pictureOfType: @"picture" name: mName];
	else if( mIconID == -1 )
		return [mStack pictureOfType: @"picture" name: mName];
	else
		return [mStack pictureOfType: @"icon" id: mIconID];
}


-(BOOL)	wideMargins
{
	return mWideMargins;
}


-(void)	setHighlighted: (BOOL)inState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"highlighted" forKey: UKPropagandaAffectedPropertyKey]];
	mHighlight = inState;
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"highlighted" forKey: UKPropagandaAffectedPropertyKey]];
}


-(BOOL)	highlighted
{
	return mHighlight;
}


-(void)	setAutoHighlight: (BOOL)inState
{
	mAutoHighlight = inState;
}


-(BOOL)	autoHighlight
{
	return mAutoHighlight;
}


-(BOOL)	sharedText
{
	return mSharedText;
}


-(void)	setHighlightedForTracking: (BOOL)inState
{
	mHighlightedForTracking = inState;
}


-(BOOL)	highlightedForTracking
{
	return mHighlightedForTracking;
}


-(NSInteger)	family
{
	return mFamily;
}


-(BOOL)	textLocked
{
	return mLockText;
}


-(void)	setFillColor: (NSColor*)theColor
{
	if( mFillColor != theColor )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"fillColor"
																forKey: UKPropagandaAffectedPropertyKey]];
		[mFillColor release];
		mFillColor = [theColor retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"fillColor"
																forKey: UKPropagandaAffectedPropertyKey]];
	}
}


-(NSColor*)		fillColor
{
	if( !mFillColor )
		return [NSColor whiteColor];
	return mFillColor;
}


-(void)		setBevel: (NSInteger)theBevel
{
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"bevel"
															forKey: UKPropagandaAffectedPropertyKey]];
	mBevel = theBevel;
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"bevel"
															forKey: UKPropagandaAffectedPropertyKey]];
}


-(NSInteger)	bevel
{
	return mBevel;
}


-(NSString*)	script
{
	return mScript;
}


-(void)	setScript: (NSString*)theScript
{
	if( mScript != theScript )
	{
		[mScript release];
		mScript = [theScript retain];
	}
}


-(NSString*)	displayName
{
	NSString*	theFmt = @"part ID %1$d";
	BOOL		haveName = mName && [mName length] > 0;
	BOOL		isField = [mType isEqualToString: @"field"];
	
	if( isField && haveName )
		theFmt = @"field “%2$@” (ID %1$d)";
	else if( isField && !haveName )
		theFmt = @"field ID %1$d";
	else if( !isField && haveName )
		theFmt = @"button “%2$@” (ID %1$d)";
	else if( !isField && !haveName )
		theFmt = @"button ID %1$d";
	
	return [NSString stringWithFormat: theFmt, mID, mName];
}


-(NSImage*)	displayIcon
{
	BOOL		isField = [mType isEqualToString: @"field"];
	
	if( isField )
		return [NSImage imageNamed: @"FieldIconSmall"];
	else
		return [NSImage imageNamed: @"ButtonIconSmall"];
}


-(NSIndexSet*)	selectedListItemIndexes
{
	return mSelectedLines;
}


-(void)	setSelectedListItemIndexes: (NSIndexSet*)newSelection
{
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"selectedListItemIndexes"
															forKey: UKPropagandaAffectedPropertyKey]];
	[mSelectedLines removeAllIndexes];
	[mSelectedLines addIndexes: newSelection];
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"selectedListItemIndexes"
															forKey: UKPropagandaAffectedPropertyKey]];
}


-(BOOL)	autoSelect
{
	return mAutoSelect;
}


-(void)	setAutoSelect: (BOOL)inState
{
	mAutoSelect = inState;
}


-(BOOL)			canSelectMultipleLines
{
	return mMultipleLines;
}


-(void)			setCanSelectMultipleLines: (BOOL)inState
{
	mMultipleLines = inState;
}


-(BOOL)		showLines
{
	return mShowLines;
}


-(NSInteger)	titleWidth
{
	return mTitleWidth;
}


-(BOOL)			fixedLineHeight
{
	return mFixedLineHeight;
}


-(NSInteger)	textHeight
{
	return mTextHeight;
}


-(UKPropagandaStack*)	stack
{
	return mStack;
}


-(void)	updateOnClick: (NSButton*)thePart
{
	[[self partOwner] updatePartOnClick: self];
}


-(BOOL)	searchForPattern: (NSString*)inPattern withContext: (UKPropagandaSearchContext*)inContext
			flags: (UKPropagandaSearchFlags)inFlags
{
	// We only know how to search fields at the moment:
	if( mDontSearch || ![[self partType] isEqualToString: @"field"]
		|| ![self visible] )
	{
		;//NSLog( @"Skipping %@", [self displayName] );
		return NO;
	}
	
	// Fetch the correct text for this field:
	NSString*	myText = nil;
	if( [self sharedText] )
		myText = [[mOwner contentsForPart: self] text];
	else
		myText = [[inContext.currentCard contentsForPart: self] text];
	
	if( [myText length] == 0 )
	{
		//NSLog( @"No text in %@", [self displayName] );
		return NO;
	}
	
	// Are we just starting to search?
	if( inContext.currentPart != self )
	{
		inContext.currentPart = self;
		if( inFlags & UKPropagandaSearchBackwards )
			inContext.currentResultRange = NSMakeRange([myText length], 0);
		else
			inContext.currentResultRange = NSMakeRange(0, 0);
	}
	
	// Determine what text range we still have to search through:
	NSRange searchRange = { 0, 0 };
	if( inFlags & UKPropagandaSearchBackwards )
	{
		searchRange.location = 0;
		searchRange.length = inContext.currentResultRange.location +UKMaximum(0,inContext.currentResultRange.length -1);
	}
	else
	{
		// We advance by 1 only, so searches for "aaa" in "aaaa" give two results:
		searchRange.location = inContext.currentResultRange.location +UKMinimum(1,inContext.currentResultRange.length);
		searchRange.length = [myText length] -searchRange.location;
	}
	
	if( searchRange.length == 0 )
	{
		//NSLog( @"Last result at %@ was already at end", [self displayName] );
		return NO;
	}
	
	// Actually find the string:
	NSStringCompareOptions		compareOptions = 0;
	if( inFlags & UKPropagandaSearchCaseInsensitive )
		compareOptions |= NSCaseInsensitiveSearch;
	if( inFlags & UKPropagandaSearchBackwards )
		compareOptions |= NSBackwardsSearch;
	NSRange foundRange = [myText rangeOfString: inPattern options: compareOptions range: searchRange];
	if( foundRange.location != NSNotFound )
	{
		inContext.currentResultRange = foundRange;
		//NSLog( @"Found %@ in range %@ of %@", NSStringFromRange( foundRange ), NSStringFromRange( searchRange ), [self displayName] );
		return YES;
	}
	else
		;//NSLog( @"Found nothing in %@", [self displayName] );
	
	return NO;
}

@end
