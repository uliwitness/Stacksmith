//
//  CMacPartBase.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMacPartBase.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDContentsEditorWindowController.h"
#include "CPart.h"


using namespace Carlson;


void	CMacPartBase::OpenScriptEditorAndShowOffset( size_t byteOffset )
{
	if( !mScriptEditor )
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: dynamic_cast<CConcreteObject*>(this)];
	
	[mScriptEditor showWindow: nil];
	if( byteOffset != SIZE_T_MAX )
		[mScriptEditor goToCharacter: byteOffset];
}


void	CMacPartBase::OpenScriptEditorAndShowLine( size_t lineIndex )
{
	if( !mScriptEditor )
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: dynamic_cast<CConcreteObject*>(this)];
	
	[mScriptEditor showWindow: nil];
	if( lineIndex != SIZE_T_MAX )
		[mScriptEditor goToLine: lineIndex];
}


void	CMacPartBase::OpenContentsEditor()
{
	if( !mContentsEditor )
		mContentsEditor = [[WILDContentsEditorWindowController alloc] initWithPart: dynamic_cast<CPart*>(this)];
	[mContentsEditor showWindow: nil];
}


void	CMacPartBase::SetCocoaAttributesForPart( NSDictionary* inAttrs )
{
	CVisiblePart*	myself = dynamic_cast<CVisiblePart*>(this);
	if( !myself )
		return;
	
	NSFont*	theFont = [inAttrs objectForKey: NSFontAttributeName];
	if( !theFont )
		theFont = [NSFont systemFontOfSize: [NSFont systemFontSize]];
	
	TPartTextStyle		textStyle = 0;
	if( [[NSFontManager sharedFontManager] traitsOfFont: theFont] & NSItalicFontMask )
		textStyle |= EPartTextStyleItalic;
	else
	{
		NSNumber*	obliquenessNum = [inAttrs objectForKey: NSObliquenessAttributeName];
		if( obliquenessNum && obliquenessNum.floatValue >= 0.2 )
			textStyle |= EPartTextStyleItalic;
	}

	if( [[NSFontManager sharedFontManager] traitsOfFont: theFont] & NSBoldFontMask )
		textStyle |= EPartTextStyleBold;
	
	myself->SetTextFont( [theFont familyName].UTF8String );
	myself->SetTextSize( theFont.pointSize );
	
	NSNumber*	underlineNum = [inAttrs objectForKey: NSUnderlineStyleAttributeName];
	if( underlineNum && underlineNum.integerValue == NSUnderlineStyleSingle )
		textStyle |= EPartTextStyleUnderline;
	
	NSNumber*	outlineNum = [inAttrs objectForKey: NSStrokeWidthAttributeName];
	if( outlineNum && outlineNum.integerValue <= -3.0 )
		textStyle |= EPartTextStyleOutline;
	
	if( [inAttrs objectForKey: NSShadowAttributeName] )
		textStyle |= EPartTextStyleShadow;
	
	if( [inAttrs objectForKey: NSLinkAttributeName] )
		textStyle |= EPartTextStyleGroup;
	
	NSNumber*	kerningNum = [inAttrs objectForKey: NSKernAttributeName];
	if( kerningNum && kerningNum.integerValue < 0 )
		textStyle |= EPartTextStyleCondensed;
	else if( kerningNum && kerningNum.integerValue > 0 )
		textStyle |= EPartTextStyleExtended;
	
	myself->SetTextStyle( textStyle );
	
	NSColor*	textColor = [[inAttrs objectForKey: NSForegroundColorAttributeName] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	if( textColor )
	{
		myself->SetTextColor( textColor.redComponent * 65535.0, textColor.greenComponent * 65535.0, textColor.blueComponent * 65535.0, textColor.alphaComponent * 65535.0 );
	}
	
	//NSLog( @"New Attrs: %s %d %u", myself->GetTextFont().c_str(), myself->GetTextSize(), textStyle );
}


NSDictionary*	CMacPartBase::GetCocoaAttributesForPart()
{
	CVisiblePart*			myself = dynamic_cast<CVisiblePart*>(this);
	NSMutableDictionary	*	styles = [NSMutableDictionary dictionary];
	NSFont	*				theFont = nil;
	CGFloat					fontSize = myself->GetTextSize();
	if( fontSize < 0 )
		fontSize = [NSFont systemFontSize];
	if( myself->GetTextFont().length() > 0 )
		theFont = [NSFont fontWithName: [NSString stringWithUTF8String: myself->GetTextFont().c_str()] size: fontSize];
	if( !theFont )
		theFont = [NSFont systemFontOfSize: fontSize];
	TPartTextStyle			styleFlags = myself->GetTextStyle();
	
	if( styleFlags & EPartTextStyleBold )
	{
		NSFont*	newFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSBoldFontMask];
		if( newFont )
			theFont = newFont;
	}
	if( styleFlags & EPartTextStyleItalic )
	{
		NSFont*	newFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSItalicFontMask];
		if( newFont && [[NSFontManager sharedFontManager] traitsOfFont: newFont] & NSItalicFontMask )
		{
			theFont = newFont;
		}
		else
		{
			[styles setObject: @(0.5) forKey: NSObliquenessAttributeName];
		}

	}
	if( styleFlags & EPartTextStyleUnderline )
	{
		[styles setObject: @(NSUnderlineStyleSingle) forKey: NSUnderlineStyleAttributeName];
	}
	if( styleFlags & EPartTextStyleOutline )
	{
		[styles setObject: @-3.0 forKey: NSStrokeWidthAttributeName];
	}
	if( styleFlags & EPartTextStyleShadow )
	{
		NSShadow*	textShadow = [[[NSShadow alloc] init] autorelease];
		[textShadow setShadowColor: NSColor.blackColor];
		[textShadow setShadowOffset: NSMakeSize(1,1)];
		[styles setObject: textShadow forKey: NSShadowAttributeName];
	}
	if( styleFlags & EPartTextStyleCondensed )
		[styles setObject: @(-3.0) forKey: NSKernAttributeName];
	if( styleFlags & EPartTextStyleExtended )
		[styles setObject: @(3.0) forKey: NSKernAttributeName];
	if( styleFlags & EPartTextStyleGroup )
		[styles setObject: [NSURL URLWithString: @"http://#"] forKey: NSLinkAttributeName];
	
	if( theFont )
	[styles setObject: theFont forKey: NSFontAttributeName];
	
	if( myself->GetTextColorRed() >= 0 )
	{
		[styles setObject: [NSColor colorWithCalibratedRed: myself->GetTextColorRed() / 65535.0 green: myself->GetTextColorGreen() / 65535.0 blue: myself->GetTextColorBlue() / 65535.0 alpha: myself->GetTextColorAlpha() / 65535.0] forKey: NSForegroundColorAttributeName];
	}
	
	//NSLog( @"Styles: %@", styles );
	
	return styles;
}


