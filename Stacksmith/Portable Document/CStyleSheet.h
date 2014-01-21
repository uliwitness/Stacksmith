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
#include <map>


class CStyleSheet
{
public:
	void	LoadFromStream( const std::string& inCSS );
	
	std::map<std::string,std::string>	GetStyleForClass( const char* inClassName ) const
	{
		std::string	fullClassName(".");
		fullClassName.append(inClassName);
		
		auto	foundClass = mStyles.find(fullClassName);
		if( foundClass != mStyles.end() )
			return foundClass->second;
		else
			return std::map<std::string,std::string>();
	};
	
	void	SetStyleForClass( const char* inClassName, const std::map<std::string,std::string>& inStyle )
	{
		std::string	fullClassName(".");
		fullClassName.append(inClassName);
		
		mStyles[fullClassName] = inStyle;
	};
	
	std::string	GetCSS() const;
	
	void	Dump() const;
	
protected:
	std::map<std::string,std::map<std::string,std::string>>	mStyles;
};

#endif /* defined(__Stacksmith__CStyleSheet__) */
