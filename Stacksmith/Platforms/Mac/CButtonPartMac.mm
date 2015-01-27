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
#include "CDocument.h"
#import "WILDViewFactory.h"
#import "WILDButtonView.h"
#import "WILDButtonCell.h"
#import "WILDPopUpButtonView.h"
#include <sstream>


using namespace Carlson;


static bool	PopUpChunkCallback( const char* currStr, size_t currLen, size_t currStart, size_t currEnd, void* userData )
{
	NSPopUpButton	*	popUp = (NSPopUpButton*)userData;
	NSMenuItem	*		theItem = nil;
	if( currLen == 1 && currStr[0] == '-' )
		theItem = [[NSMenuItem separatorItem] retain];
	else
	{
		NSString	*		itemTitle = [[NSString alloc] initWithBytes: currStr length: currLen encoding:NSUTF8StringEncoding];
		theItem = [[NSMenuItem alloc] initWithTitle: itemTitle action:Nil keyEquivalent: @""];
		[itemTitle release];
	}
	[popUp.menu addItem: theItem];
	[theItem release];
	
	return true;
}


void	CButtonPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView.superview == inSuperView )
	{
		[mView removeFromSuperview];
		[inSuperView addSubview: mView];	// Make sure we show up in right layering order.
		return;
	}
	NSRect		box = NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop);
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
		box = NSInsetRect( box, -2, -2 );
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSShadowlessSquareBezelStyle];
	}
	else if( mButtonStyle == EButtonStyleOpaque )
	{
		box = NSInsetRect( box, -2, -2 );
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSShadowlessSquareBezelStyle];
		[mView setBordered: NO];
	}
	else if( mButtonStyle == EButtonStyleRoundrect )
	{
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSRoundedBezelStyle];
	}
	else if( mButtonStyle == EButtonStyleStandard )
	{
		mView = [[WILDViewFactory systemButton] retain];
		[mView setBezelStyle: NSRoundedBezelStyle];
		box = NSInsetRect( box, -5, -3 );
		box.size.height += 3;
	}
	else if( mButtonStyle == EButtonStyleDefault )
	{
		mView = [[WILDViewFactory systemButton] retain];
		[mView setBezelStyle: NSRoundedBezelStyle];
		[mView setKeyEquivalent: @"\n"];
		box = NSInsetRect( box, -5, -3 );
		box.size.height += 3;
	}
	else if( mButtonStyle == EButtonStyleOval )
	{
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSCircularBezelStyle];
	}
	else if( mButtonStyle == EButtonStylePopUp )
	{
		mView = (WILDButtonView*)[[WILDViewFactory popUpButton] retain];
		box = NSInsetRect( box, -1, 0 );
		box.size.width += 1;
		box.origin.y += 1;
	}
	else
	{
		box = NSInsetRect( box, -2, -2 );
		mView = [[WILDViewFactory shapeButton] retain];
		[mView setBezelStyle: NSShadowlessSquareBezelStyle];
		[mView setBordered: NO];
	}
	[mView setFrame: box];
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	[mView setOwningPart: this];
	[[mView cell] setHighlighted: mHighlightForTracking];
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
		[mView setTitle: mShowName ? [NSString stringWithUTF8String: mName.c_str()] : @""];
		if( [mView.cell respondsToSelector: @selector(setLineColor:)] )
		{
			[((WILDButtonCell*)mView.cell) setLineColor: [NSColor colorWithCalibratedRed: (mLineColorRed / 65535.0) green: (mLineColorGreen / 65535.0) blue: (mLineColorBlue / 65535.0) alpha:(mLineColorAlpha / 65535.0)]];
			if( mButtonStyle == EButtonStyleTransparent )
			{
				[((WILDButtonCell*)mView.cell) setBackgroundColor: nil];
			}
			else
			{
				[((WILDButtonCell*)mView.cell) setBackgroundColor: [NSColor colorWithCalibratedRed: (mFillColorRed / 65535.0) green: (mFillColorGreen / 65535.0) blue: (mFillColorBlue / 65535.0) alpha:(mFillColorAlpha / 65535.0)]];
			}
			[((WILDButtonCell*)mView.cell) setLineWidth: mLineWidth];
		}
	}
	if( mIconID != 0 )
	{
		GetDocument()->GetMediaCache().GetMediaImageByIDOfType( mIconID, EMediaTypeIcon, [this](WILDNSImagePtr theIcon)
		{
			[mView setImage: theIcon];
			[mView setImagePosition: mShowName ? NSImageAbove : NSImageOnly];
			[mView setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		} );
	}
	else if( mButtonStyle != EButtonStyleCheckBox && mButtonStyle != EButtonStyleRadioButton )
		[mView setImagePosition: NSNoImage];
	[mView setEnabled: mEnabled];
	[mView setToolTip: [NSString stringWithUTF8String: mToolTip.c_str()]];
	[inSuperView addSubview: mView];
}


