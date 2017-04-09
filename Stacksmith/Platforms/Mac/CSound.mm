//
//  CSound.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CSound.h"
#import "ULIMelodyQueue.h"
#import "UKSoundFileRecorder.h"
#import <AppKit/AppKit.h>


static int						sBusySounds = 0;
static UKSoundFileRecorder	*	sCurrentSoundFileRecorder = nil;


@interface WILDNSSoundDelegate : NSObject <NSSoundDelegate,ULIMelodyQueueDelegate,UKSoundFileRecorderDelegate>

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


+(void)	soundFileRecorderWasStarted: (UKSoundFileRecorder*)sender
{
	NSLog(@"recording started.");
}


// Sent while we're recording:
+(void)	soundFileRecorder: (UKSoundFileRecorder*)sender reachedDuration: (NSTimeInterval)timeInSeconds
{
	NSLog(@"duration %f.", timeInSeconds);
}


// This is for level meters:
+(void)	soundFileRecorder: (UKSoundFileRecorder*)sender hasAmplitude: (float)theLevel
{
	NSLog(@"audio level %f.", theLevel);
}


// Sent after a successful stop:
+(void)	soundFileRecorderWasStopped: (UKSoundFileRecorder*)sender
{
	NSLog(@"recording ended.");
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


bool	CSound::StartRecordingToURL( const std::string& inURL )
{
	if( sCurrentSoundFileRecorder != nil )
		return false;
	
	NSString			*	urlString = [NSString stringWithUTF8String: inURL.c_str()];
	UKSoundFileRecorder	*	sfr = [[UKSoundFileRecorder alloc] initWithOutputFilePath: [NSURL URLWithString: urlString].path];
	sfr.delegate = [WILDNSSoundDelegate class];
	sfr.errorHandler = ^( NSError * errObj ){ NSLog(@"%@", errObj); };
	[sfr start: nil];
	sCurrentSoundFileRecorder = sfr;
	
	return sCurrentSoundFileRecorder != nil;
}


void	CSound::StopRecording()
{
	[sCurrentSoundFileRecorder stop: nil];
	[sCurrentSoundFileRecorder release];
	sCurrentSoundFileRecorder = nil;
}

