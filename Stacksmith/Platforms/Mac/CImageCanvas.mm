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


CImageCanvas::CImageCanvas( const CSize& inSize )
{
	mImage = [[NSImage alloc] initWithSize: inSize.mSize];
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

void	CImageCanvas::BeginDrawing()
{
	[mImage lockFocus];
}


void	CImageCanvas::EndDrawing()
{
	[mImage unlockFocus];
}


CRect	CImageCanvas::GetRect()
{
	if( !mImage )
		return CRect();
	return CRect( (CGRect){{0,0},[mImage size]} );
}


CImageCanvas	CImageCanvas::Copy()
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