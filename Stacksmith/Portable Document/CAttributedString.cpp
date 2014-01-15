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
		}
		else
			mString.append( currChild->Value() );
		currChild = currChild->NextSibling();
	}
}


void	CAttributedString::Dump()
{
	size_t	currOffs = 0;
	for( CAttributeRange currRun : mAttributes )
	{
		if( currOffs < currRun.mStart )
			printf( "%s", mString.substr( currOffs, currRun.mStart -currOffs ).c_str() );
		std::string	text("<span style=\"");
		for( auto currStyle : currRun.mAttributes )
		{
			text.append( currStyle.first );
			text.append(1,':');
			text.append( currStyle.second );
			text.append(1,';');
		}
		text.append("\">");
		text.append(mString.substr( currRun.mStart, currRun.mEnd -currRun.mStart ));
		text.append("</span>");
		printf( "%s", text.c_str() );
		currOffs = currRun.mEnd;
	}
	if( currOffs < mString.length() )
		printf( "%s", mString.substr( currOffs, mString.length() -currOffs ).c_str() );
}

