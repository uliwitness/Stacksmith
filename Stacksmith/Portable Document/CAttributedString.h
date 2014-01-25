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


namespace Carlson
{

struct CAttributeRange
{
	std::map<std::string,std::string>	mAttributes;
	size_t								mStart;
	size_t								mEnd;
	
	std::map<std::string,std::string>	GetAttributesWithoutInternal() const;
};


class CAttributedString
{
public:
	void			LoadFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles );
	void			SaveToXMLDocumentElementStyleSheet( tinyxml2::XMLDocument* inDoc, tinyxml2::XMLElement* inElement, CStyleSheet *styleSheet ) const;
	std::string		GetString()	const						{ return mString; };
	void			SetString( const std::string& inStr )	{ mString = inStr; mRanges.clear(); };
	size_t			GetLength()	const						{ return mString.length(); };
	void			AddAttributeValueForRange( const std::string& inAttribute, const std::string& inValue, size_t inStart, size_t inEnd );
	void			ClearAttributeForRange( const std::string& inAttribute, size_t inStart, size_t inEnd );
	void			ClearAllAttributesForRange( size_t inStart, size_t inEnd );
	void			GetAttributesInRange( size_t inStart, size_t inEnd, std::map<std::string,std::string>& outStyles, bool *outMixed ) const;
	
	void			ForEachRangeDo( std::function<void(CAttributeRange*,const std::string&)> inCallback ) const;
	
	void			Dump() const;
	
protected:
	void	AppendFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles );
	void	NormalizeStyleRuns();

	std::vector<CAttributeRange>	mRanges;
	std::string						mString;
};

}

#endif /* defined(__Stacksmith__CAttributedString__) */
