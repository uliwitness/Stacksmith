//
//  WILDPart.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDPart.h"
#import "WILDXMLUtils.h"
#import "WILDLayer.h"
#import "WILDCard.h"
#import "WILDStack.h"
#import "WILDPartContents.h"
#import "WILDNotifications.h"
#import "Forge.h"
#import "LEORemoteDebugger.h"
#import "ULINSIntegerMath.h"
#import "UKHelperMacros.h"
#import "WILDDocument.h"
#import "WILDPresentationConstants.h"
#import "UKHelperMacros.h"


@interface WILDPart ()
{
	NSFont	*	mFont;
	NSTimer	*	mTimer;
}

@end


@implementation WILDPart

@synthesize dontWrap = mDontWrap;
@synthesize autoTab = mAutoTab;
@synthesize dontSearch = mDontSearch;
@synthesize lockText = mLockText;
@synthesize wideMargins = mWideMargins;
@synthesize fixedLineHeight = mFixedLineHeight;
@synthesize showLines = mShowLines;
@synthesize sharedText = mSharedText;
@synthesize controllerVisible = mControllerVisible;
@synthesize mediaPath = mMediaPath;
@synthesize currentTime = mCurrentTime;
@synthesize hasHorizontalScroller = mHasHorizontalScroller;
@synthesize hasVerticalScroller = mHasVerticalScroller;
@synthesize lineColor = mLineColor;
@synthesize fillColor = mFillColor;
@synthesize shadowColor = mShadowColor;
@synthesize shadowOffset = mShadowOffset;
@synthesize shadowBlurRadius = mShadowBlurRadius;
@synthesize clickableInInactiveWindow = mClickableInInactiveWindow;
@synthesize lineWidth = mLineWidth;
@synthesize stack = mStack;
@synthesize currentURL = mCurrentURL;
@synthesize statusMessage = mStatusMessage;
@synthesize bevel = mBevel;
@synthesize bevelAngle = mBevelAngle;
@synthesize timerMessage = mTimerMessage;
@synthesize timerInterval = mTimerInterval;


-(id)	initWithXMLElement: (NSXMLElement*)elem forStack: (WILDStack*)inStack
{
	if(( self = [super init] ))
	{
		mStack = inStack;
		mID = WILDIntegerFromSubElementInElement( @"id", elem );
		mHammerRectangle = WILDRectFromSubElementInElement( @"rect", elem );
		mName = [WILDStringFromSubElementInElement( @"name", elem ) retain];
		mMediaPath = [WILDStringFromSubElementInElement( @"mediaPath", elem ) retain];
		mScript = [WILDStringFromSubElementInElement( @"script", elem ) retain];
		mStyle = [WILDStringFromSubElementInElement( @"style", elem ) retain];
		mType = [WILDStringFromSubElementInElement( @"type", elem ) retain];
		mVisible = (!elem) ? YES : WILDBoolFromSubElementInElement( @"visible", elem, YES );
		mDontWrap = WILDBoolFromSubElementInElement( @"dontWrap", elem, NO );
		mDontSearch = WILDBoolFromSubElementInElement( @"dontSearch", elem, NO );
		mSharedText = WILDBoolFromSubElementInElement( @"sharedText", elem, NO );
		mFixedLineHeight = WILDBoolFromSubElementInElement( @"fixedLineHeight", elem, NO );
		mAutoTab = WILDBoolFromSubElementInElement( @"autoTab", elem, NO );
		mLockText = WILDBoolFromSubElementInElement( @"lockText", elem, NO );
		mAutoSelect = WILDBoolFromSubElementInElement( @"autoSelect", elem, NO );
		mShowLines = WILDBoolFromSubElementInElement( @"showLines", elem, NO );
		mAutoHighlight = WILDBoolFromSubElementInElement( @"autoHighlight", elem, NO );
		mWideMargins = WILDBoolFromSubElementInElement( @"wideMargins", elem, NO );
		mMultipleLines = WILDBoolFromSubElementInElement( @"multipleLines", elem, NO );
		mShowName = WILDBoolFromSubElementInElement( @"showName", elem, ([mType isEqualToString: @"button"] ? YES : NO) );
		mSelectedLines = [WILDIndexSetFromSubElementInElement( @"selectedLines", elem, -1 ) mutableCopy];
		mTitleWidth = WILDIntegerFromSubElementInElement( @"titleWidth", elem );
		mHighlight = WILDBoolFromSubElementInElement( @"highlight", elem, NO );
		mSharedHighlight = WILDBoolFromSubElementInElement( @"sharedHighlight", elem, YES );
		mEnabled = WILDBoolFromSubElementInElement( @"enabled", elem, YES );
		mHasHorizontalScroller = WILDBoolFromSubElementInElement( @"hasHorizontalScroller", elem, NO );
		mHasVerticalScroller = WILDBoolFromSubElementInElement( @"hasVerticalScroller", elem, NO );
		mFamily = WILDIntegerFromSubElementInElement( @"family", elem );
		NSString	* timeString = WILDStringFromSubElementInElement( @"currentTime", elem );
		if( timeString )
			mCurrentTime = QTTimeFromString( timeString );
		mClickableInInactiveWindow = WILDBoolFromSubElementInElement( @"clickableInInactiveWindow", elem, ([mType isEqualToString: @"button"] ? YES : NO) );
		
		NSString*		alignStr = WILDStringFromSubElementInElement( @"textAlign", elem );
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
		
		mTextFontName = [WILDStringFromSubElementInElement( @"font", elem ) retain];
		mTextFontSize = WILDIntegerFromSubElementInElement( @"textSize", elem );
		mTextHeight = WILDIntegerFromSubElementInElement( @"textHeight", elem );
		mTextStyles = [WILDStringsFromSubElementInElement( @"textStyle", elem ) retain];
		mIconID = WILDIntegerFromSubElementInElement( @"icon", elem );
		mControllerVisible = WILDBoolFromSubElementInElement( @"controllerVisible", elem, NO );
		NSString	*	theURLString = WILDStringFromSubElementInElement( @"currentURL", elem );
		if( theURLString && theURLString.length > 0 )
			mCurrentURL = [[NSURL alloc] initWithString: theURLString];
		
		mFillColor = [WILDColorFromSubElementInElement( @"fillColor", elem ) retain];
		if( !mFillColor )
			mFillColor = [[NSColor whiteColor] retain];
		mLineColor = [WILDColorFromSubElementInElement( @"lineColor", elem ) retain];
		if( !mLineColor )
			mLineColor = [[NSColor blackColor] retain];
		mShadowColor = [WILDColorFromSubElementInElement( @"shadowColor", elem ) retain];
		if( !mShadowColor )
			mShadowColor = [[NSColor clearColor] retain];
		mShadowOffset = WILDSizeFromSubElementInElement( @"shadowOffset", elem );
		mShadowBlurRadius = WILDIntegerFromSubElementInElement( @"shadowBlurRadius", elem );
		if( mShadowBlurRadius < 0 )
			mShadowBlurRadius = 0;
		mLineWidth = WILDIntegerFromSubElementInElement( @"lineWidth", elem );
		if( mLineWidth < 0 )
			mLineWidth = 0;
		mBevel = WILDIntegerFromSubElementInElement( @"bevelWidth", elem );
		if( mBevel < 0 )
			mBevel = 0;
		mBevelAngle = WILDIntegerFromSubElementInElement( @"bevelAngle", elem );
		if( mBevelAngle < 0 )
			mBevelAngle = 0;
		mTimerMessage = [WILDStringFromSubElementInElement( @"message", elem ) retain];
		mTimerInterval = WILDIntegerFromSubElementInElement( @"interval", elem );
		
		NSError *	err = nil;
		NSArray	*	userPropsNodes = [elem nodesForXPath: @"userProperties" error: &err];
		if( userPropsNodes.count > 0 )
		{
			NSString		*	lastKey = nil;
			NSString		*	lastValue = nil;
			NSXMLElement	*	userPropsNode = [userPropsNodes objectAtIndex: 0];
			for( NSXMLElement* currChild in userPropsNode.children )
			{
				if( [currChild.name isEqualToString: @"name"] )
					lastKey = currChild.stringValue;
				if( !lastValue && [currChild.name isEqualToString: @"value"] )
					lastValue = currChild.stringValue;
				if( lastKey && lastValue )
				{
					if( !mUserProperties )
						mUserProperties = [[NSMutableDictionary alloc] init];
					[mUserProperties setObject: lastValue forKey: lastKey];
					lastValue = lastKey = nil;
				}
				if( lastValue && !lastKey )
					lastValue = nil;
			}
		}
		
		NSArray*		parts = [elem elementsForName: @"part"];
		if( parts.count > 0 )
			mSubParts = [[NSMutableArray alloc] initWithCapacity: [parts count]];
		for( NSXMLElement* currPart in parts )
		{
			WILDPart*	newPart = [[[WILDPart alloc] initWithXMLElement: currPart forStack: mStack] autorelease];
			[newPart setPartLayer: [self partLayer]];
			[newPart setPartOwner: mOwner];
			[newPart setOwningPart: self];
			[mSubParts addObject: newPart];
			[mOwner registerPart: newPart];
		}
		
		mIDForScripts = kLEOObjectIDINVALID;
	}
	
	return self;
}


