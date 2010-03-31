//
//  UKPropagandaAppDelegate.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaAppDelegate.h"
#import "UKPropagandaStack.h"
#import "UKPropagandaCard.h"
#import "UKPropagandaNotifications.h"
#import "UKMenuBarOverlay.h"


@implementation UKPropagandaAppDelegate

-(BOOL)	applicationShouldHandleReopen: (NSApplication *)sender hasVisibleWindows: (BOOL)hasVisibleWindows
{
	return !hasVisibleWindows;
}


-(BOOL)	applicationOpenUntitledFile: (NSApplication *)sender
{
	NSString	*	homeStackPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"Home.xstk"];
	NSError		*	theError = nil;
	NSDocument	*	theDoc = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: [NSURL fileURLWithPath: homeStackPath] display: YES error: &theError];
	[theDoc showWindows];
	return theDoc != nil;
}


-(BOOL)	applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
	return YES;
}


-(BOOL)	validateMenuItem: (NSMenuItem *)menuItem
{
	if( [menuItem action] == @selector(toggleBackgroundEditMode:) )
	{
		[menuItem setState: mBackgroundEditMode ? NSOnState : NSOffState];
		return YES;
	}
	else
		return NO;
}


-(IBAction)	toggleBackgroundEditMode: (id)sender
{
	mBackgroundEditMode = !mBackgroundEditMode;
	[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaBackgroundEditModeChangedNotification
											object: nil userInfo:
												[NSDictionary dictionaryWithObjectsAndKeys:
													[NSNumber numberWithBool: mBackgroundEditMode], UKPropagandaBackgroundEditModeKey,
												nil]];
	if( mBackgroundEditMode )
		[UKMenuBarOverlay show];
	else
		[UKMenuBarOverlay hide];
}

@end
