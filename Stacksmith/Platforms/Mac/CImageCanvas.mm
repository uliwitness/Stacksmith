//
//  CImageCanvas.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 02/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#include "CImageCanvas.h"
#include <iostream>
#include <ImageIO/ImageIO.h>
#import <Foundation/Foundation.h>


using namespace Carlson;


CImageCanvas::CImageCanvas( const CSize& inSize, TCoordinate scaleFactor )
{
	InitWithSize( inSize, scaleFactor );
}


CImageCanvas::CImageCanvas( const std::string& inImageURL )
{
	InitWithImageFileURL( inImageURL );
}


CImageCanvas::CImageCanvas( CImageCanvas&& inOriginal )
{
	mImage = inOriginal.mImage;
	inOriginal.mImage = NULL;
}


CImageCanvas::CImageCanvas( CGImageRef inImage )
{
	mImage = CGImageRetain( inImage );
}


CImageCanvas::~CImageCanvas()
{
	CGImageRelease( mImage );
	CGContextRelease( mContext );
}


void	CImageCanvas::InitWithSize( const CSize& inSize, TCoordinate scaleFactor )
{
	CGContextRelease( mContext );
	mContext = NULL;
	CGImageRelease( mImage );
	mImage = NULL;
	
	CGColorSpaceRef theColorSpace = CGColorSpaceCreateDeviceRGB();
	mContext = CGBitmapContextCreate( NULL, inSize.GetWidth(), inSize.GetHeight(), 8, inSize.GetWidth() * 4, theColorSpace, kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst );
	CGColorSpaceRelease( theColorSpace );
	
	mLastGraphicsStateSeed = 0;
}


void	CImageCanvas::InitWithImageFileURL( const std::string& inImageURL )
{
	CGContextRelease( mContext );
	mContext = NULL;
	CGImageRelease( mImage );
	mImage = NULL;
	
	CFURLRef	theURL = CFURLCreateWithBytes( kCFAllocatorDefault, (UInt8*) inImageURL.data(), inImageURL.size(), kCFStringEncodingUTF8, NULL );
	if( !theURL )
		return;
	CGImageSourceRef theSource = CGImageSourceCreateWithURL( theURL, NULL );
	if( !theSource )
	{
		CFRelease( theURL );
		return;
	}
	mImage = CGImageSourceCreateImageAtIndex( theSource, 0, NULL );
	CFRelease( theSource );
	if( !mImage )
	{
		CGPDFDocumentRef theDocument = CGPDFDocumentCreateWithURL( theURL );
		CGPDFPageRef thePage = theDocument ? CGPDFDocumentGetPage( theDocument, 1 ) : NULL;
		
		if( thePage )
		{
			CGRect pageRect = CGPDFPageGetBoxRect( thePage, kCGPDFMediaBox );
			InitWithSize( CSize(pageRect.size) );
			CGContextDrawPDFPage( mContext, thePage );
		}
		
		CGPDFDocumentRelease( theDocument );
	}
	CFRelease( theURL );

	mLastGraphicsStateSeed = 0;
}


void	CImageCanvas::InitWithImageFileData( const void* inData, size_t inDataLen )
{
	CGContextRelease( mContext );
	mContext = NULL;
	CGImageRelease( mImage );
	mImage = NULL;
	
	CFDataRef theData = CFDataCreate( kCFAllocatorDefault, (UInt8*)inData, inDataLen );
	CGImageSourceRef theSource = CGImageSourceCreateWithData( theData, (CFDictionaryRef) @{ (NSString*) kCGImageSourceShouldCache: @YES, (NSString*)kCGImageSourceShouldAllowFloat: @YES } );
	if( !theSource )
	{
		CFRelease( theData );
		return;
	}
	mImage = CGImageSourceCreateImageAtIndex( theSource, 0, NULL );
	CFRelease( theSource );
	if( !mImage )
	{
		CGDataProviderRef theProvider = CGDataProviderCreateWithCFData( theData );
		CGPDFDocumentRef theDocument = CGPDFDocumentCreateWithProvider( theProvider );
		CGDataProviderRelease( theProvider );
		CGPDFPageRef thePage = theDocument ? CGPDFDocumentGetPage( theDocument, 1 ) : NULL;
		
		if( thePage )
		{
			CGRect pageRect = CGPDFPageGetBoxRect( thePage, kCGPDFMediaBox );
			pageRect.size.width = ceil(pageRect.size.width);
			pageRect.size.height = ceil(pageRect.size.height);
			InitWithSize( CSize(pageRect.size) );
			CGContextDrawPDFPage( mContext, thePage );
		}
		CGPDFDocumentRelease( theDocument );
	}
	CFRelease( theData );
	
	mLastGraphicsStateSeed = 0;
}


