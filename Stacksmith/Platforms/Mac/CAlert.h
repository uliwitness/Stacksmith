//
//  CAlert.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CAlert__
#define __Stacksmith__CAlert__

#include <cstddef>
#include <string>


namespace Carlson {

class CAlert
{
public:
	static size_t		RunMessageAlert( const std::string& inMessage, const std::string& button1, const std::string& button2, const std::string& button3 );
	static bool			RunInputAlert( const std::string& inMessage, std::string& ioInputText );
};

}

#endif /* defined(__Stacksmith__CAlert__) */
