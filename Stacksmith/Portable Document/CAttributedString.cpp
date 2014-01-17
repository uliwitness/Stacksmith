//
//  CAttributedString.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-14.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CAttributedString.h"


std::map<std::string,std::string>	CAttributeRange::GetAttributesWithoutInternal()
{
	std::map<std::string,std::string>	filteredAttrs;
	for( auto currElem : mAttributes )
	{
		if( currElem.first[0] != '$' )
			filteredAttrs.insert( currElem );
	}
	return filteredAttrs;
}


void	CAttributedString::LoadFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles )
{
	AppendFromElementWithStyles( inElement, inStyles );
	
	Dump();
	printf( "\n" );
}


void	CAttributedString::AppendFromElementWithStyles( tinyxml2::XMLElement * inElement, const CStyleSheet& inStyles )
{
	tinyxml2::XMLNode * currChild = inElement->FirstChild();
	while( currChild )
	{
		tinyxml2::XMLElement *	elem = currChild->ToElement();
		if( elem )
		{
			CAttributeRange		attr;
			attr.mStart = mString.length();
			
			tinyxml2::XMLNode * firstChild = currChild->FirstChild();
			if( firstChild )
			{
				tinyxml2::XMLElement *	firstElem = firstChild->ToElement();
				if( firstElem )
					AppendFromElementWithStyles( firstElem, inStyles );
				else
					mString.append( firstChild->Value() );
			}
			
			attr.mEnd = mString.length();
			
			const char*	className = elem->Attribute( "class" );
			if( className )
			{
				auto	styles = inStyles.GetStyleForClass( className );
				attr.mAttributes = styles;
				mRanges.push_back( attr );
			}
			else if( strcmp(elem->Value(),"a") == 0 )
			{
				const char*	urlStr = elem->Attribute( "href" );
				if( urlStr )
					attr.mAttributes["$link"] = urlStr;
				mRanges.push_back( attr );
			}
			else if( strcmp(elem->Value(),"b") == 0 )
			{
				attr.mAttributes["font-weight"] = "bold";
				mRanges.push_back( attr );
			}
			else if( strcmp(elem->Value(),"i") == 0 )
			{
				attr.mAttributes["font-style"] = "italic";
				mRanges.push_back( attr );
			}
			else if( strcmp(elem->Value(),"u") == 0 )
			{
				attr.mAttributes["text-decoration"] = "underline";
				mRanges.push_back( attr );
			}
		}
		else
			mString.append( currChild->Value() );
		currChild = currChild->NextSibling();
	}
	
	NormalizeStyleRuns();
}


void	CAttributedString::NormalizeStyleRuns()
{
	// Sort runs by start.
	sort( mRanges.begin(), mRanges.end(),
            [](const CAttributeRange& a, const CAttributeRange& b)
            {
                return a.mStart > b.mStart;
            });
	
	// Split overlapping runs.
	if( mRanges.size() > 1 )
	{
		for( size_t x = 0; x < (mRanges.size() -1); x++ )
		{
			CAttributeRange& a = mRanges[x];
			CAttributeRange& b = mRanges[x +1];
			
			if( b.mStart < a.mEnd )	// Overlap!
			{
				CAttributeRange		ab = a;
				ab.mStart = b.mStart;
				ab.mEnd = a.mEnd;
				a.mEnd = b.mStart;
				b.mStart = a.mEnd;
				ab.mAttributes.insert( b.mAttributes.begin(), b.mAttributes.end() );
				mRanges.insert( mRanges.begin() +x +1, ab);
			}
		}
	}
	
	// Merge runs covering the same range.
	if( mRanges.size() > 1 )
	{
		for( size_t x = 0; x < (mRanges.size() -1); x++ )
		{
			CAttributeRange& a = mRanges[x];
			CAttributeRange& b = mRanges[x +1];
			
			if( b.mStart < a.mEnd )	// Overlap!
			{
				CAttributeRange		ab = a;
				ab.mStart = b.mStart;
				ab.mEnd = a.mEnd;
				a.mEnd = b.mStart;
				b.mStart = a.mEnd;
				ab.mAttributes.insert( b.mAttributes.begin(), b.mAttributes.end() );
				mRanges.insert( mRanges.begin() +x +1, ab);
			}
		}
	}
	
	// Merge adjacent runs with same attributes.
	if( mRanges.size() > 1 )
	{
		for( size_t x = 0; x < (mRanges.size() -1); x++ )
		{
			CAttributeRange& a = mRanges[x];
			CAttributeRange& b = mRanges[x +1];
			
			if( b.mAttributes == a.mAttributes )	// Same attributes!
			{
				a.mEnd = b.mEnd;
				b.mStart = b.mEnd;
			}
		}
	}

	// Remove zero-length runs.
	std::vector<CAttributeRange>	newRanges = mRanges;
	for( auto currAttr : mRanges )
	{
		if( currAttr.mStart != currAttr.mEnd )
			newRanges.push_back(currAttr);
	}
	
	mRanges = newRanges;
}


