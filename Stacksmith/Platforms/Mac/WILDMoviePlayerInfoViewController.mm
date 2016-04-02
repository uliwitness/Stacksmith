//
//  WILDMoviePlayerInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDMoviePlayerInfoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UKHelperMacros.h"
#import "CMoviePlayerPart.h"


using namespace Carlson;


@implementation WILDMoviePlayerInfoViewController

@synthesize moviePathField = mMoviePathField;

-(void)	dealloc
{
	DESTROY(mMoviePathField);
	
	[super dealloc];
}


-(void)	loadView
{
	[super loadView];
	
	[mMoviePathField setStringValue: [NSString stringWithUTF8String: ((CMoviePlayerPart*)part)->GetMediaPath().c_str()]];
	[self.controllerVisibleSwitch setState: ((CMoviePlayerPart*)part)->GetControllerVisible() ? NSOnState : NSOffState];
	[self.playingSwitch setState: ((CMoviePlayerPart*)part)->GetStarted() ? NSOnState : NSOffState];
}


-(IBAction)	doChooseMovieFile: (id)sender
{
	NSOpenPanel	*	thePanel = [NSOpenPanel openPanel];
	NSArray		*	types = [AVURLAsset audiovisualTypes];
	[thePanel setAllowedFileTypes: types];
	if( NSFileHandlingPanelOKButton == [thePanel runModal] )
	{
		[[self retain] autorelease];	// Make sure we're not released if the movie player property change recreates its view.

		NSURL		*	theURL = [thePanel URL];
		((CMoviePlayerPart*)part)->SetMediaPath( [[theURL absoluteString] UTF8String] );
	}
}

-(IBAction)	doToggleControllerVisibleSwitch: (id)sender
{
	((CMoviePlayerPart*)part)->SetControllerVisible( [self.controllerVisibleSwitch state] == NSOnState );
}

-(IBAction)	doTogglePlayingSwitch: (id)sender
{
	((CMoviePlayerPart*)part)->SetStarted( [self.playingSwitch state] == NSOnState );
}

@end
