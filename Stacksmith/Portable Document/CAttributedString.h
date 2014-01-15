//
//  CAttributedString.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-14.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CAttributedString__
#define __Stacksmith__CAttributedString__

#include <string>
#include <vector>


struct CAttributeRange
{
	std::string	mAttribute;
	std::string	mValue;
	size_t		mStart;
	size_t		mEnd;
};


class CAttributedString
{
public:
	void	AddAttributeValueForRange( const std::string& inAttribute, const std::string& inValue, size_t inStart, size_t inEnd )	{ mAttributes.push_back( (CAttributeRange){ inAttribute, inValue, inStart, inEnd } ); };
	
protected:
	std::vector<CAttributeRange>	mAttributes;
	std::string						mString;
};

#endif /* defined(__Stacksmith__CAttributedString__) */