-(void)	dealloc
{
	for( WILDPart* currPart in mSubParts )
		[mOwner unregisterPart: currPart];

	DESTROY_DEALLOC(mName);
	DESTROY_DEALLOC(mScript);
	DESTROY_DEALLOC(mStyle);
	DESTROY_DEALLOC(mType);
	DESTROY_DEALLOC(mLayer);
	DESTROY_DEALLOC(mTextFontName);
	DESTROY_DEALLOC(mTextStyles);
	DESTROY_DEALLOC(mFillColor);
	DESTROY_DEALLOC(mLineColor);
	DESTROY_DEALLOC(mShadowColor);
	DESTROY_DEALLOC(mMediaPath);
	DESTROY_DEALLOC(mFont);
	DESTROY_DEALLOC(mUserProperties);
	DESTROY_DEALLOC(mTimerMessage);
	
	mStack = UKInvalidPointer;
	DESTROY_DEALLOC(mCurrentURL);
	
	if( mScriptObject )
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
	
	if( mIDForScripts != kLEOObjectIDINVALID )
	{
		LEOCleanUpValue( &mValueForScripts, kLEOInvalidateReferences, NULL );
		mIDForScripts = kLEOObjectIDINVALID;
	}
	
	[super dealloc];
}


-(NSArray*)		subParts
{
	return mSubParts;
}


-(NSArray *)	writableTypesForPasteboard:	(NSPasteboard *)pasteboard
{
	return @[WILDPartPboardType];
}


-(BOOL)	toggleHighlightAfterTracking
{
	return [mStyle isEqualToString: @"checkbox"] || [mStyle isEqualToString: @"radiobutton"]
			 || mFamily != 0;
}


-(void)	setHammerRectangle: (NSRect)theBox
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"hammerRectangle"
																forKey: WILDAffectedPropertyKey]];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"quartzRectangle"
																forKey: WILDAffectedPropertyKey]];
	mHammerRectangle = theBox;
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"quartzRectangle"
																forKey: WILDAffectedPropertyKey]];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"hammerRectangle"
																forKey: WILDAffectedPropertyKey]];
}


-(NSRect)	hammerRectangle
{
	return mHammerRectangle;
}


-(NSRect)	quartzRectangle
{
	NSRect		resultRect = mHammerRectangle;
	CGFloat		ownerHeight = 0;
	if( self.owningPart )
		ownerHeight = [self.owningPart hammerRectangle].size.height;
	else
		ownerHeight = [mStack cardSize].height;
	resultRect.origin.y = ownerHeight -NSMaxY( mHammerRectangle );
	return resultRect;
}


-(void)	setQuartzRectangle: (NSRect)theBox
{
	CGFloat		ownerHeight = 0;
	if( self.owningPart )
		ownerHeight = [self.owningPart hammerRectangle].size.height;
	else
		ownerHeight = [mStack cardSize].height;
	theBox.origin.y = ownerHeight -NSMaxY( theBox );
	[self setHammerRectangle: theBox];
}


-(void)	setName: (NSString*)theStr
{
	if( mName != theStr )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"name"
																forKey: WILDAffectedPropertyKey]];
		[mName release];
		mName = [theStr retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"name"
																forKey: WILDAffectedPropertyKey]];
		[self updateChangeCount: NSChangeDone];
	}
}


-(NSString*)	name
{
	return mName;
}


-(NSString*)	partStyle
{
	return mStyle;
}


