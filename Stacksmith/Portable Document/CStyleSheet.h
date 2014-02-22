//
//  CStyleSheet.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-15.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CStyleSheet__
#define __Stacksmith__CStyleSheet__

#include <string>
#include "CMap.h"


namespace Carlson
{

class CStyleSheet
{
public:
	void	LoadFromStream( const std::string& inCSS );
	
	CMap<std::string>	GetStyleForClass( const char* inClassName ) const
	{
		std::string	fullClassName(".");
		fullClassName.append(inClassName);
		
		auto	foundClass = mStyles.find(fullClassName);
		if( foundClass != mStyles.end() )
			return foundClass->second;
		else
			return CMap<std::string>();
	};
	
	void	SetStyleForClass( const char* inClassName, const CMap<std::string>& inStyle )
	{
		std::string	fullClassName(".");
		fullClassName.append(inClassName);
		
		mStyles[fullClassName] = inStyle;
	};
	
	std::string	GetCSS() const;
	
	size_t		GetNumClasses()						{ return mStyles.size(); };
	std::string	GetClassAtIndex( size_t inIdx )		{ if( inIdx >= mStyles.size() ) return ""; auto itty = mStyles.begin(); for( ; inIdx > 0; itty++, inIdx-- ) {} return itty->first; };
	std::string	UniqueNameForClass( const char* inBaseName );	// *always* appends a number to the class name.
	
	void	Dump() const;
	
protected:
	CMap<CMap<std::string>>	mStyles;
};

}

#endif /* defined(__Stacksmith__CStyleSheet__) */
