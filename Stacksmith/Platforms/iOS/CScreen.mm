//
//  CScreen.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2017-06-19.
//  Copyright (c) 2017 Uli Kusterer. All rights reserved.
//

#include "CScreen.h"
#import <UIKit/UIKit.h>


using namespace Carlson;


/*static*/ size_t	CScreen::GetNumScreens()
{
	return UIScreen.screens.count;
}


/*static*/ CScreen	CScreen::GetScreen( size_t inIndex )
{
	return CScreen( UIScreen.screens[inIndex] );
}


CScreen::CScreen( WILDUIScreenPtr inScreen )
: mIOSScreen(inScreen)
{
	[mIOSScreen retain];
}


CScreen::CScreen( const CScreen& inOriginal )
{
	mIOSScreen = [inOriginal.mIOSScreen retain];
}


CScreen::~CScreen()
{
	[mIOSScreen release];
	mIOSScreen = nil;
}


CRect	CScreen::GetRectangle() const
{
	return CRect( [mIOSScreen bounds] );
}


CRect	CScreen::GetWorkingRectangle() const
{
	return CRect( [mIOSScreen bounds] );
}


TCoordinate	CScreen::GetScale() const
{
	return [mIOSScreen scale];
}