-(void)	setPartStyle: (NSString*)theStyle
{
	if( mStyle != theStyle )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: PROPERTY(partStyle)
																forKey: WILDAffectedPropertyKey]];
		[mStyle release];
		mStyle = [theStyle retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: PROPERTY(partStyle)
																forKey: WILDAffectedPropertyKey]];
		[self updateChangeCount: NSChangeDone];
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


-(WILDObjectID)	partID
{
	return mID;
}


-(void)	setPartID: (WILDObjectID)inID
{
	mID = inID;
}


-(NSInteger)	partNumber
{
	if( self.owningPart )
		return [self.owningPart indexOfPart: self asType: nil];
	else
		return [mOwner indexOfPart: self asType: nil];
}


-(void)	ensureIDIsUniqueInLayer: (WILDLayer*)inLayer
{
	if( [inLayer partWithID: mID] != nil )
		mID = [inLayer uniqueIDForPart];
}


-(void)		ensureSubPartIDsAreUniqueInLayer: (WILDLayer*)inLayer;
{
	for( WILDPart* subPart in mSubParts )
	{
		[subPart ensureIDIsUniqueInLayer: inLayer];
		[subPart ensureSubPartIDsAreUniqueInLayer: inLayer];
	}
}


-(WILDPart*)	subPartWithID: (WILDObjectID)theID
{
	for( WILDPart* thePart in mSubParts )
	{
		if( [thePart partID] == theID )
			return thePart;
		WILDPart	*	subPart = [thePart subPartWithID: theID];
		if( subPart )
			return subPart;
	}
	
	return nil;
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


-(void)	setPartOwner: (WILDLayer*)cardOrBg
{
	WILDLayer	*	oldOwner = mOwner;
	
	mOwner = cardOrBg;
	for( WILDPart* currPart in mSubParts )
	{
		[oldOwner unregisterPart: currPart];
		[currPart setPartOwner: mOwner];
		[currPart setOwningPart: self];
		[mOwner registerPart: currPart];
	}
}


-(WILDLayer*)	partOwner
{
	return mOwner;
}


-(NSUInteger)	indexOfPart: (WILDPart*)inPart asType: (NSString*)inPartType
{
	if( inPartType == nil )
		return [mSubParts indexOfObject: inPart];
	else
	{
		NSUInteger		partIdx = 0;
		for( WILDPart* currPart in mSubParts )
		{
			if( [[currPart partType] isEqualToString: inPartType] )
			{
				if( currPart == inPart )
					return partIdx;
				++partIdx;
			}
		}
	}
	
	return NSNotFound;
}


-(NSFont*)	textFont
{
	if( !mFont )
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
		ASSIGN(mFont,theFont);
	}
	
	return mFont;
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


-(void)		setShowName: (BOOL)theState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"showName"
															forKey: WILDAffectedPropertyKey]];
	mShowName = theState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"showName"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(void)		setStatusMessage:(NSString *)statusMessage
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"statusMessage"
															forKey: WILDAffectedPropertyKey]];
	ASSIGNCOPY(mStatusMessage,statusMessage);
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"statusMessage"
															forKey: WILDAffectedPropertyKey]];
}


-(BOOL)	isEnabled
{
	return mEnabled;
}


-(void)		setEnabled: (BOOL)theState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"enabled"
															forKey: WILDAffectedPropertyKey]];
	mEnabled = theState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"enabled"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)	visible
{
	return mVisible;
}


-(void)		setVisible: (BOOL)theState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"visible"
															forKey: WILDAffectedPropertyKey]];
	mVisible = theState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"visible"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(void)	setIconID: (WILDObjectID)theID
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"icon"
															forKey: WILDAffectedPropertyKey]];
	mIconID = theID;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"icon"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(WILDObjectID)	iconID
{
	return mIconID;
}


-(NSImage*)	iconImage
{
	if( [mType isEqualToString: @"picture"] )
		return [[mStack document] pictureOfType: @"picture" name: mName];
	else if( mIconID == -1 )
		return [[mStack document] pictureOfType: @"picture" name: mName];
	else if( mIconID == 0 )
		return nil;
	else
		return [[mStack document] pictureOfType: @"icon" id: mIconID];
}


-(BOOL)	wideMargins
{
	return mWideMargins;
}


-(void)	setHighlighted: (BOOL)inState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"highlighted" forKey: WILDAffectedPropertyKey]];
	mHighlight = inState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"highlighted" forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)	highlighted
{
	return mHighlight;
}


-(void)	setAutoHighlight: (BOOL)inState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"autoHighlight" forKey: WILDAffectedPropertyKey]];
	mAutoHighlight = inState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"autoHighlight" forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)	autoHighlight
{
	return mAutoHighlight;
}


-(BOOL)	sharedText
{
	return mSharedText;
}


-(BOOL)	sharedHighlight
{
	return mSharedHighlight;
}


-(void)	setSharedHighlight: (BOOL)inState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"sharedHighlight" forKey: WILDAffectedPropertyKey]];
	mSharedHighlight = inState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"sharedHighlight" forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
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


-(void)	setFamily: (NSInteger)inFamilyNumber
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"family" forKey: WILDAffectedPropertyKey]];
	mFamily = inFamilyNumber;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"family" forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(void)	setCurrentURL: (NSURL *)currentURL
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"currentURL" forKey: WILDAffectedPropertyKey]];
	ASSIGN(mCurrentURL, currentURL);
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"currentURL" forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(void)	setFillColor: (NSColor*)theColor
{
	if( mFillColor != theColor )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"fillColor"
																forKey: WILDAffectedPropertyKey]];
		[mFillColor release];
		mFillColor = [theColor retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"fillColor"
																forKey: WILDAffectedPropertyKey]];
		[self updateChangeCount: NSChangeDone];
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
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"bevel"
															forKey: WILDAffectedPropertyKey]];
	mBevel = theBevel;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"bevel"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(NSInteger)	bevel
{
	return mBevel;
}


-(void)		setBevelAngle: (NSInteger)theBevel
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"bevelAngle"
															forKey: WILDAffectedPropertyKey]];
	mBevelAngle = theBevel;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"bevelAngle"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(NSInteger)	bevelAngle
{
	return mBevelAngle;
}


-(NSString*)	script
{
	return mScript;
}


-(void)	setScript: (NSString*)theScript
{
	ASSIGN(mScript,theScript);
	if( mScriptObject )
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
}


