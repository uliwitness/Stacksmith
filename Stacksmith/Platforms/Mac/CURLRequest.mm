//
//  CURLRequest.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CURLRequest.h"
#import <Cocoa/Cocoa.h>


using namespace Calhoun;


CURLRequest::CURLRequest( const CURLRequest& inRequest )
{
	mMacRequestObject = [inRequest.mMacRequestObject retain];
}


CURLRequest::CURLRequest( const std::string& inURL )
{
	mMacRequestObject = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: [NSString stringWithUTF8String: inURL.c_str()]]];
}


CURLRequest::~CURLRequest()
{
	[mMacRequestObject release];
	mMacRequestObject = nil;
}


std::string		CURLRequest::GetURL()
{
	return std::string( [[[mMacRequestObject URL] absoluteString] UTF8String] );
}

