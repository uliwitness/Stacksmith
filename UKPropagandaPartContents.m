//
//  UKPropagandaPartContents.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaPartContents.h"
#import "UKPropagandaXMLUtils.h"
#import "UKPropagandaStack.h"
#import "UKPropagandaPart.h"


@interface UKPropagandaStyleRun : NSObject
{
	NSRange		styleRange;
	NSString*	fontName;
	CGFloat		fontSize;
	NSArray*	styles;
	NSInteger	styleID;
}

@property (assign)	NSRange		styleRange;
@property (copy)	NSString*	fontName;
@property (assign)	CGFloat		fontSize;
@property (copy)	NSArray*	styles;
@property (assign)	NSInteger	styleID;

@end


@implementation UKPropagandaStyleRun

@synthesize	styleRange;
@synthesize	fontName;
@synthesize	fontSize;
@synthesize	styles;
@synthesize	styleID;

-(void)	dealloc
{
	[fontName release];
	fontName = nil;
	[styles release];
	styles = nil;
	
	[super dealloc];
}

@end




@implementation UKPropagandaPartContents

-(id)	initWithXMLElement: (NSXMLElement*)theElem forStack: (UKPropagandaStack*)theStack
{
	if(( self = [super init] ))
	{
		mText = [UKPropagandaStringFromSubElementInElement( @"text", theElem ) retain];
		mID = UKPropagandaIntegerFromSubElementInElement( @"id", theElem );
		mLayer = [UKPropagandaStringFromSubElementInElement( @"layer", theElem ) retain];
		mHighlighted = UKPropagandaBoolFromSubElementInElement( @"highlight", theElem );
		
		// Style runs contain their start offsets, so we apply them from the end,
		//	to be able to start with the length as the end offset, and then just
		//	use each start offset as the end of the next run:
		NSArray*		styleRuns = [theElem elementsForName: @"stylerun"];
		if( styleRuns && [styleRuns count] > 0 )
		{
			NSInteger	startOffset = 0, endOffset = [mText length];
			for( NSXMLElement * currentRun in [styleRuns reverseObjectEnumerator] )
			{
				NSString*	offsetStr = [[[currentRun elementsForName: @"offset"] objectAtIndex: 0] stringValue];
				NSString*	styleIDStr = [[[currentRun elementsForName: @"id"] objectAtIndex: 0] stringValue];
				startOffset = [offsetStr integerValue];
				NSInteger	styleID = [styleIDStr integerValue];
				NSString*	fontName = nil;
				NSInteger	fontSize = -1;
				NSArray*	styles = nil;
				
				[theStack provideStyleFormatWithID: styleID font: &fontName size: &fontSize styles: &styles];
				
				UKPropagandaStyleRun*	currStyleRun = [[UKPropagandaStyleRun alloc] init];
				NSRange					txRange = { startOffset, endOffset -startOffset };
				currStyleRun.styleID = styleID;
				currStyleRun.fontName = fontName;
				currStyleRun.fontSize = fontSize;
				currStyleRun.styles = styles;
				currStyleRun.styleRange = txRange;
				[mStyles addObject: currStyleRun];
				[currStyleRun release];
				
				endOffset = startOffset;
			}
		}
	}
	
	return self;
}


-(void)	dealloc
{
	[mListItems release];
	mListItems = nil;
	[mText release];
	mText = nil;
	[mLayer release];
	mLayer = nil;
	[mStyledText release];
	mStyledText = nil;
	[mStyles release];
	mStyles = nil;
	
	[super dealloc];
}


-(NSString*)	text
{
	return mText;
}


-(void)	setText: (NSString*)inString
{
	[mText release];
	mText = [inString copy];
	[mStyledText release];
	mStyledText = nil;
	[mStyles release];
	mStyles = nil;
	[mListItems release];
	mListItems = nil;
}