-(NSString*)	defaultScriptReturningSelectionRange: (NSRange*)outSelection
{
	NSString	*	outScript = @"";
	
	if( [mType isEqualToString: @"button"] )
	{
		outScript = @"on mouseUp\n\t\nend mouseUp";
		
		if( outSelection )
		{
			outSelection->location = 12;	// Behind tab on middle line.
			outSelection->length = 0;
		}
	}
	
	return outScript;
}


-(struct LEOScript*)	scriptObjectShowingErrorMessage: (BOOL)showError
{
	if( !mScriptObject )
	{
		const char*		scriptStr = [mScript UTF8String];
		uint16_t		fileID = LEOFileIDForFileName( [[self displayName] UTF8String] );
		LEOParseTree*	parseTree = LEOParseTreeCreateFromUTF8Characters( scriptStr, strlen(scriptStr), fileID );
		if( LEOParserGetLastErrorMessage() == NULL )
		{
			if( mIDForScripts == kLEOObjectIDINVALID )
			{
				WILDInitObjectValue( &mValueForScripts, self, kLEOInvalidateReferences, NULL );
				mIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( [mStack scriptContextGroupObject], &mValueForScripts );
				mSeedForScripts = LEOContextGroupGetSeedForObjectID( [mStack scriptContextGroupObject], mIDForScripts );
			}
			mScriptObject = LEOScriptCreateForOwner( mIDForScripts, mSeedForScripts, WILDGetParentScript );
			LEOScriptCompileAndAddParseTree( mScriptObject, [mStack scriptContextGroupObject], parseTree, fileID );
			
			#if REMOTE_DEBUGGER
			LEORemoteDebuggerAddFile( scriptStr, fileID, mScriptObject );
			
			// Set a breakpoint on the mouseUp handler:
//			LEOHandlerID handlerName = LEOContextGroupHandlerIDForHandlerName( [mStack scriptContextGroupObject], "mouseup" );
//			LEOHandler* theHandler = LEOScriptFindCommandHandlerWithID( mScriptObject, handlerName );
//			if( theHandler )
//				LEORemoteDebuggerAddBreakpoint( theHandler->instructions );
			#endif
		}
		if( LEOParserGetLastErrorMessage() )
		{
			if( showError )
				NSRunAlertPanel( @"Script Error", @"%@", @"OK", @"", @"", [NSString stringWithCString: LEOParserGetLastErrorMessage() encoding: NSUTF8StringEncoding] );
			if( mScriptObject )
			{
				LEOScriptRelease( mScriptObject );
				mScriptObject = NULL;
			}
		}
	}
	
	return mScriptObject;
}


-(id<WILDObject>)	parentObject
{
	return mOwner;
}


-(struct LEOContextGroup*)	scriptContextGroupObject
{
	return [[mStack document] scriptContextGroupObject];
}


-(NSString*)	displayName
{
	NSString*	theFmt = @"part ID %1$d";
	BOOL		haveName = mName && [mName length] > 0;
	BOOL		isField = [mType isEqualToString: @"field"];
	BOOL		isPlayer = [mType isEqualToString: @"moviePlayer"];
	BOOL		isBrowser = [mType isEqualToString: @"browser"];
	
	if( isField && haveName )
		theFmt = @"field “%2$@” (ID %1$d)";
	else if( isField && !haveName )
		theFmt = @"field ID %1$d";
	else if( isPlayer && haveName )
		theFmt = @"movie player “%2$@” (ID %1$d)";
	else if( isField && !haveName )
		theFmt = @"movie player ID %1$d";
	else if( isBrowser && haveName )
		theFmt = @"browser “%2$@” (ID %1$d)";
	else if( isBrowser && !haveName )
		theFmt = @"browser ID %1$d";
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
// Don't notify from here, gets called when the object is created & causes endless recursion.
//	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
//							object: self userInfo: [NSDictionary dictionaryWithObject: @"selectedListItemIndexes"
//															forKey: WILDAffectedPropertyKey]];
	[mSelectedLines removeAllIndexes];
	[mSelectedLines addIndexes: newSelection];
//	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
//							object: self userInfo: [NSDictionary dictionaryWithObject: @"selectedListItemIndexes"
//															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)	autoSelect
{
	return mAutoSelect;
}


-(void)	setAutoSelect: (BOOL)inState
{
	[self updateChangeCount: NSChangeDone];
	mAutoSelect = inState;
}


-(BOOL)	canSelectMultipleLines
{
	return mMultipleLines;
}


-(void)			setCanSelectMultipleLines: (BOOL)inState
{
	mMultipleLines = inState;
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)		showLines
{
	return mShowLines;
}


-(CGFloat)	titleWidth
{
	if( mTitleWidth < 0 )
		return 0;
	return mTitleWidth;
}


-(BOOL)		canHaveTitleWidth
{
	return [mType isEqualToString: @"button"] && [mStyle isEqualToString: @"popup"];
}


-(void)	setTitleWidth: (CGFloat)inWidth
{
	mTitleWidth = inWidth;
}


-(BOOL)			fixedLineHeight
{
	return mFixedLineHeight;
}


-(NSInteger)	textHeight
{
	return mTextHeight;
}


-(WILDStack*)	stack
{
	return mStack;
}


-(void)	updateViewOnClick: (NSView*)sender withCard: (WILDCard*)inCard background: (WILDBackground*)inBackground
{
	if( [mStyle isEqualToString: @"popup"] )
		[self setSelectedListItemIndexes: [NSIndexSet indexSetWithIndex: [(NSPopUpButton*)sender indexOfSelectedItem]]];
	
	[[self partOwner] updatePartOnClick: self withCard: inCard background: inBackground];

	if( [mStyle isEqualToString: @"popup"] )
		WILDScriptContainerResultFromSendingMessage( self, @"mouseUp" );
}


-(BOOL)	searchForPattern: (NSString*)inPattern withContext: (WILDSearchContext*)inContext
			flags: (WILDSearchFlags)inFlags
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
		if( inFlags & WILDSearchBackwards )
			inContext.currentResultRange = NSMakeRange([myText length], 0);
		else
			inContext.currentResultRange = NSMakeRange(0, 0);
	}
	
	// Determine what text range we still have to search through:
	NSRange searchRange = { 0, 0 };
	if( inFlags & WILDSearchBackwards )
	{
		searchRange.location = 0;
		searchRange.length = inContext.currentResultRange.location +ULINSIntegerMaximum(0,inContext.currentResultRange.length -1);
	}
	else
	{
		// We advance by 1 only, so searches for "aaa" in "aaaa" give two results:
		searchRange.location = inContext.currentResultRange.location +ULINSIntegerMinimum(1,inContext.currentResultRange.length);
		searchRange.length = [myText length] -searchRange.location;
	}
	
	if( searchRange.length == 0 )
	{
		//NSLog( @"Last result at %@ was already at end", [self displayName] );
		return NO;
	}
	
	// Actually find the string:
	NSStringCompareOptions		compareOptions = 0;
	if( inFlags & WILDSearchCaseInsensitive )
		compareOptions |= NSCaseInsensitiveSearch;
	if( inFlags & WILDSearchBackwards )
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


