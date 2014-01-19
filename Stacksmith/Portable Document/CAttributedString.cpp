//
//  CAttributedString.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-14.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CAttributedString.h"


using namespace Carlson;


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
	
//	Dump();
//	printf( "\n" );
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
				assert( ab.mEnd >= ab.mStart );
				assert( a.mEnd >= a.mStart );
				assert( b.mEnd >= b.mStart );
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
				assert( ab.mEnd >= ab.mStart );
				assert( a.mEnd >= a.mStart );
				assert( b.mEnd >= b.mStart );
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
				assert( a.mEnd >= a.mStart );
				assert( b.mEnd >= b.mStart );
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


void	CAttributedString::AddAttributeValueForRange( const std::string& inAttribute, const std::string& inValue, size_t inStart, size_t inEnd )
{
//	Dump();

	if( mRanges.size() == 0 )
	{
		CAttributeRange	theRange;
		theRange.mStart = inStart;
		theRange.mEnd = inEnd;
		theRange.mAttributes[inAttribute] = inValue;
		assert( theRange.mEnd >= theRange.mStart );
		mRanges.push_back(theRange);
		return;
	}
	
	for( auto currRun = mRanges.begin(); currRun != mRanges.end(); currRun++ )
	{
		assert( currRun->mEnd >= currRun->mStart );
		if( inEnd < currRun->mStart )	// Our new style is before this range.
		{
			CAttributeRange	theRange;
			theRange.mStart = inStart;
			theRange.mEnd = inEnd;
			theRange.mAttributes[inAttribute] = inValue;
			assert( theRange.mEnd >= theRange.mStart );
			currRun = mRanges.insert(currRun,theRange) +1;
		}
		else if( inStart >= currRun->mEnd )
			continue;
		else if( inStart <= currRun->mStart && inEnd >= currRun->mEnd )	// This range is completely in our new range, so we just add our attribute.
		{
			currRun->mAttributes[inAttribute] = inValue;
		}
		else if( inEnd > currRun->mStart && inEnd < currRun->mEnd )	// Our new style needs to be applied to the start of this range.
		{
			CAttributeRange	theRange = *currRun;
			theRange.mEnd = inEnd;
			currRun->mStart = inEnd;
			theRange.mAttributes[inAttribute] = inValue;
			assert( theRange.mEnd >= theRange.mStart );
			assert( currRun->mEnd >= currRun->mStart );
			currRun = mRanges.insert(currRun,theRange) +1;
		}
		else if( inStart > currRun->mStart && inEnd >= currRun->mEnd )	// Our new style needs to be applied to the end of this range.
		{
			assert( currRun->mEnd >= inStart );
			CAttributeRange	theRange = *currRun;
			theRange.mEnd = inStart;
			currRun->mStart = inStart;
			currRun->mAttributes[inAttribute] = inValue;
			assert( theRange.mEnd >= theRange.mStart );
			assert( currRun->mEnd >= currRun->mStart );
			currRun = mRanges.insert(currRun,theRange) +1;
		}
		else if( inStart > currRun->mStart && inEnd < currRun->mEnd )	// Our new style is smack-dab in the middle of this range
		{
			CAttributeRange	beforeRange = *currRun;
			CAttributeRange	afterRange = *currRun;
			beforeRange.mEnd = inStart;
			afterRange.mStart = inEnd;
			currRun->mStart = inStart;
			currRun->mEnd = inEnd;
			currRun->mAttributes[inAttribute] = inValue;
			assert( beforeRange.mEnd >= beforeRange.mStart );
			assert( afterRange.mEnd >= afterRange.mStart );
			assert( currRun->mEnd >= currRun->mStart );
			currRun = mRanges.insert(currRun,beforeRange) +1;
			currRun = mRanges.insert(currRun+1,afterRange) +1;
		}
	}

//	Dump();
}


