//
//  CButtonPartMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CButtonPartMac.h"
#include "CPartContents.h"
#include "CCard.h"
#include "CStack.h"
#import "WILDViewFactory.h"
#import "WILDButtonView.h"
#import "WILDButtonCell.h"


using namespace Carlson;


static bool	PopUpChunkCallback( const char* currStr, size_t currLen, size_t currStart, size_t currEnd, void* userData )
{
	NSPopUpButton	*	popUp = (NSPopUpButton*)userData;
	NSString	*		itemTitle = [[NSString alloc] initWithBytes: currStr length: currLen encoding:NSUTF8StringEncoding];
	NSMenuItem	*		theItem = [[NSMenuItem alloc] initWithTitle: itemTitle action:Nil keyEquivalent: @""];
	[popUp.menu addItem: theItem];
	[theItem release];
	[itemTitle release];
	
	return true;
}


void	CButtonPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mButtonStyle == EButtonStyleCheckBox )
	{
		mView = [[WILDViewFactory systemButton] retain];
		[mView setBezelStyle: NSRegularSquareBezelStyle];
		[mView setButtonType: NSSwitchButton];
	}
	else if( mButtonStyle == EButtonStyleRadioButton )
	{
		mView = [[WILDViewFactory systemButton] retain];
		[mView setBezelStyle: NSRegularSquareBezelStyle];
		[mView setButtonType: NSRadioButton];
	}
	else if( mButtonStyle == EButtonStyleRectangle )
	{
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSShadowlessSquareBezelStyle];
	}
	else if( mButtonStyle == EButtonStyleOpaque )
	{
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSShadowlessSquareBezelStyle];
		[mView setBordered: NO];
	}
	else if( mButtonStyle == EButtonStyleRoundrect )
	{
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSTexturedRoundedBezelStyle];
		[mView setBordered: NO];
	}
	else if( mButtonStyle == EButtonStyleStandard )
	{
		mView = [[WILDViewFactory systemButton] retain];
		[mView setBezelStyle: NSRoundRectBezelStyle];
		[mView setBordered: NO];
	}
	else if( mButtonStyle == EButtonStyleDefault )
	{
		mView = [[WILDViewFactory systemButton] retain];
		[mView setBezelStyle: NSRoundRectBezelStyle];
		[mView setKeyEquivalent: @"\n"];
		[mView setBordered: NO];
	}
	else if( mButtonStyle == EButtonStyleOval )
	{
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSCircularBezelStyle];
	}
	else if( mButtonStyle == EButtonStylePopUp )
	{
		mView = (WILDButtonView*)[[WILDViewFactory popUpButton] retain];
	}
	else
	{
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSRoundedBezelStyle];
	}
	[mView setFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	if( mButtonStyle == EButtonStylePopUp )
	{
		[(NSPopUpButton*)mView removeAllItems];
		std::string		contentsStr;
		GetTextContents(contentsStr);
		LEODoForEachChunk( contentsStr.c_str(), contentsStr.length(), kLEOChunkTypeLine, PopUpChunkCallback, 0, mView );
	}
	else
	{
		[mView setState: GetHighlight() ? NSOnState : NSOffState];
		[mView setTitle: [NSString stringWithUTF8String: mName.c_str()]];
		[mView setOwningPart: this];
		if( [mView.cell respondsToSelector: @selector(setLineColor:)] )
		{
			[((WILDButtonCell*)mView.cell) setLineColor: [NSColor colorWithCalibratedRed: (mLineColorRed / 65535.0) green: (mLineColorGreen / 65535.0) blue: (mLineColorBlue / 65535.0) alpha:(mLineColorAlpha / 65535.0)]];
			[((WILDButtonCell*)mView.cell) setBackgroundColor: [NSColor colorWithCalibratedRed: (mFillColorRed / 65535.0) green: (mFillColorGreen / 65535.0) blue: (mFillColorBlue / 65535.0) alpha:(mFillColorAlpha / 65535.0)]];
			[((WILDButtonCell*)mView.cell) setLineWidth: mLineWidth];
		}
	}
	[mView setEnabled: mEnabled];
	[inSuperView addSubview: mView];
}


void	CButtonPartMac::SetName( const std::string& inStr )
{
	CButtonPart::SetName(inStr);
	
	if( mButtonStyle != EButtonStylePopUp )
		[mView setTitle: [NSString stringWithUTF8String: mName.c_str()]];
}


void	CButtonPartMac::SetPeeking( bool inState )
{
	ApplyPeekingStateToView(inState, mView);
}


void	CButtonPartMac::SetHighlight( bool inHighlight )
{
	CButtonPart::SetHighlight( inHighlight );
	
	if( mButtonStyle != EButtonStylePopUp )
		[mView setState: inHighlight ? NSOnState : NSOffState];
}


void	CButtonPartMac::DestroyView()
{
	[mView removeFromSuperview];
	mView = nil;
}