-(void)	updateChangeCount: (NSDocumentChangeType)inChange
{
	[mOwner updateChangeCount: inChange];
}


-(WILDPartContents*)	currentPartContentsAndBackgroundContents: (WILDPartContents**)outBgContents create: (BOOL)inDoCreate onCard: (WILDCard*)inCard forBackgroundEditing: (BOOL)isBgEditing
{
	WILDBackground*		theBg = [inCard owningBackground];
	WILDPartContents*	contents = nil;
	WILDPartContents*	bgContents = nil;
	bgContents = [theBg contentsForPart: self create: inDoCreate];
	if( [self sharedText] )
		contents = bgContents;
	else
		contents = isBgEditing ? nil : [inCard contentsForPart: self create: inDoCreate];
	
	if( outBgContents )
		*outBgContents = bgContents;
	
	return contents;
}


-(NSString*)	xmlString
{
	NSMutableString*	outString = [[[NSMutableString alloc] init] autorelease];
	
	[outString appendString: @"\t<part>\n"];
	
	WILDAppendLongLongXML( outString, 2, mID, @"id" );
	WILDAppendStringXML( outString, 2, [self partType], @"type" );
	WILDAppendStringXML( outString, 2, mLayer, @"layer" );
	WILDAppendBoolXML( outString, 2, mVisible, @"visible" );
	WILDAppendBoolXML( outString, 2, mEnabled, @"enabled" );
	WILDAppendRectXML( outString, 2, mHammerRectangle, @"rect" );
	WILDAppendStringXML( outString, 2, [self partStyle], @"style" );
	WILDAppendBoolXML( outString, 2, mShowName, @"showName" );
	WILDAppendBoolXML( outString, 2, mHighlight, @"highlight" );
	WILDAppendBoolXML( outString, 2, mAutoHighlight, @"autoHighlight" );
	WILDAppendBoolXML( outString, 2, mSharedHighlight, @"sharedHighlight" );
	WILDAppendLongXML( outString, 2, mFamily, @"family" );
	WILDAppendLongXML( outString, 2, mTitleWidth, @"titleWidth" );
	WILDAppendLongLongXML( outString, 2, mIconID, @"icon" );

	WILDAppendBoolXML( outString, 2, mDontWrap, @"dontWrap" );
	WILDAppendBoolXML( outString, 2, mDontSearch, @"dontSearch" );
	WILDAppendBoolXML( outString, 2, mSharedText, @"sharedText" );
	WILDAppendBoolXML( outString, 2, mFixedLineHeight, @"fixedLineHeight" );
	WILDAppendBoolXML( outString, 2, mAutoTab, @"autoTab" );
	WILDAppendBoolXML( outString, 2, mLockText, @"lockText" );
	WILDAppendBoolXML( outString, 2, mAutoSelect, @"autoSelect" );
	WILDAppendBoolXML( outString, 2, mMultipleLines, @"multipleLines" );
	WILDAppendBoolXML( outString, 2, mShowLines, @"showLines" );
	WILDAppendBoolXML( outString, 2, mWideMargins, @"wideMargins" );
	WILDAppendStringXML( outString, 2, QTStringFromTime(mCurrentTime), @"currentTime" );
	WILDAppendBoolXML( outString, 2, mControllerVisible, @"controllerVisible" );
	WILDAppendStringXML( outString, 2, mCurrentURL ? mCurrentURL.absoluteString	: @"", @"currentURL" );
	
	WILDAppendColorXML( outString, 2, mFillColor, @"fillColor" );
	WILDAppendColorXML( outString, 2, mLineColor, @"lineColor" );
	WILDAppendColorXML( outString, 2, mShadowColor, @"shadowColor" );
	WILDAppendSizeXML( outString, 2, mShadowOffset, @"shadowOffset" );
	WILDAppendLongXML( outString, 2, mShadowBlurRadius, @"shadowBlurRadius" );
	WILDAppendLongXML( outString, 2, mLineWidth, @"lineWidth" );
	WILDAppendLongXML( outString, 2, mBevel, @"bevelWidth" );
	WILDAppendLongXML( outString, 2, mBevelAngle, @"bevelAngle" );
	WILDAppendLongXML( outString, 2, mTimerInterval, @"interval" );
	WILDAppendStringXML( outString, 2, mTimerMessage, @"message" );
	
	if( [mSelectedLines count] > 0 )
	{
		[outString appendString: @"\t\t<selectedLines>\n"];
		NSInteger	lineIdx = [mSelectedLines firstIndex];
		do
		{
			WILDAppendLongXML( outString, 3, lineIdx +1, @"integer" );
		}
		while( (lineIdx = [mSelectedLines indexGreaterThanIndex: lineIdx]) != NSNotFound );
		[outString appendString: @"\t\t</selectedLines>\n"];
	}
	
	NSString*	textAlignment = @"left";
	if( mTextAlignment == NSCenterTextAlignment )
		textAlignment = @"center";
	if( mTextAlignment == NSRightTextAlignment )
		textAlignment = @"right";
	WILDAppendStringXML( outString, 2, textAlignment, @"textAlign" );
	WILDAppendStringXML( outString, 2, mTextFontName, @"font" );
	WILDAppendLongXML( outString, 2, mTextFontSize, @"textSize" );
	for( NSString* styleName in mTextStyles )
		WILDAppendStringXML( outString, 2, styleName, @"textStyle" );
	WILDAppendBoolXML( outString, 2, mHasHorizontalScroller, @"hasHorizontalScroller" );
	WILDAppendBoolXML( outString, 2, mHasVerticalScroller, @"hasVerticalScroller" );
	
	WILDAppendStringXML( outString, 2, mName, @"name" );
	if( [mMediaPath length] > 0 )
		WILDAppendStringXML( outString, 2, mMediaPath, @"mediaPath" );

	WILDAppendStringXML( outString, 2, mScript, @"script" );
	
	[outString appendString: @"\t\t<userProperties>\n"];
	for( NSString *userPropName in [[mUserProperties allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)] )
	{
		WILDAppendStringXML( outString, 3, userPropName, @"name" );
		WILDAppendStringXML( outString, 3, mUserProperties[userPropName], @"value" );
	}
	[outString appendString: @"\t\t</userProperties>\n"];
	
	for( WILDPart* currPart in mSubParts )
	{
		[outString appendString: [currPart xmlString]];
	}
	
	[outString appendString: @"\t</part>\n"];
	
	return outString;
}


