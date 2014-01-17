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
	
	std::map<std::string,std::string>	GetAttributesWithoutInternal();
};


class CAttributedString
{
public:
	void			LoadFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles );
	void			SaveToXMLDocumentElementStyleSheet( tinyxml2::XMLDocument* inDoc, tinyxml2::XMLElement* inElement, CStyleSheet *styleSheet );
	std::string		GetString()								{ return mString; };
	void			SetString( const std::string& inStr )	{ mString = inStr; mRanges.clear(); };
	
	void			Dump();
	
protected:
	void	AppendFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles );
	void	NormalizeStyleRuns();

	std::vector<CAttributeRange>	mRanges;
	std::string						mString;
};

#endif /* defined(__Stacksmith__CAttributedString__) */
