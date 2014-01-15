//
//  CAttributedString.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-14.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CAttributedString.h"


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
				mAttributes.push_back( attr );
			}
			else if( strcmp(elem->Value(),"a") == 0 )
			{
				const char*	urlStr = elem->Attribute( "href" );
				if( urlStr )
					attr.mAttributes["$link"] = urlStr;
				mAttributes.push_back( attr );
			}
			else if( strcmp(elem->Value(),"b") == 0 )
			{
				attr.mAttributes["font-weight"] = "bold";
				mAttributes.push_back( attr );
			}
			else if( strcmp(elem->Value(),"i") == 0 )
			{
				attr.mAttributes["font-style"] = "italic";
				mAttributes.push_back( attr );
			}
			else if( strcmp(elem->Value(),"u") == 0 )
			{
				attr.mAttributes["text-decoration"] = "underline";
				mAttributes.push_back( attr );
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
	// Split overlapping runs.
	// Merge runs covering the same range.
	// Merge adjacent runs with same attributes.
	// Remove zero-length runs.
}


void	CAttributedString::Dump()
{
	size_t	currOffs = 0;
	for( CAttributeRange currRun : mAttributes )
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