-(NSString*)	textContents
{
	WILDCard*			theCard = [[self stack] currentCard];
	WILDPartContents*	bgContents = nil;
	WILDPartContents*	contents = nil;
	
	contents = [self currentPartContentsAndBackgroundContents: &bgContents create: NO onCard: theCard forBackgroundEditing: NO];
	if( !contents || !contents.text )
		return @"";
	return [contents text];
}


-(BOOL)	setTextContents: (NSString*)inString
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"text"
															forKey: WILDAffectedPropertyKey]];
	
	WILDCard*			theCard = [[self stack] currentCard];
	WILDPartContents*	bgContents = nil;
	WILDPartContents*	contents = nil;
	
	contents = [self currentPartContentsAndBackgroundContents: &bgContents create: YES onCard: theCard forBackgroundEditing: NO];
	[contents setText: inString];

	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"text"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
	
	return YES;
}


-(BOOL)	goThereInNewWindow: (BOOL)inNewWindow
{
	return NO;
}


-(id)	valueForWILDPropertyNamed: (NSString*)inPropertyName ofRange: (NSRange)byteRange
{
	id	theValue = [super valueForWILDPropertyNamed: inPropertyName ofRange: byteRange];
	if( theValue )
		return theValue;
	
	if( [inPropertyName isEqualToString: @"selectedline"] )
	{
		NSUInteger	selectedIndex = [[self selectedListItemIndexes] firstIndex];
		if( selectedIndex == NSNotFound )
			selectedIndex = 0;
		else
			selectedIndex += 1;
		return [NSNumber numberWithLongLong: selectedIndex];
	}
	else if( [inPropertyName isEqualToString: @"selectedlines"] )
	{
		NSMutableDictionary	* selectedLines = [NSMutableDictionary dictionaryWithCapacity: [[self selectedListItemIndexes] count]];
		
		NSUInteger	x = 0;
		NSUInteger	currIdx = [[self selectedListItemIndexes] firstIndex];
		while( currIdx != NSNotFound )
		{
			[selectedLines setObject: [NSNumber numberWithInteger: currIdx +1] forKey: [NSString stringWithFormat: @"%llu",(unsigned long long)++x]];
			
			currIdx = [[self selectedListItemIndexes] indexGreaterThanIndex: currIdx];
		}
		
		return selectedLines;
	}
	else if( [inPropertyName isEqualToString: @"textstyle"] )
	{
		WILDCard*			theCard = [[self stack] currentCard];
		WILDPartContents*	bgContents = nil;
		WILDPartContents*	contents = nil;
		
		contents = [self currentPartContentsAndBackgroundContents: &bgContents create: NO onCard: theCard forBackgroundEditing: NO];
		NSMutableAttributedString	*	styledText = [[[contents styledTextForPart: self] mutableCopy] autorelease];
		if( !styledText )
			styledText = [[[NSMutableAttributedString alloc] initWithString: contents.text] autorelease];
		NSRange		realRange = { 0, 0 };
		NSDictionary *attrs = [styledText attributesAtIndex: byteRange.location longestEffectiveRange: &realRange inRange: byteRange];
		if( (realRange.length +realRange.location) < (byteRange.length +byteRange.location)
			|| realRange.location > byteRange.location )
		{
			return @"mixed";
		}
		else
		{
			if( attrs[NSObliquenessAttributeName] )
				return @"italic";
			else if( attrs[NSUnderlineStyleAttributeName] )
				return @"underline";
			else
				return @"plain";
		}
	}
	
	return nil;
}


-(NSString*)	validatedStyle: (NSString*)userStyle
{
	if( ![userStyle isKindOfClass: [NSString class]] )
		return mStyle;
	static NSDictionary*	sValidStyles = nil;
	if( !sValidStyles )
		sValidStyles = [[NSDictionary alloc] initWithObjectsAndKeys:
										@"transparent", @"transparent",
										@"opaque", @"opaque",
										@"rectangle", @"rectangle",
										@"roundrect", @"roundrect",
										@"shadow", @"shadow",
										@"scrolling", @"scrolling",
										@"checkbox", @"checkbox",
										@"radiobutton", @"radiobutton",
										@"standard", @"standard",
										@"default", @"default",
										@"oval", @"oval",
										@"popup", @"popup",
										nil];
	userStyle = [sValidStyles objectForKey: [userStyle lowercaseString]];
	if( !userStyle )
		return mStyle;
	return userStyle;
}


-(BOOL)		setValue: (id)inValue forWILDPropertyNamed: (NSString*)inPropertyName inRange: (NSRange)byteRange
{
	if( ![super setValue: inValue forWILDPropertyNamed: inPropertyName inRange: byteRange] )
	{
		BOOL	propExists = YES;
		
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: inPropertyName
																forKey: WILDAffectedPropertyKey]];
		if( [inPropertyName isEqualToString: @"textstyle"] )
		{
			[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
									object: self userInfo: [NSDictionary dictionaryWithObject: @"text"
																	forKey: WILDAffectedPropertyKey]];
			
			WILDCard*			theCard = [[self stack] currentCard];
			WILDPartContents*	bgContents = nil;
			WILDPartContents*	contents = nil;
			
			contents = [self currentPartContentsAndBackgroundContents: &bgContents create: NO onCard: theCard forBackgroundEditing: NO];
			NSMutableAttributedString	*	styledText = [[[contents styledTextForPart: self] mutableCopy] autorelease];
			if( !styledText )
				styledText = [[[NSMutableAttributedString alloc] initWithString: contents.text] autorelease];
			if( [inValue isEqualToString: @"italic"] )
				[styledText setAttributes: @{ NSObliquenessAttributeName: @0.5 } range: byteRange];
			else
				[styledText removeAttribute: NSObliquenessAttributeName range: byteRange];
			if( [inValue isEqualToString: @"underline"] )
				[styledText setAttributes: @{ NSUnderlineStyleAttributeName: @(NSUnderlineStyleThick) } range: byteRange];
			else
				[styledText removeAttribute: NSUnderlineStyleAttributeName range: byteRange];
			[contents setStyledText: styledText];
			
			[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
									object: self userInfo: [NSDictionary dictionaryWithObject: @"text"
																	forKey: WILDAffectedPropertyKey]];
			[self updateChangeCount: NSChangeDone];
		}

		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: inPropertyName
																forKey: WILDAffectedPropertyKey]];
		if( propExists )
			[self updateChangeCount: NSChangeDone];
		
		return propExists;
	}
	return YES;
}


