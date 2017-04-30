//
//  CImageCanvas.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 02/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#include "CImageCanvas.h"
#import <Cocoa/Cocoa.h>


using namespace Carlson;


CImageCanvas::CImageCanvas( const CSize& inSize, TCoordinate scaleFactor )
{
	NSSize	theSize = inSize.mSize;
	mImage = [[NSImage alloc] initWithSize: theSize];
}


CImageCanvas::CImageCanvas( const std::string& inImageURL )
{
	mImage = [[NSImage alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithUTF8String: inImageURL.c_str()]]];
}


CImageCanvas::CImageCanvas( CImageCanvas&& inOriginal )
{
	mImage = inOriginal.mImage;
	inOriginal.mImage = NULL;
}


CImageCanvas::CImageCanvas( WILDNSImagePtr inImage )
{
	mImage = [inImage retain];
}


CImageCanvas::~CImageCanvas()
{
	[mImage release];
}


void	CImageCanvas::InitWithSize( const CSize& inSize, TCoordinate scaleFactor )
{
	[mImage release];
	mImage = nil;
	if( inSize.GetWidth() > 0 && inSize.GetHeight() > 0 )
		mImage = [[NSImage alloc] initWithSize: inSize.mSize];
}


void	CImageCanvas::InitWithImageFileURL( const std::string& inImageURL )
{
	[mImage release];
	mImage = nil;
	mImage = [[NSImage alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithUTF8String: inImageURL.c_str()]]];

}


void	CImageCanvas::BeginDrawing()
{
	[mImage lockFocus];
	mLastGraphicsStateSeed = 0;	// lockFocus creates a new context for us, so need to re-apply graphics state.
}


void	CImageCanvas::EndDrawing()
{
	[mImage unlockFocus];
}


CRect	CImageCanvas::GetRect() const
{
	if( !mImage )
		return CRect();
	return CRect( (CGRect){{0,0},[mImage size]} );
}


CSize	CImageCanvas::GetSize() const
{
	if( !mImage )
		return CSize();
	return CSize( [mImage size] );
}


CImageCanvas	CImageCanvas::Copy() const
{
	NSImage		*	imageCopy = [mImage copy];
	CImageCanvas	resultImg( imageCopy );
	[imageCopy release];
	
	return resultImg;
}


 CImageCanvas& CImageCanvas::operator =( const CImageCanvas& inOriginal )
 {
	if( mImage != inOriginal.mImage )
	{
		mImage = [inOriginal.mImage retain];
	}
	
	return *this;
 }