bool	CButtonPartMac::SetTextContents( const std::string &inString )
{
	CButtonPart::SetTextContents( inString );
	
	if( mButtonStyle == EButtonStylePopUp )
	{
		NSInteger	oldSel = [(NSPopUpButton*)mView indexOfSelectedItem];
		[(NSPopUpButton*)mView removeAllItems];
		LEODoForEachChunk( inString.c_str(), inString.length(), kLEOChunkTypeLine, PopUpChunkCallback, 0, mView );
		NSInteger	numItems = [(NSPopUpButton*)mView numberOfItems];
		if( numItems > 0 )
		{
			if( oldSel >= numItems )
				oldSel = numItems -1;
			[(NSPopUpButton*)mView selectItemAtIndex: oldSel];
		}
	}
	
	return true;
}


void	CButtonPartMac::SetStyle( TButtonStyle inButtonStyle )
{
	NSView*	oldSuper = mView.superview;
	DestroyView();
	CButtonPart::SetStyle(inButtonStyle);
	if( oldSuper )
		CreateViewIn( oldSuper );
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


void	CButtonPartMac::SetHighlightForTracking( bool inHighlight )
{
	CButtonPart::SetHighlightForTracking( inHighlight );
	
	[[mView cell] setHighlighted: inHighlight];
	[mView setNeedsDisplay: YES];
}


void	CButtonPartMac::SetFillColor( int r, int g, int b, int a )
{
	CButtonPart::SetFillColor( r, g, b, a );

	[((WILDButtonCell*)mView.cell) setBackgroundColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0]];
}


void	CButtonPartMac::SetLineColor( int r, int g, int b, int a )
{
	CButtonPart::SetLineColor( r, g, b, a );

	[((WILDButtonCell*)mView.cell) setLineColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0]];
}


void	CButtonPartMac::SetShadowColor( int r, int g, int b, int a )
{
	CButtonPart::SetShadowColor( r, g, b, a );
	
	[mView.layer setShadowOpacity: (a == 0) ? 0.0 : 1.0];
	if( a != 0 )
	{
		[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CButtonPartMac::SetShadowOffset( double w, double h )
{
	CButtonPart::SetShadowOffset( w, h );
	
	[mView.layer setShadowOffset: NSMakeSize(w,h)];
}


void	CButtonPartMac::SetShadowBlurRadius( double r )
{
	CButtonPart::SetShadowBlurRadius( r );
	
	[mView.layer setShadowRadius: r];
}


void	CButtonPartMac::SetLineWidth( int w )
{
	CButtonPart::SetLineWidth( w );
	
	[((WILDButtonCell*)mView.cell) setLineWidth: w];
}


void	CButtonPartMac::SetBevelWidth( int bevel )
{
	CButtonPart::SetBevelWidth( bevel );

	[((WILDButtonCell*)mView.cell) setBevelWidth: bevel];
}


void	CButtonPartMac::SetBevelAngle( int a )
{
	CButtonPart::SetBevelAngle( a );

	[((WILDButtonCell*)mView.cell) setBevelAngle: a];
}


void	CButtonPartMac::SetShowName( bool inShowName )
{
	CButtonPart::SetShowName( inShowName );
	
	if( inShowName )
		[mView setTitle: [NSString stringWithUTF8String: GetName().c_str()]];
	else
		[mView setTitle: @""];
	if( mIconID != 0 )
	{
		std::string	iconURL = GetDocument()->GetMediaCache().GetMediaURLByIDOfType( mIconID, EMediaTypeIcon );
		if( iconURL.length() > 0 )
		{
			NSImage*	theIcon = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: iconURL.c_str()]]] autorelease];
			[mView setImagePosition: inShowName ? NSImageAbove : NSImageOnly];
			[mView setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
			[mView setImage: theIcon];
		}
		else if( mButtonStyle != EButtonStyleCheckBox && mButtonStyle != EButtonStyleRadioButton )
		{
			[mView setImagePosition: NSNoImage];
		}
	}
	else if( mButtonStyle != EButtonStyleCheckBox && mButtonStyle != EButtonStyleRadioButton )
	{
		[mView setImagePosition: NSNoImage];
	}
	[mView setNeedsDisplay: YES];
}


