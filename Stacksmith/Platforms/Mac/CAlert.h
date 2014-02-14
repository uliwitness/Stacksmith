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
#include <climits>


namespace Carlson {

class CScriptableObject;

class CAlert
{
public:
	static size_t		RunMessageAlert( const std::string& inMessage, const std::string& button1 = std::string(), const std::string& button2 = std::string(), const std::string& button3 = std::string() );
	static bool			RunInputAlert( const std::string& inMessage, std::string& ioInputText );
	static void			RunScriptErrorAlert( CScriptableObject* inErrObj, const char* errMsg, size_t inLineOffset = SIZE_T_MAX, size_t inOffset = SIZE_T_MAX );
};

}

#endif /* defined(__Stacksmith__CAlert__) */
