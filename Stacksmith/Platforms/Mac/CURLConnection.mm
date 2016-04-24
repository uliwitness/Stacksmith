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
		CAutoreleasePool	pool;
		completionBlock( responseObject, (const char*)data.bytes, data.length );
	}
	else
	{
		NSURLSession		 *	session = [NSURLSession sharedSession];
		NSURLSessionDataTask *	theTask = [session dataTaskWithRequest: inRequest.GetMacRequest() completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
			CAutoreleasePool	pool;
			CURLResponse		responseObject(response);
            dispatch_async( dispatch_get_main_queue(), ^{
                completionBlock( responseObject, (const char*)[data bytes], [data length] );
            });
		}];
		[theTask resume];
	}
}
