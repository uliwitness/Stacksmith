//
//  CURLConnection.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CURLConnection.h"
#include <Foundation/Foundation.h>
#include "CRefCountedObject.h"

using namespace Carlson;


/*static*/ void	CURLConnection::SendRequestWithCompletionHandler( CURLRequest& inRequest, std::function<void (CURLResponse inResponse, const char* inData, size_t inDataLength)> completionBlock )
{
	if( [inRequest.GetMacRequest().URL.scheme isEqualToString: @"file"] )
	{
		CURLResponse	responseObject(nil);
		NSData*	data = [NSData dataWithContentsOfFile: [inRequest.GetMacRequest().URL.absoluteURL path]];
		completionBlock( responseObject, (const char*)data.bytes, data.length );
	}
	else
	{
		[NSURLConnection sendAsynchronousRequest: inRequest.GetMacRequest()
							  queue: [NSOperationQueue mainQueue]
				  completionHandler: ^(NSURLResponse* response, NSData* data, NSError* connectionError)
									{
										CAutoreleasePool	pool;
										CURLResponse		responseObject(response);
										completionBlock( responseObject, (const char*)[data bytes], [data length] );
									}];
	}
}
