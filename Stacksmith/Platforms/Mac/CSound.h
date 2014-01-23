//
//  CSound.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CSound__
#define __Stacksmith__CSound__


#include <cstddef>
#include <string>


namespace Carlson {


class CSound
{
public:
	static void		PlaySoundWithURLAndMelody( const std::string& inURL, const std::string& inMelody );
	static bool		IsDone();
};


}

#endif /* defined(__Stacksmith__CSound__) */
