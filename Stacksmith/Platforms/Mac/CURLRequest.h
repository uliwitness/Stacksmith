//
//  CURLRequest.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CURLRequest__
#define __Stacksmith__CURLRequest__

#include <string>

// Mac-specific backing object:
#if __OBJC__
@class NSURLRequest;

typedef NSURLRequest*			WILDNSURLRequestPtr;
#else
typedef struct NSURLRequest*	WILDNSURLRequestPtr;
#endif


namespace Carlson {

// Wrapper around headers, URL etc. we may want to set on a HTTP request:
//	Intended to be a portable C++ API wrapping Cocoa's NSURLRequest,
//	though I only add the methods I actually need to make things easier for now.
class CURLRequest
{
public:
	explicit CURLRequest( const std::string& inURL );
	CURLRequest( const CURLRequest& inRequest );
	virtual	~CURLRequest();
	
	std::string		GetURL();
	
	WILDNSURLRequestPtr	GetMacRequest()	{ return mMacRequestObject; };	// Mac-specific, for use by CURLConnection only.

protected:
	WILDNSURLRequestPtr		mMacRequestObject;
};

}

#endif /* defined(__Stacksmith__CURLRequest__) */
