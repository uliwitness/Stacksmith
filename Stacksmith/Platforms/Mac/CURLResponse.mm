//
//  CURLResponse.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CURLResponse.h"
#import <Foundation/Foundation.h>


using namespace Carlson;



CURLResponse::CURLResponse( const CURLResponse& inResponse )
{
	mMacURLResponse = [inResponse.mMacURLResponse retain];
}


CURLResponse::CURLResponse( WILDNSURLResponsePtr inMacResponse )
{
	mMacURLResponse = [inMacResponse retain];
}


CURLResponse::~CURLResponse()
{
	[mMacURLResponse release];
	mMacURLResponse = nil;
}


std::string	CURLResponse::GetURL()
{
	NSString	*	urlString = [[mMacURLResponse URL] absoluteString];
	return std::string( [urlString UTF8String] );
}


std::string	CURLResponse::GetMIMEType()
{
	NSString	*	mimeType = [mMacURLResponse MIMEType];
	if( !mimeType )
		return std::string();
	return std::string( [mimeType UTF8String] );
}


size_t	CURLResponse::GetExpectedContentLength()
{
	return [mMacURLResponse expectedContentLength];
}


long		CURLResponse::GetStatusCode()
{
	return [(NSHTTPURLResponse*)mMacURLResponse statusCode];
}


std::string	CURLResponse::GetValueForHeaderField( std::string inFieldName )
{
	NSDictionary		*	headers = [(NSHTTPURLResponse*)mMacURLResponse allHeaderFields];
	NSString			*	headerValue = [headers objectForKey: [NSString stringWithUTF8String: inFieldName.c_str()]];
	if( !headerValue )
		return std::string();
	return std::string( [headerValue UTF8String] );
}


