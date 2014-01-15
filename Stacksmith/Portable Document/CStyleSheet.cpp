//
//  CStyleSheet.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-15.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CStyleSheet.h"
#include <cctype>


bool	iswhitespaceornewline( char ch )
{
	return (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r');
}


void	CStyleSheet::LoadFromStream( const std::string& inCSS )
{
	enum { kStateWhitespace, kStateStyleClass,
			kStateWhitespaceAfterStyleClass,
			kStateInsideStyle, kStateStyleSelector,
			kStateWhitespaceAfterStyleSelector,
			kStateWhitespaceAfterStyleSelectorColon, kStateSelectorValue,
			}		state = kStateWhitespace;
	std::string	selectorName;
	std::string	styleClassName;
	std::string selectorValue;
	
	for( char currCh : inCSS )
	{
		switch( state )
		{
			case kStateWhitespace:
				if( !iswhitespaceornewline(currCh) )
				{
					styleClassName.erase();
					styleClassName.append( 1, currCh );
					state = kStateStyleClass;
				}
				break;
			
			case kStateStyleClass:
				if( iswhitespaceornewline(currCh) )
				{
					state = kStateWhitespaceAfterStyleClass;
					mStyles[styleClassName] = std::map<std::string,std::string>();
				}
				else if( currCh == '{' )
					state = kStateInsideStyle;
				else
					styleClassName.append( 1, currCh );
				break;
			
			case kStateWhitespaceAfterStyleClass:
				if( currCh == '{' )
					state = kStateInsideStyle;
				break;
			
			case kStateInsideStyle:
				if( currCh == '}' )
					state = kStateWhitespace;
				else if( !iswhitespaceornewline(currCh) )
				{
					selectorName.erase();
					selectorName.append( 1, currCh );
					state = kStateStyleSelector;
				}
				break;
			
			case kStateStyleSelector:
				if( currCh == ':' )
					state = kStateWhitespaceAfterStyleSelectorColon;
				else if( !iswhitespaceornewline(currCh) )
				{
					selectorName.append( 1, currCh );
				}
				else
				{
					state = kStateWhitespaceAfterStyleSelector;
				}
				break;
			
			case kStateWhitespaceAfterStyleSelector:
				if( currCh == ':' )
					state = kStateWhitespaceAfterStyleSelectorColon;
				break;
			
			case kStateWhitespaceAfterStyleSelectorColon:
				if( !iswhitespaceornewline(currCh) )
				{
					selectorValue.erase();
					selectorValue.append( 1, currCh );
					state = kStateSelectorValue;
				}
				break;
			
			case kStateSelectorValue:
				if( currCh == ';' )
				{
					state = kStateInsideStyle;
					mStyles[styleClassName][selectorName] = selectorValue;
				}
				else
				{
					selectorValue.append( 1, currCh );
				}
				break;
		}
	}
}


void	CStyleSheet::Dump()
{
	for( auto styleParts : mStyles )
	{
		printf( "\"%s\":\n", styleParts.first.c_str() );
		for( auto currStyle : styleParts.second )
		{
			printf( "\t\"%s\": \"%s\"\n", currStyle.first.c_str(), currStyle.second.c_str() );
		}
	}
}
