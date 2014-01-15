//
//  CAttributedString.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-14.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CAttributedString__
#define __Stacksmith__CAttributedString__

#include "CStyleSheet.h"
#include "tinyxml2.h"
#include <string>
#include <vector>


struct CAttributeRange
{
	std::map<std::string,std::string>	mAttributes;
	size_t								mStart;
	size_t								mEnd;
};


class CAttributedString
{
public:
	void	LoadFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles );
	
	std::string		GetString()								{ return mString; };
	void			SetString( const std::string& inStr )	{ mString = inStr; mAttributes.clear(); };
	
	void			Dump();
	
protected:
	void	AppendFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles );

	std::vector<CAttributeRange>	mAttributes;
	std::string						mString;
};

#endif /* defined(__Stacksmith__CAttributedString__) */
