//
//  CMap.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-10.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMap__
#define __Stacksmith__CMap__

#include <map>
#include <string>
#include <iostream>


using namespace std;

namespace Carlson
{

class CCaseInsensitiveStringComparator : public binary_function<string, string, bool>
{
public:
	bool operator()( const string & s1, const string & s2 ) const;
};

template<class V>
class CMap : public map<string,V,CCaseInsensitiveStringComparator>
{
public:
	void	Dump() const
	{
		for( auto val : *this )
			std::cout << "[" << val.first << "] = " << val.second << std::endl;
		std::cout << "-----" << std::endl;
	}
};

}

#endif /* defined(__Stacksmith__CMap__) */
