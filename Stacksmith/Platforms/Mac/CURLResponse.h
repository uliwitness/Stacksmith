//
//  CURLResponse.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CURLResponse__
#define __Stacksmith__CURLResponse__

#include <cstddef>
#include <string>

// Mac-specific backing object:
#if __OBJC__
@class NSURLResponse;

typedef NSURLResponse*			NSURLResponsePtr;
#else
typedef struct NSURLResponse*	NSURLResponsePtr;
#endif


namespace Calhoun {

// Object that encapsulates a reply to an HTTP request. You get one of
//	these back from CURLConnection. You never create one yourself.
class CURLResponse
{
public:
	explicit CURLResponse( NSURLResponsePtr inMacResponse );	// Mac-specific constructor.
	CURLResponse( const CURLResponse& inResponse );
	~CURLResponse();
	
	std::string							GetURL();
	std::string							GetMIMEType();
	size_t								GetExpectedContentLength();
	long								GetStatusCode();
	std::string							GetValueForHeaderField( std::string inFieldName );

protected:
	NSURLResponsePtr	mMacURLResponse;
};

}

#endif /* defined(__Stacksmith__CURLResponse__) */
