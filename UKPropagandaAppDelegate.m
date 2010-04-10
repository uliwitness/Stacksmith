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

-(void)	applicationDidFinishLaunching:(NSNotification *)notification
{
	NSView	*	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 94, 32)] autorelease];
	
	NSButton*	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(-1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(32 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(64 -3, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];

	[[mToolsMenu itemAtIndex: 0] setView: oneRow];

	
	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 94, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(-1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(32 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(64 -3, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];

	[[mToolsMenu itemAtIndex: 1] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 94, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(-1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(32 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(64 -3, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 2] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 94, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(-1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(32 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(64 -3, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 3] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 94, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(-1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(32 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(64 -3, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 4] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 94, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(-1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(32 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect(64 -3, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CURS_128"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 5] setView: oneRow];
}

-(BOOL)	applicationShouldHandleReopen: (NSApplication *)sender hasVisibleWindows: (BOOL)hasVisibleWindows
{
	return !hasVisibleWindows;
}


-(BOOL)	applicationOpenUntitledFile: (NSApplication *)sender
{
	NSString	*	homeStackPath = nil;
	NSString	*	standaloneStackPath = [[NSBundle mainBundle] pathForResource: @"Home" ofType: @"xstk"];
	if( standaloneStackPath && [[NSFileManager defaultManager] fileExistsAtPath: standaloneStackPath] )
		homeStackPath = standaloneStackPath;
	else
		standaloneStackPath = nil;
	homeStackPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"Home.xstk"];
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