NSAutoresizingMaskOptions	CMacPartBase::GetCocoaResizeFlags( TPartLayoutFlags inFlags )
{
	// NB: HyperCard starts coordinates at top left, Cocoa generally starts them
	//	at the lower left, so the top is actually the highest Y coordinate for Cocoa.
	
	NSAutoresizingMaskOptions	cocoaFlags = 0;
	switch( PART_H_LAYOUT_MODE(inFlags) )
	{
		case EPartLayoutAlignLeft:
			cocoaFlags |= NSViewMaxXMargin;
			break;
		case EPartLayoutAlignHBoth:
			cocoaFlags |= NSViewWidthSizable;
			break;
		case EPartLayoutAlignHCenter:
			cocoaFlags |= NSViewMaxXMargin | NSViewMinXMargin;
			break;
		case EPartLayoutAlignRight:
			cocoaFlags |= NSViewMinXMargin;
			break;
	}
	switch( PART_V_LAYOUT_MODE(inFlags) )
	{
		case EPartLayoutAlignTop:
			cocoaFlags |= NSViewMaxYMargin;	// Cocoa coords start in lower left.
			break;
		case EPartLayoutAlignVBoth:
			cocoaFlags |= NSViewHeightSizable;
			break;
		case EPartLayoutAlignVCenter:
			cocoaFlags |= NSViewMaxYMargin | NSViewMinYMargin;
			break;
		case EPartLayoutAlignBottom:
			cocoaFlags |= NSViewMinYMargin;	// Cocoa coords start in lower left.
			break;
	}
	return cocoaFlags;
}


void	CMacPartBase::WillBeDeleted()
{
	DestroyView();
	
	
}


