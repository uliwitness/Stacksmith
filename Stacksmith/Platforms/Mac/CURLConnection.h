//
//  CURLConnection.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CURLConnection__
#define __Stacksmith__CURLConnection__

#include <functional>
#include "CURLRequest.h"
#include "CURLResponse.h"


namespace Calhoun {

// A class for sending HTTP requests and getting headers and body data back:
class CURLConnection
{
public:
	static void	SendRequestWithCompletionHandler( CURLRequest& inRequest, std::function<void (CURLResponse inResponse, const char* inData, size_t inDataLength)> completionBlock );
};

}

#endif /* defined(__Stacksmith__CURLConnection__) */
