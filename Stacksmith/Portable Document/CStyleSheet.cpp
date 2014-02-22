//
//  CStyleSheet.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-15.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CStyleSheet.h"
#include <sstream>
#include "CMap.h"


using namespace Carlson;


bool	iswhitespaceornewline( char ch );


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
					mStyles[styleClassName] = CMap<std::string>();
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
					if( selectorValue.length() > 0 && iswhitespaceornewline(selectorValue[selectorValue.length() -1]) )	// Ends in whitespace?
						selectorValue = selectorValue.substr(0,selectorValue.length() -1);
					mStyles[styleClassName][selectorName] = selectorValue;
				}
				else if( iswhitespaceornewline(currCh) )
				{
					if( selectorValue.length() == 0
						|| selectorValue[selectorValue.length() -1] != ' ' )
						selectorValue.append( 1, ' ' );	// At most a single space, no newlines etc.
				}
				else
				{
					selectorValue.append( 1, currCh );
				}
				break;
		}
	}
}


void	CStyleSheet::Dump() const
{
	for( auto styleParts : mStyles )
	{
		printf( "\t\t%s\n\t\t{\n", styleParts.first.c_str() );
		for( auto currStyle : styleParts.second )
		{
			printf( "\t\t\t%s: %s;\n", currStyle.first.c_str(), currStyle.second.c_str() );
		}
		printf( "\t\t}\n" );
	}
}


std::string	CStyleSheet::GetCSS() const
{
	std::stringstream	sstream;
	
	for( auto styleParts : mStyles )
	{
		sstream << styleParts.first << "\n{\n";
		for( auto currStyle : styleParts.second )
		{
			sstream << "\t" << currStyle.first << ": " << currStyle.second << ";\n";
		}
		sstream << "}\n";
	}
	
	return sstream.str();
}


std::string	CStyleSheet::UniqueNameForClass( const char* inBaseName )
{
	size_t			counter = 1;
	std::string		currName;
	{
		std::stringstream	nameStream;
		nameStream << '.' << inBaseName << counter++;
		currName = nameStream.str();
	}
	
	bool			isUnique = false;
	while( !isUnique )
	{
		isUnique = true;
		for( auto currStyle : mStyles )
		{
			if( currStyle.first.compare( currName ) == 0 )
			{
				isUnique = false;
				break;
			}
		}
		
		if( !isUnique )
		{
			std::stringstream	nameStream;
			nameStream << '.' << inBaseName << counter++;
			currName = nameStream.str();
		}
	}
	
	return currName.substr(1);
}