void	CAttributedString::ClearAttributeForRange( const std::string& inAttribute, size_t inStart, size_t inEnd )
{
//	Dump();

	for( auto currRun = mRanges.begin(); currRun != mRanges.end(); currRun++ )
	{
		if( inEnd < currRun->mStart )	// Our new style is before this range.
		{
			// Nothing to do anymore.
			break;
		}
		else if( inStart >= currRun->mEnd )
			continue;
		else if( inStart <= currRun->mStart && inEnd >= currRun->mEnd )	// This range is completely in our new range, so we just remove our attribute.
		{
			auto	foundAttr = currRun->mAttributes.find(inAttribute);
			if( foundAttr != currRun->mAttributes.end() )
				currRun->mAttributes.erase(foundAttr);
		}
		else if( inEnd > currRun->mStart && inEnd < currRun->mEnd )	// Our new style needs to be applied to the start of this range.
		{
			CAttributeRange	theRange = *currRun;
			theRange.mEnd = inEnd;
			currRun->mStart = inEnd;
			assert( theRange.mEnd >= theRange.mStart );
			assert( currRun->mEnd >= currRun->mStart );
			auto	foundAttr = theRange.mAttributes.find(inAttribute);
			if( foundAttr != theRange.mAttributes.end() )
				theRange.mAttributes.erase(foundAttr);
			currRun = mRanges.insert(currRun,theRange) +1;
		}
		else if( inStart > currRun->mStart && inEnd > currRun->mEnd )	// Our new style needs to be applied to the end of this range.
		{
			CAttributeRange	theRange = *currRun;
			theRange.mStart = inStart;
			currRun->mEnd = inStart;
			assert( theRange.mEnd >= theRange.mStart );
			assert( currRun->mEnd >= currRun->mStart );
			auto	foundAttr = theRange.mAttributes.find(inAttribute);
			if( foundAttr != theRange.mAttributes.end() )
				theRange.mAttributes.erase(foundAttr);
			currRun = mRanges.insert(currRun,theRange) +1;
		}
		else if( inStart > currRun->mStart && inEnd < currRun->mEnd )	// Our new style is smack-dab in the middle of this range
		{
			CAttributeRange	beforeRange = *currRun;
			CAttributeRange	afterRange = *currRun;
			beforeRange.mEnd = inStart;
			afterRange.mStart = inEnd;
			currRun->mStart = inStart;
			currRun->mEnd = inEnd;
			auto	foundAttr = currRun->mAttributes.find(inAttribute);
			if( foundAttr != currRun->mAttributes.end() )
				currRun->mAttributes.erase(foundAttr);
			assert( beforeRange.mEnd >= beforeRange.mStart );
			assert( afterRange.mEnd >= afterRange.mStart );
			assert( currRun->mEnd >= currRun->mStart );
			currRun = mRanges.insert(currRun,beforeRange) +1;
			currRun = mRanges.insert(currRun+1,afterRange) +1;
		}
	}

//	Dump();
}


void	CAttributedString::ClearAllAttributesForRange( size_t inStart, size_t inEnd )
{
	Dump();
	
	for( auto currRun = mRanges.begin(); currRun != mRanges.end(); currRun++ )
	{
		if( inEnd < currRun->mStart )	// Our new style is before this range.
		{
			// Nothing to do anymore.
			break;
		}
		else if( inStart >= currRun->mEnd )
			continue;
		else if( inStart <= currRun->mStart && inEnd >= currRun->mEnd )	// This range is completely in our new range, so we just remove our attribute.
		{
			currRun = mRanges.erase(currRun);
		}
		else if( inEnd > currRun->mStart && inEnd < currRun->mEnd )	// Our new style needs to be applied to the start of this range.
		{
			currRun->mStart = inEnd;
			assert( currRun->mEnd >= currRun->mStart );
		}
		else if( inStart > currRun->mStart && inEnd > currRun->mEnd )	// Our new style needs to be applied to the end of this range.
		{
			currRun->mEnd = inStart;
			assert( currRun->mEnd >= currRun->mStart );
		}
		else if( inStart > currRun->mStart && inEnd < currRun->mEnd )	// Our new style is smack-dab in the middle of this range
		{
			CAttributeRange	beforeRange = *currRun;
			beforeRange.mEnd = inStart;
			currRun->mStart = inEnd;
			assert( beforeRange.mEnd >= beforeRange.mStart );
			assert( currRun->mEnd >= currRun->mStart );
			currRun = mRanges.insert(currRun,beforeRange) +1;
		}
	}
	
	Dump();
}


void	CAttributedString::GetAttributesInRange( size_t inStart, size_t inEnd, std::map<std::string,std::string>& outStyles, bool *outMixed )
{
	for( CAttributeRange currRun : mRanges )
	{
		if( currRun.mStart >= inStart && currRun.mEnd <= inEnd )	// Wholly contained in this style run?
			outStyles = currRun.mAttributes;
		else if( currRun.mStart < inStart && currRun.mEnd > inStart )	// Our range ends in this run?
		{
			if( outMixed )
				*outMixed = true;
		}
		else if( currRun.mStart < inStart && currRun.mEnd < inEnd )	// Our range starts in this run?
		{
			if( outMixed )
				*outMixed = true;
		}
	}
}


void	CAttributedString::ForEachRangeDo( std::function<void(CAttributeRange*,const std::string&)> inCallback )
{
	size_t	currOffs = 0;
	for( CAttributeRange currRun : mRanges )
	{
		if( currOffs < currRun.mStart )
			inCallback( NULL, mString.substr( currOffs, currRun.mStart -currOffs ) );
		assert( currRun.mEnd >= currRun.mStart );
		inCallback( &currRun, mString.substr( currRun.mStart, currRun.mEnd -currRun.mStart ) );
		currOffs = currRun.mEnd;
	}
	if( currOffs < mString.length() )
		inCallback( NULL, mString.substr( currOffs, mString.length() -currOffs ) );
}


void	CAttributedString::Dump()
{
	ForEachRangeDo( []( CAttributeRange* currRun,const std::string& inText )
	{
		std::string	text("<span style=\"");
		std::string	currLink;
		if( currRun )
		{
			for( auto currStyle : currRun->mAttributes )
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
				if( currRun->mAttributes.size() > 1 )
					text = std::string("<a href=\"") + currLink + "\">" + text;
				else
					text = std::string("<a href=\"") + currLink + "\">";
			}
		}
		if( !currRun )
			text = "";
		text.append( inText );
		if( (currRun && currLink.length() == 0) || (currRun && currRun->mAttributes.size() > 1) )
			text.append("</span>");
		if( currLink.length() > 0 )
			text.append("</a>");
		printf( "%s", text.c_str() );
	} );
}

