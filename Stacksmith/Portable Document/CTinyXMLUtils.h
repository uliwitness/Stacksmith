//
//  CTinyXMLUtils.h
//  Stacksmith
//
//  Created by Uli Kusterer on 29.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CTinyXmlUtils__
#define __Stacksmith__CTinyXmlUtils__

#include <string>
#include "tinyxml2.h"


namespace Carlson {

class CTinyXMLUtils
{
public:
	static long long	GetLongLongNamed( tinyxml2::XMLElement* root, const char* inName, long long defaultValue = 0LL );
	static void			GetStringNamed( tinyxml2::XMLElement* root, const char* inName, std::string &outName );	// If string doesn't exist, leaves it unmodified.
	static bool			GetBoolNamed( tinyxml2::XMLElement* root, const char* inName, bool defaultValue = false );
	static int			GetIntNamed( tinyxml2::XMLElement* root, const char* inName, int defaultValue = 0 );
	static double		GetDoubleNamed( tinyxml2::XMLElement* root, const char* inName, double defaultValue = 0 );
	static void			GetRectNamed( tinyxml2::XMLElement* root, const char* inName, int *outLeft, int *outTop, int *outRight, int *outBottom );	// If a coordinate (or the whole key) doesn't exist, leaves that coordinate (or all 4 coordinates) unmodified.
	static void			GetColorNamed( tinyxml2::XMLElement* root, const char* inName, int *outRed, int *outGreen, int *outBlue, int *outAlpha );	// If a component (or the whole key) doesn't exist, leaves that component (or all 4 components) unmodified.
	static void			GetPointNamed( tinyxml2::XMLElement* root, const char* inName, int *outLeft, int *outTop );	// If a component (or the whole key) doesn't exist, leaves that component (or all 2 components) unmodified.
	static void			GetSizeNamed( tinyxml2::XMLElement* root, const char* inName, int *outWidth, int *outHeight );	// If a component (or the whole key) doesn't exist, leaves that component (or all 2 components) unmodified.

	static void			AddLongLongNamed( tinyxml2::XMLElement* root, long long inValue, const char* inName );
	static void			AddStringNamed( tinyxml2::XMLElement* root, const std::string& inValue, const char* inName );
	static void			AddBoolNamed( tinyxml2::XMLElement* root, bool inValue, const char* inName );
	static void			AddIntNamed( tinyxml2::XMLElement* root, int inValue, const char* inName );
	static void			AddDoubleNamed( tinyxml2::XMLElement* root, double inValue, const char* inName );
	static void			AddRectNamed( tinyxml2::XMLElement* root, long long left, long long top, long long right, long long bottom, const char* inName );
	static void			AddColorNamed( tinyxml2::XMLElement* root, int red, int green, int blue, int alpha, const char* inName );
	static void			AddPointNamed( tinyxml2::XMLElement* root, int left, int top, const char* inName );
	static void			AddSizeNamed( tinyxml2::XMLElement* root, int width, int height, const char* inName );

	static void			SetLongLongAttributeNamed( tinyxml2::XMLElement* root, long long inValue, const char* inName );
	static long long	GetLongLongAttributeNamed( tinyxml2::XMLElement* root, const char* inName, long long defaultValue = 0 );

	static std::string	EnsureNonNULLString( const char* inStr );
};

}

#endif /* defined(__Stacksmith__CTinyXmlUtils__) */
