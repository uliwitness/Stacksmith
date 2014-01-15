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
	
	void	Dump();
	
protected:
	std::map<std::string,std::map<std::string,std::string>>	mStyles;
};

#endif /* defined(__Stacksmith__CStyleSheet__) */