void	CButtonPartMac::PrepareMouseUp()
{
	if( mButtonStyle == EButtonStylePopUp )
	{
		mSelectedLines.clear();
		mSelectedLines.insert([(NSPopUpButton*)mView indexOfSelectedItem] +1);
	}
	else
		CButtonPart::PrepareMouseUp();
}


void	CButtonPartMac::ApplyChangedSelectedLinesToView()
{
	CButtonPart::ApplyChangedSelectedLinesToView();
	
	if( mSelectedLines.size() > 0 )
	{
		auto	foundIndex = mSelectedLines.lower_bound(1);
		if( foundIndex != mSelectedLines.end() )
			[(NSPopUpButton*)mView selectItemAtIndex: (*foundIndex) -1];
	}
}


void	CButtonPartMac::DestroyView()
{
	[mView removeFromSuperview];
	mView = nil;
}


void	CButtonPartMac::SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom )
{
	CButtonPart::SetRect( left, top, right, bottom );
	NSRect		box = NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop);
	if( mButtonStyle == EButtonStyleStandard )
	{
		box = NSInsetRect( box, -5, -3 );
		box.size.height += 3;
	}
	else if( mButtonStyle == EButtonStyleDefault )
	{
		box = NSInsetRect( box, -5, -3 );
		box.size.height += 3;
	}
	else if( mButtonStyle == EButtonStylePopUp )
	{
		box = NSInsetRect( box, -1, 0 );
		box.size.width += 1;
		box.origin.y += 1;
	}
	[mView setFrame: box];
	GetStack()->RectChangedOfPart( this );
}


NSView*	CButtonPartMac::GetView()
{
	return mView;
}


void	CButtonPartMac::SetIconID( ObjectID inID )
{
    NSView*	oldSuper = mView.superview;
	
    CButtonPart::SetIconID(inID);

	if( mIconID != 0 )
	{
		std::string	iconURL = GetDocument()->GetMediaCache().GetMediaURLByIDOfType( mIconID, EMediaTypeIcon );
		if( iconURL.length() > 0 )
		{
			NSImage*	theIcon = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: iconURL.c_str()]]]autorelease];
			[mView setImage: theIcon];
			[mView setImagePosition: mShowName ? NSImageAbove : NSImageOnly];
			[mView setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		}
		else if( mButtonStyle != EButtonStyleCheckBox && mButtonStyle != EButtonStyleRadioButton )
		{
			[mView setImagePosition: NSNoImage];
			if( mShowName )
				[mView setTitle: [NSString stringWithUTF8String: GetName().c_str()]];
			else
				[mView setTitle: @""];
		}
	}
	else if( mButtonStyle != EButtonStyleCheckBox && mButtonStyle != EButtonStyleRadioButton )
	{
		[mView setImagePosition: NSNoImage];
		if( mShowName )
			[mView setTitle: [NSString stringWithUTF8String: GetName().c_str()]];
		else
			[mView setTitle: @""];
	}
    else if( mButtonStyle == EButtonStyleCheckBox || mButtonStyle == EButtonStyleRadioButton )
    {
		if( oldSuper )
		{
			DestroyView();
			CreateViewIn( oldSuper );
		}
    }
}


void	CButtonPartMac::SetScript( std::string inScript )
{
	CButtonPart::SetScript( inScript );
	
	[mView updateTrackingAreas];
}



