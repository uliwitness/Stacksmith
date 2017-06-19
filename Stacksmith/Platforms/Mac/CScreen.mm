//
//  CScreen.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2017-06-19.
//  Copyright (c) 2017 Uli Kusterer. All rights reserved.
//

#include "CScreen.h"
#import <Cocoa/Cocoa.h>


using namespace Carlson;


static NSRect	WILDFlippedScreenRect( NSRect inBox )
{
	NSRect		mainScreenBox = [NSScreen.screens[0] frame];
	inBox.origin.y += inBox.size.height;						// Calc upper left of the box.
	mainScreenBox.origin.y += mainScreenBox.size.height;		// Calc upper left of main screen.
	inBox.origin.y = mainScreenBox.origin.y -inBox.origin.y;	// Since upper left of main screen is 0,0 in flipped, difference between those two coordinates is new Y coordinate for flipped box
	return inBox;
}


/*static*/ size_t	CScreen::GetNumScreens()
{
	return NSScreen.screens.count;
}


/*static*/ CScreen	CScreen::GetScreen( size_t inIndex )
{
	return CScreen( NSScreen.screens[inIndex] );
}


CScreen::CScreen( WILDNSScreenPtr inScreen )
: mMacScreen(inScreen)
{
	[mMacScreen retain];
}


CScreen::CScreen( const CScreen& inOriginal )
{
	mMacScreen = [inOriginal.mMacScreen retain];
}


CScreen::~CScreen()
{
	[mMacScreen release];
	mMacScreen = nil;
}


CRect	CScreen::GetRectangle() const
{
	return CRect( WILDFlippedScreenRect([mMacScreen frame]) );
}


CRect	CScreen::GetWorkingRectangle() const
{
	return CRect( WILDFlippedScreenRect([mMacScreen visibleFrame]) );
}


TCoordinate	CScreen::GetScale() const
{
	return [mMacScreen backingScaleFactor];
}