-(NSString*)	propertyWillChangeNotificationName
{
	return WILDPartWillChangeNotification;
}


-(NSString*)	propertyDidChangeNotificationName
{
	return WILDPartDidChangeNotification;
}


-(void)	setStyleString: (NSString*)inValue
{
	[self setPartStyle: [self validatedStyle: inValue]];
}


-(NSString*)	styleString
{
	return mStyle;
}


-(NSString*)	currentURLString
{
	return mCurrentURL ? mCurrentURL.absoluteString : @"";
}


-(void)	setCurrentURLString: (NSString*)inString
{
	self.currentURL = (inString.length > 0) ? [NSURL URLWithString: inString] : nil;
}


-(void)	setRectangleDictionary: (NSDictionary*)inDict
{
	NSRect		newRect = NSZeroRect;
	newRect.origin.x = [[inDict objectForKey: @"left"] doubleValue];
	newRect.origin.y = [[inDict objectForKey: @"top"] doubleValue];
	newRect.size.width = [[inDict objectForKey: @"right"] doubleValue] -newRect.origin.x;
	newRect.size.height = [[inDict objectForKey: @"bottom"] doubleValue] -newRect.origin.y;
	[self setHammerRectangle: newRect];
}


-(NSDictionary*)	rectangleDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble: mHammerRectangle.origin.x], @"left",
			[NSNumber numberWithDouble: mHammerRectangle.origin.y], @"top",
			[NSNumber numberWithDouble: NSMaxX(mHammerRectangle)], @"right",
			[NSNumber numberWithDouble: NSMaxY(mHammerRectangle)], @"bottom",
			nil];
}


-(void)	setFillColorDictionary: (NSDictionary*)inValue
{
	CGFloat		redComponent = [[inValue objectForKey: @"red"] doubleValue];
	CGFloat		greenComponent = [[inValue objectForKey: @"green"] doubleValue];
	CGFloat		blueComponent = [[inValue objectForKey: @"blue"] doubleValue];
	NSNumber*	alphaComponentObj = [inValue objectForKey: @"alpha"];
	CGFloat		alphaComponent = alphaComponentObj ? [alphaComponentObj doubleValue] : 1.0;
	[self setFillColor: [NSColor colorWithCalibratedRed: redComponent green: greenComponent blue: blueComponent alpha: alphaComponent]];
}


-(NSDictionary*)	fillColorDictionary
{
	NSColor	*	rgbColor = [[self fillColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble: [rgbColor redComponent]], @"red",
			[NSNumber numberWithDouble: [rgbColor greenComponent]], @"green",
			[NSNumber numberWithDouble: [rgbColor blueComponent]], @"blue",
			[NSNumber numberWithDouble: [rgbColor alphaComponent]], @"alpha",
			nil];
}


-(void)	setLineColorDictionary: (NSDictionary*)inValue
{
	CGFloat		redComponent = [[inValue objectForKey: @"red"] doubleValue];
	CGFloat		greenComponent = [[inValue objectForKey: @"green"] doubleValue];
	CGFloat		blueComponent = [[inValue objectForKey: @"blue"] doubleValue];
	NSNumber*	alphaComponentObj = [inValue objectForKey: @"alpha"];
	CGFloat		alphaComponent = alphaComponentObj ? [alphaComponentObj doubleValue] : 1.0;
	[self setLineColor: [NSColor colorWithCalibratedRed: redComponent green: greenComponent blue: blueComponent alpha: alphaComponent]];
}


-(NSDictionary*)	lineColorDictionary
{
	NSColor	*	rgbColor = [[self lineColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble: [rgbColor redComponent]], @"red",
			[NSNumber numberWithDouble: [rgbColor greenComponent]], @"green",
			[NSNumber numberWithDouble: [rgbColor blueComponent]], @"blue",
			[NSNumber numberWithDouble: [rgbColor alphaComponent]], @"alpha",
			nil];
}


-(void)	setShadowColorDictionary: (NSDictionary*)inValue
{
	CGFloat		redComponent = [[inValue objectForKey: @"red"] doubleValue];
	CGFloat		greenComponent = [[inValue objectForKey: @"green"] doubleValue];
	CGFloat		blueComponent = [[inValue objectForKey: @"blue"] doubleValue];
	NSNumber*	alphaComponentObj = [inValue objectForKey: @"alpha"];
	CGFloat		alphaComponent = alphaComponentObj ? [alphaComponentObj doubleValue] : 1.0;
	[self setShadowColor: [NSColor colorWithCalibratedRed: redComponent green: greenComponent blue: blueComponent alpha: alphaComponent]];
}


-(NSDictionary*)	shadowColorDictionary
{
	NSColor	*	rgbColor = [[self shadowColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble: [rgbColor redComponent]], @"red",
			[NSNumber numberWithDouble: [rgbColor greenComponent]], @"green",
			[NSNumber numberWithDouble: [rgbColor blueComponent]], @"blue",
			[NSNumber numberWithDouble: [rgbColor alphaComponent]], @"alpha",
			nil];
}


-(void)	setShadowOffsetDictionary: (NSDictionary*)inValue
{
	CGFloat		h = [[inValue objectForKey: @"horizontal"] doubleValue];
	CGFloat		v = [[inValue objectForKey: @"vertical"] doubleValue];
	mShadowOffset = NSMakeSize(h,v);
}


-(NSDictionary*)	shadowOffsetDictionary
{
	NSSize	shadowOffset = self.shadowOffset;
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble: shadowOffset.width], @"horizontal",
			[NSNumber numberWithDouble: shadowOffset.height], @"vertical",
			nil];
}


