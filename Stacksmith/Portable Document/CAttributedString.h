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
#include "CMap.h"


namespace Carlson
{

struct CAttributeRange
{
	CMap<std::string>	mAttributes;
	size_t				mStart;
	size_t				mEnd;
	
	CMap<std::string>	GetAttributesWithoutInternal() const;
};


class CAttributedString
{
public:
	CAttributedString() {};
	explicit CAttributedString( const std::string &inStr ) : mString(inStr) {};
	CAttributedString( const CAttributedString& inStr ) : mString(inStr.mString), mRanges(inStr.mRanges) {};
	
	void			LoadFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles );
	void			SaveToXMLDocumentElementStyleSheet( tinyxml2::XMLDocument* inDoc, tinyxml2::XMLNode* inElement, CStyleSheet *styleSheet ) const;
	std::string		GetString()	const						{ return mString; };
	void			SetString( const std::string& inStr )	{ mString = inStr; mRanges.clear(); };
	size_t			GetLength()	const						{ return mString.length(); };
	void			AddAttributeValueForRange( const std::string& inAttribute, const std::string& inValue, size_t inStart, size_t inEnd );
	void			ClearAttributeForRange( const std::string& inAttribute, size_t inStart, size_t inEnd );
	void			ClearAllAttributesForRange( size_t inStart, size_t inEnd );
	void			GetAttributesInRange( size_t inStart, size_t inEnd, CMap<std::string>& outStyles, bool *outMixed ) const;
	
	void			ForEachRangeDo( std::function<void(size_t,size_t,CAttributeRange*,const std::string&)> inCallback ) const;
	size_t	UTF16OffsetFromUTF8Offset( size_t inOffs ) const;
	size_t	UTF32OffsetFromUTF8Offset( size_t inOffs ) const;
	
	void			Dump( size_t inIndent = 0 ) const;
	void			Dump( std::ostream &stream, size_t inIndent = 0 ) const;
	
	static size_t	UTF8OffsetFromUTF16Offset( size_t inCharOffs, const uint16_t* utf16, size_t byteLen );
	static size_t	UTF16OffsetFromUTF8Offset( size_t inOffs, const uint8_t* utf8, size_t byteLen );
	static size_t	UTF32OffsetFromUTF16Offset( size_t inCharOffs, const uint16_t* utf16, size_t byteLen );
	static size_t	UTF16OffsetFromUTF32Offset( size_t inCharOffs, const uint32_t* utf32, size_t byteLen );
	
protected:
	void	AppendFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles );
	void	NormalizeStyleRuns();

	std::vector<CAttributeRange>	mRanges;
	std::string						mString;
};

}

#endif /* defined(__Stacksmith__CAttributedString__) */
