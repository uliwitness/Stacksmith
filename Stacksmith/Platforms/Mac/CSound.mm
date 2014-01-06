//
//  CSound.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CSound.h"
#import "ULIMelodyQueue.h"
#import <Foundation/Foundation.h>


using namespace Carlson;


void	CSound::PlaySoundWithURLAndMelody( const std::string& inURL, const std::string& inMelody )
{
	ULIMelodyQueue	*	melodyQueue = [[[ULIMelodyQueue alloc] initWithInstrument: [NSURL URLWithString: [NSString stringWithUTF8String: inURL.c_str()]]] autorelease];
	[melodyQueue addMelody: [NSString stringWithUTF8String: inMelody.c_str()]];
	[melodyQueue play];
}