-(void)	setPartNumberForScripts: (NSInteger)desiredIndex
{
	if( desiredIndex > 0 )
		[mOwner movePart: self toIndex: desiredIndex -1 asType: nil];
}


-(NSInteger)	partNumberForScripts
{
	return [mOwner indexOfPart: self asType: nil];
}


-(void)	setNumberForScripts: (NSInteger)desiredIndex
{
	if( desiredIndex > 0 )
		[mOwner movePart: self toIndex: desiredIndex -1 asType: self.partType];
}


-(NSInteger)	numberForScripts
{
	return [mOwner indexOfPart: self asType: self.partType];
}


PROPERTY_MAP_START
PROPERTY_MAPPING(name,"name",kLeoValueTypeString)
PROPERTY_MAPPING(name,"short name",kLeoValueTypeString)
PROPERTY_MAPPING(parentObject,"owner",kLeoValueTypeWILDObject)
PROPERTY_MAPPING(rectangleDictionary,"rectangle",kLeoValueTypeArray)
PROPERTY_MAPPING(partID,"id",kLeoValueTypeInteger)
PROPERTY_MAPPING(partNumber,"number",kLeoValueTypeInteger)
PROPERTY_MAPPING(fillColorDictionary,"fillcolor",kLeoValueTypeArray)
PROPERTY_MAPPING(lineColorDictionary,"linecolor",kLeoValueTypeArray)
PROPERTY_MAPPING(shadowColorDictionary,"shadowcolor",kLeoValueTypeArray)
PROPERTY_MAPPING(shadowOffsetDictionary,"shadowoffset",kLeoValueTypeArray)
PROPERTY_MAPPING(shadowBlurRadius,"shadowblurradius",kLeoValueTypeNumber)
PROPERTY_MAPPING(visible,"visible",kLeoValueTypeBoolean)
PROPERTY_MAPPING(dontWrap,"dontwrap",kLeoValueTypeBoolean)
PROPERTY_MAPPING(dontSearch,"dontsearch",kLeoValueTypeBoolean)
PROPERTY_MAPPING(sharedText,"sharedtext",kLeoValueTypeBoolean)
PROPERTY_MAPPING(fixedLineHeight,"fixedlineheight",kLeoValueTypeBoolean)
PROPERTY_MAPPING(autoTab,"autotab",kLeoValueTypeBoolean)
PROPERTY_MAPPING(lockText,"locktext",kLeoValueTypeBoolean)
PROPERTY_MAPPING(autoSelect,"autoselect",kLeoValueTypeBoolean)
PROPERTY_MAPPING(showLines,"showlines",kLeoValueTypeBoolean)
PROPERTY_MAPPING(autoHighlight,"autohighlight",kLeoValueTypeBoolean)
PROPERTY_MAPPING(highlighted,"highlight",kLeoValueTypeBoolean)
PROPERTY_MAPPING(sharedHighlight,"sharedhighlight",kLeoValueTypeBoolean)
PROPERTY_MAPPING(wideMargins,"widemargins",kLeoValueTypeBoolean)
PROPERTY_MAPPING(canSelectMultipleLines,"multiplelines",kLeoValueTypeBoolean)
PROPERTY_MAPPING(showName,"showname",kLeoValueTypeBoolean)
PROPERTY_MAPPING(enabled,"enabled",kLeoValueTypeBoolean)
PROPERTY_MAPPING(highlightedForTracking,"highlightedfortracking",kLeoValueTypeBoolean)
PROPERTY_MAPPING(script,"script",kLeoValueTypeString)
PROPERTY_MAPPING(styleString,"style",kLeoValueTypeString)
PROPERTY_MAPPING(mediaPath,"moviepath",kLeoValueTypeString)
PROPERTY_MAPPING(controllerVisible,"controllervisible",kLeoValueTypeBoolean)
PROPERTY_MAPPING(icon,"icon",kLeoValueTypeInteger)
PROPERTY_MAPPING(lineWidth,"linewidth",kLeoValueTypeInteger)
PROPERTY_MAPPING(bevel,"bevelwidth",kLeoValueTypeInteger)
PROPERTY_MAPPING(bevelAngle,"bevelangle",kLeoValueTypeInteger)
PROPERTY_MAPPING(numberForScripts,"number",kLeoValueTypeInteger)
PROPERTY_MAPPING(partNumberForScripts,"partnumber",kLeoValueTypeInteger)
PROPERTY_MAPPING(currentURLString,"currenturl",kLeoValueTypeString)
PROPERTY_MAPPING(statusMessage,"statusmessage",kLeoValueTypeString)
PROPERTY_MAPPING(timerMessage,"message",kLeoValueTypeString)
PROPERTY_MAPPING(timerInterval,"interval",kLeoValueTypeNumber)
PROPERTY_MAP_END


-(BOOL)	deleteWILDObject
{
	[mOwner deletePart: self];
	
	return YES;
}


-(void)	addUserPropertyNamed: (NSString*)userPropName
{
	if( !mUserProperties )
		mUserProperties = [[NSMutableDictionary alloc] init];
	if( ![mUserProperties objectForKey: userPropName] )
	{
		[mUserProperties setObject: @"" forKey: userPropName];
		[self updateChangeCount: NSChangeDone];
	}
}


-(void)	deleteUserPropertyNamed: (NSString*)userPropName
{
	if( [mUserProperties objectForKey: userPropName] )
	{
		[mUserProperties removeObjectForKey: userPropName];
		[self updateChangeCount: NSChangeDone];
	}
}


-(NSMutableArray*)	allUserProperties
{
	NSMutableArray	*	allProps = [NSMutableArray arrayWithCapacity: mUserProperties.count];
	for( NSString * theKey in mUserProperties )
	{
		[allProps addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: theKey, WILDUserPropertyNameKey, mUserProperties[theKey], WILDUserPropertyValueKey, nil]];
	}
	return allProps;
}


-(void)	setValue: (NSString*)inValue forUserPropertyNamed: (NSString*)inName oldName: (NSString*)inOldName
{
	if( inOldName )
		[mUserProperties removeObjectForKey: inOldName];
	if( !mUserProperties )
		mUserProperties = [[NSMutableDictionary alloc] init];
	[mUserProperties setObject: inValue forKey: inName];
	[self updateChangeCount: NSChangeDone];
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ { layer = %@, type = %@, style = %@, name = %@, id = %lld, path = %@ }", NSStringFromClass([self class]), mLayer, mType, mStyle, mName, mID, mMediaPath];	
}

@end
