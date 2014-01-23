//
//  CSound.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CSound.h"
#import "ULIMelodyQueue.h"
#import <AppKit/AppKit.h>


static int		sBusySounds = 0;


@interface WILDNSSoundDelegate : NSObject <NSSoundDelegate,ULIMelodyQueueDelegate>

@end


@implementation WILDNSSoundDelegate

+(void)	sound: (NSSound *)sound didFinishPlaying: (BOOL)aBool
{
	[sound release];
	sBusySounds--;
}


+(void)	melodyQueueDidFinishPlaying: (ULIMelodyQueue*)theQueue
{
	sBusySounds--;
}

@end


using namespace Carlson;


void	CSound::PlaySoundWithURLAndMelody( const std::string& inURL, const std::string& inMelody )
{
	sBusySounds++;
	if( inMelody.length() > 0 )
	{
		ULIMelodyQueue	*	melodyQueue = [[[ULIMelodyQueue alloc] initWithInstrument: [NSURL URLWithString: [NSString stringWithUTF8String: inURL.c_str()]]] autorelease];
		[melodyQueue addMelody: [NSString stringWithUTF8String: inMelody.c_str()]];
		[melodyQueue setDelegate: [WILDNSSoundDelegate class]];
		[melodyQueue play];
	}
	else
	{
		NSSound		*	theSound = [[NSSound alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithUTF8String: inURL.c_str()]] byReference: YES];
		[theSound setDelegate: [WILDNSSoundDelegate class]];
		[theSound play];
	}
}


bool	CSound::IsDone()
{
	return (sBusySounds == 0);
}
