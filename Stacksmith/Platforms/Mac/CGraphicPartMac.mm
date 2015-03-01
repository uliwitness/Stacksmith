//
//  CGraphicPartMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CGraphicPartMac.h"
#include "CStack.h"
#import "UKHelperMacros.h"


using namespace Carlson;


void	CGraphicPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView && mView.superview == inSuperView )
	{
		[mView removeFromSuperview];
		if( mView )
			[inSuperView addSubview: mView];	// Make sure we show up in right layering order.
		return;
	}
	[mView removeFromSuperview];
	DESTROY(mView);
	mView = [[NSView alloc] initWithFrame: NSMakeRect(GetLeft(), GetTop(), GetRight() -GetLeft(), GetBottom() -GetTop())];
	mView.wantsLayer = YES;
	mView.layer.borderColor = NSColor.blackColor.CGColor;
	mView.layer.borderWidth = 1;
	mView.layer.backgroundColor = NSColor.whiteColor.CGColor;
	[inSuperView addSubview: mView];
}


NSImage*	CGraphicPartMac::GetDisplayIcon()
{
	static NSImage*	sGraphicIcon = nil;
	if( !sGraphicIcon )
	{
		sGraphicIcon = [[NSImage imageNamed: @"GraphicIcon"] copy];
		[sGraphicIcon setSize: NSMakeSize(16,16)];
	}
	return sGraphicIcon;
}



void	CGraphicPartMac::DestroyView()
{
	if( mView )
	{
		[mView removeFromSuperview];
		DESTROY(mView);
	}
}


void	CGraphicPartMac::SetRect( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b )
{
	CGraphicPart::SetRect( l, t, r, b );
	[mView setFrame: NSMakeRect(l, t, r-l, b-t)];
	GetStack()->RectChangedOfPart( this );
}

