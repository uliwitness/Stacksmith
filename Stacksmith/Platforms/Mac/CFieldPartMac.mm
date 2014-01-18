//
//  CFieldPartMac.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CFieldPartMac.h"
#include "CPartContents.h"
#import "WILDViewFactory.h"


using namespace Carlson;


void	CFieldPartMac::CreateViewIn( NSView* inSuperView )
{
	mView = [[WILDViewFactory textField] retain];
	CPartContents*	contents = GetContentsOnCurrentCard();
	if( contents )
	{
		CAttributedString&		cppstr = contents->GetAttributedText();
		NSAttributedString*		attrStr = GetCocoaAttributedString( &cppstr, GetCocoaAttributesForPart() );
		if( cppstr.GetString().find("{\\rtf1\\ansi\\") == 0 )	// +++ Remove before shipping, this is to import old Stacksmith beta styles.
		{
			NSDictionary*	docAttrs = nil;
			attrStr = [[NSAttributedString alloc] initWithRTF: [NSData dataWithBytes: cppstr.GetString().c_str() length: cppstr.GetString().length()] documentAttributes: &docAttrs];
		}
		[mView setAttributedStringValue: attrStr];
	}
	else
		[mView setStringValue: @""];
	[mView setFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	[inSuperView addSubview: mView];
}


NSDictionary*	CFieldPartMac::GetCocoaAttributesForPart()
{
	NSMutableDictionary	*	styles = [NSMutableDictionary dictionary];
	NSFont	*				theFont = nil;
	CGFloat					fontSize = mTextSize;
	if( fontSize < 0 )
		fontSize = [NSFont systemFontSize];
	if( mFont.length() > 0 )
		theFont = [NSFont fontWithName: [NSString stringWithUTF8String: mFont.c_str()] size: fontSize];
	else
		theFont = [NSFont systemFontOfSize: fontSize];
	
	if( mTextStyle & EPartTextStyleBold )
	{
		NSFont*	newFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSBoldFontMask];
		if( newFont )
			theFont = newFont;
	}
	if( mTextStyle & EPartTextStyleItalic )
	{
		NSFont*	newFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSItalicFontMask];
		if( newFont )
			theFont = newFont;
	}
	if( mTextStyle & EPartTextStyleUnderline )
	{
		[styles setObject: @(NSUnderlineStyleSingle) forKey: NSUnderlineStyleAttributeName];
	}
	if( mTextStyle & EPartTextStyleOutline )
	{
		[styles setObject: @3.0 forKey: NSStrokeWidthAttributeName];
	}
	[styles setObject: theFont forKey: NSFontAttributeName];
	
	return styles;
}


NSAttributedString	*	CFieldPartMac::GetCocoaAttributedString( CAttributedString * attrStr, NSDictionary * defaultAttrs )
{
	NSMutableAttributedString	*	newAttrStr = [[[NSMutableAttributedString alloc] initWithString: [NSString stringWithUTF8String: attrStr->GetString().c_str()] attributes: defaultAttrs] autorelease];
	attrStr->ForEachRangeDo([newAttrStr](CAttributeRange *currRange, const std::string &txt)
	{
		if( currRange )
		{
			NSRange	currCocoaRange = { currRange->mStart, currRange->mEnd -currRange->mStart };
			
			// +++ Convert UTF8 to UTF16 range!
			
			for( auto currStyle : currRange->mAttributes )
			{
				if( currStyle.first.compare("text-decoration") == 0 && currStyle.second.compare("underline") == 0 )
				{
					[newAttrStr addAttribute: NSUnderlineStyleAttributeName value: @(NSUnderlineStyleSingle) range: currCocoaRange];
				}
				else if( currStyle.first.compare("text-style") == 0 && currStyle.second.compare("italic") == 0 )
				{
//					[newAttrStr addAttribute: NSUnderlineStyleAttributeName value: @(NSUnderlineStyleSingle) range: currCocoaRange];
				}
				else if( currStyle.first.compare("font-weight") == 0 && currStyle.second.compare("bold") == 0 )
				{
//					[newAttrStr addAttribute: NSUnderlineStyleAttributeName value: @(NSUnderlineStyleSingle) range: currCocoaRange];
				}
				else if( currStyle.first.compare("font-family") == 0 )
				{
//					[newAttrStr addAttribute: NSUnderlineStyleAttributeName value: @(NSUnderlineStyleSingle) range: currCocoaRange];
				}
				else if( currStyle.first.compare("font-size") == 0 )
				{
//					[newAttrStr addAttribute: NSUnderlineStyleAttributeName value: @(NSUnderlineStyleSingle) range: currCocoaRange];
				}
			}
		}
	});
	return newAttrStr;
}