void	CAttributedString::SaveToXMLDocumentElementStyleSheet( tinyxml2::XMLDocument* inDoc, tinyxml2::XMLElement* inElement, CStyleSheet *styleSheet )
{
	int		styleNum = 0;
	size_t	currOffs = 0;
	for( CAttributeRange currRun : mRanges )
	{
		if( currOffs < currRun.mStart )
			inElement->InsertEndChild( inDoc->NewText( mString.substr( currOffs, currRun.mStart -currOffs ).c_str() ) );
		char	styleName[1024] = {0};
		snprintf( styleName, sizeof(styleName) -1, "style%d", ++styleNum );
		tinyxml2::XMLElement* spanElement = inDoc->NewElement( "span" );
		spanElement->SetAttribute( "class", styleName );
		spanElement->InsertEndChild( inDoc->NewText( mString.substr( currRun.mStart, currRun.mEnd -currRun.mStart ).c_str() ) );
		auto	currLink = currRun.mAttributes.find("$link");
		if( currLink != currRun.mAttributes.end() )
		{
			tinyxml2::XMLElement* linkElement = inDoc->NewElement( "a" );
			linkElement->SetAttribute( "href", currLink->second.c_str() );
			linkElement->InsertEndChild( spanElement );
			
			inElement->InsertEndChild( linkElement );
		}
		else
			inElement->InsertEndChild( spanElement );
		
		styleSheet->SetStyleForClass( styleName, currRun.GetAttributesWithoutInternal() );
		
		currOffs = currRun.mEnd;
	}
	if( currOffs < mString.length() )
		inElement->InsertEndChild( inDoc->NewText( mString.substr( currOffs, mString.length() -currOffs ).c_str() ) );
}


void	CAttributedString::Dump()
{
	size_t	currOffs = 0;
	for( CAttributeRange currRun : mRanges )
	{
		if( currOffs < currRun.mStart )
			printf( "%s", mString.substr( currOffs, currRun.mStart -currOffs ).c_str() );
		std::string	text("<span style=\"");
		std::string	currLink;
		for( auto currStyle : currRun.mAttributes )
		{
			if( currStyle.first.compare("$link") == 0 )
				currLink = currStyle.second;
			else
			{
				text.append( currStyle.first );
				text.append(1,':');
				text.append( currStyle.second );
				text.append(1,';');
			}
		}
		text.append("\">");
		if( currLink.length() > 0 )
		{
			if( currRun.mAttributes.size() > 1 )
				text = std::string("<a href=\"") + currLink + "\">" + text;
			else
				text = std::string("<a href=\"") + currLink + "\">";
		}
		text.append(mString.substr( currRun.mStart, currRun.mEnd -currRun.mStart ));
		if( currLink.length() == 0 || currRun.mAttributes.size() > 1 )
			text.append("</span>");
		if( currLink.length() > 0 )
			text.append("</a>");
		printf( "%s", text.c_str() );
		currOffs = currRun.mEnd;
	}
	if( currOffs < mString.length() )
		printf( "%s", mString.substr( currOffs, mString.length() -currOffs ).c_str() );
}