void	CImageCanvas::BeginDrawing()
{
	if( !mContext && mImage )
	{
		CRect theBox = GetRect();
		CGImageRef theImage = mImage;
		mImage = NULL;
		
		InitWithSize( theBox.GetSize() );
		
		CGContextDrawImage( mContext, theBox.GetMacRect(), theImage );
		CGImageRelease( theImage );
	}
}


void	CImageCanvas::EndDrawing()
{
	
}


CRect	CImageCanvas::GetRect() const
{
	return CRect( (CGRect){{0,0}, GetSize().GetMacSize() } );
}


CSize	CImageCanvas::GetSize() const
{
	CSize theSize;
	if( mContext )
	{
		theSize = CSize( CGBitmapContextGetWidth( mContext ), CGBitmapContextGetHeight( mContext ) );
	}
	else if( mImage )
	{
		theSize = CSize( CGImageGetWidth(mImage), CGImageGetHeight(mImage) );
	}

	return theSize;
}


CImageCanvas	CImageCanvas::Copy() const
{
	CGImageRef	theImage = mImage;
	if( theImage )
	{
		theImage = CGImageCreateCopy( theImage );
	}
	else if( mContext )
	{
		theImage = CGImageRetain( GetMacImage() );
	}
	
	CImageCanvas	resultImg( theImage );
	CGImageRelease( theImage );
	return resultImg;
}


CImageCanvas& CImageCanvas::operator =( const CImageCanvas& inOriginal )
{
	if( mContext )
	{
		CGContextRelease(mContext);
		mContext = NULL;
	}
	
	CGImageRef originalImage = inOriginal.GetMacImage();
	if( mImage != originalImage )
	{
		CGImageRelease(originalImage);
		mImage = CGImageRetain(originalImage);
	}

	return *this;
}


void	CImageCanvas::ImageChanged()
{
	if( mImage )
	{
		CFRelease(mImage);
		mImage = NULL;
	}
}


CGImageRef	CImageCanvas::GetMacImage() const
{
	if( !mImage && mContext )
	{
		mImage = CGBitmapContextCreateImage( mContext );
	}
	return mImage;
}


CImageCanvas CImageCanvas::GetImageForRect( const CRect& box )
{
	size_t bitsPerComponent = 8;
	CGContextRef bmContext = CGBitmapContextCreate( NULL, box.GetWidth(), box.GetHeight(), bitsPerComponent, box.GetWidth() * 4, NULL, kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst );
	
	CGRect	subBox = box.GetMacRect();
	subBox.origin.x *= -1.0;
	subBox.origin.y *= -1.0;
	CGImageRef theImage = CGBitmapContextCreateImage( mContext );
	CGContextDrawImage( bmContext, subBox, theImage );
	CGImageRelease( theImage );
	
	theImage = CGBitmapContextCreateImage( bmContext );
	CGContextRelease( bmContext );
	
	return CImageCanvas( theImage );
}


CColor	CImageCanvas::ColorAtPosition( const CPoint& pos )
{
	CGColorSpaceRef theColorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef	pixelContext = CGBitmapContextCreate( NULL, 1, 1, 8, 1 * 4, theColorSpace, kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst );
	CGColorSpaceRelease( theColorSpace );
	CGContextDrawImage( pixelContext, (CGRect){ { -pos.GetH(), -pos.GetV() }, GetSize().GetMacSize() }, GetMacImage() );
	uint32_t thePixel = *(uint32_t*) CGBitmapContextGetData( pixelContext );
	CGContextRelease( pixelContext );
	
	return CColor( (((thePixel & 0xff000000) >> 24) * 65535.0) / 255.0, (((thePixel & 0x00ff0000) >> 16) * 65535.0) / 255.0, (((thePixel & 0x0000ff00) >> 8) * 65535.0) / 255.0, ((thePixel & 0x000000ff) * 65535.0) / 255.0 );
}