-(NSAttributedString*)	styledTextForPart: (UKPropagandaPart*)currPart
{
	if( !mStyledText )
	{
		NSDictionary*	attrs = [currPart textAttributes];
		if( !attrs )
			attrs = [NSDictionary dictionary];
		mStyledText = [[NSMutableAttributedString alloc] initWithString: mText attributes: attrs];
		
		// Apply alignment and fixed line height, if any, across the whole field:
		NSMutableParagraphStyle*	paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[paraStyle setAlignment: [currPart textAlignment]];
		if( [currPart fixedLineHeight] )
		{
			[paraStyle setMinimumLineHeight: [currPart textHeight]];
			[paraStyle setMaximumLineHeight: [currPart textHeight]];
		}
		[mStyledText addAttribute: NSParagraphStyleAttributeName value: paraStyle range: NSMakeRange(0,[mStyledText length])];
		
		// Apply actual style ranges:
		for( UKPropagandaStyleRun* styleRun in mStyles )
		{
			BOOL		needsItalicStyle = NO;

			NSFont*		theFont = [NSFont fontWithName: styleRun.fontName size: styleRun.fontSize];
			if( !theFont && ([styleRun.fontName isEqualToString: @"Chicago"] || [styleRun.fontName isEqualToString: @"Charcoal"]) )
				theFont = [NSFont boldSystemFontOfSize: styleRun.fontSize];
			if( !theFont )
				theFont = [NSFont fontWithName: @"Geneva" size: styleRun.fontSize];
			if( !theFont )
				theFont = [NSFont userFontOfSize: styleRun.fontSize];

			if( [styleRun.styles containsObject: @"bold"] )
			{
				NSFont*	boldFont = [[NSFontManager sharedFontManager] convertWeight: YES ofFont: theFont];
				if( !boldFont || boldFont == theFont )
					boldFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSBoldFontMask];
				if( boldFont )
					theFont = boldFont;
			}

			if( [styleRun.styles containsObject: @"italic"] )
			{
				NSFont*	italicFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSItalicFontMask];
				if( italicFont && italicFont != theFont )
					theFont = italicFont;
				else
					needsItalicStyle = YES;
			}

			if( [styleRun.styles containsObject: @"condense"] )
			{
				NSFont*	condensedFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSCondensedFontMask];
				if( condensedFont )
					theFont = condensedFont;
			}

			if( [styleRun.styles containsObject: @"extend"] )
			{
				NSFont*	expandedFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSExpandedFontMask];
				if( expandedFont )
					theFont = expandedFont;
			}

			[mStyledText addAttribute: NSFontAttributeName value: theFont range: styleRun.styleRange];
			
			if( [styleRun.styles containsObject: @"shadow"] )
			{
				NSShadow*	theShadow = [[[NSShadow alloc] init] autorelease];
				[theShadow setShadowColor: [NSColor grayColor]];
				[theShadow setShadowBlurRadius: 1.0];
				[theShadow setShadowOffset: NSMakeSize(0.0,-1.0)];
				[mStyledText addAttribute: NSShadowAttributeName value: theShadow range: styleRun.styleRange];
				[mStyledText addAttribute: NSStrokeWidthAttributeName value: [NSNumber numberWithInt: 1.0] range: styleRun.styleRange];
				[mStyledText addAttribute: NSForegroundColorAttributeName value: [NSColor clearColor] range: styleRun.styleRange];
			}
			else if( [styleRun.styles containsObject: @"outline"] )
			{
				[mStyledText addAttribute: NSStrokeWidthAttributeName value: [NSNumber numberWithInt: 1.0] range: styleRun.styleRange];
				[mStyledText addAttribute: NSForegroundColorAttributeName value: [NSColor clearColor] range: styleRun.styleRange];
			}
			else if( [styleRun.styles containsObject: @"underline"] )
			{
				[mStyledText addAttribute: NSUnderlineStyleAttributeName value: [NSNumber numberWithInt: NSUnderlineStyleSingle] range: styleRun.styleRange];
			}
			else if( [styleRun.styles containsObject: @"group"] )
			{
				[mStyledText addAttribute: NSUnderlineStyleAttributeName value: [NSNumber numberWithInt: NSUnderlineStyleThick] range: styleRun.styleRange];
				[mStyledText addAttribute: NSUnderlineColorAttributeName value: [NSColor grayColor] range: styleRun.styleRange];
			}
			if( needsItalicStyle )
				[mStyledText addAttribute: NSObliquenessAttributeName value: [NSNumber numberWithFloat: 0.5] range: styleRun.styleRange];
		}
	}
	
	return mStyledText;
}


-(NSString*)	partLayer
{
	return mLayer;
}


-(NSInteger)	partID
{
	return mID;
}


-(BOOL)	highlighted
{
	return mHighlighted;
}


-(void)					setHighlighted: (BOOL)inState
{
	mHighlighted = inState;
}


-(NSArray*)	listItems
{
	if( !mListItems )
	{
		mListItems = [[mText componentsSeparatedByString: @"\n"] retain];	// +++
		//NSLog( @"%d: %@", [mListItems count], mListItems );
	}
	
	return mListItems;
}

@end
