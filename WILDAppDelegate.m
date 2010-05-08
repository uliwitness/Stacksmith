//
//  WILDAppDelegate.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDAppDelegate.h"
#import "WILDStack.h"
#import "WILDCard.h"
#import "WILDNotifications.h"
#import "UKMenuBarOverlay.h"
#import "WILDTools.h"


@implementation WILDAppDelegate

-(void)	applicationDidFinishLaunching:(NSNotification *)notification
{
	NSView	*	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 32)] autorelease];
	
	NSButton*	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"BrowseTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDBrowseTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"ButtonTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDButtonTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"FieldTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDFieldTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];

	[[mToolsMenu itemAtIndex: 0] setView: oneRow];

	
	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 37)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"SelectTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDSelectTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"LassoTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDLassoTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"PencilTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDPencilTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];

	[[mToolsMenu itemAtIndex: 1] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"BrushTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDBrushTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"EraserTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDEraserTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6+ 64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"LineTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDLineTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 2] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"SprayTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDSprayTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"RectTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDRectangleTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"RoundRectTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDRoundRectTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 3] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"BucketTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDBucketTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"OvalTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDOvalTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CurveTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDCurveTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 4] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"TextTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDTextTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"RegPolygonTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDRegularPolygonTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"PolygonTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: WILDPolygonTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
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
	else if( [menuItem action] == @selector(toolsMenuRowDummyAction:) )
	{
		NSView*	menuView = [menuItem view];
		for( int x = 0; x < 3; x++ )
		{
			NSButton*	theBtn = [[menuView subviews] objectAtIndex: x];
			BOOL	isCurrent = [theBtn tag] == [[WILDTools sharedTools] currentTool];
			[theBtn setState: isCurrent ? NSOnState : NSOffState];
		}
		
		return YES;
	}
	else
		return NO;
}


-(IBAction)	toggleBackgroundEditMode: (id)sender
{
	mBackgroundEditMode = !mBackgroundEditMode;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDBackgroundEditModeChangedNotification
											object: nil userInfo:
												[NSDictionary dictionaryWithObjectsAndKeys:
													[NSNumber numberWithBool: mBackgroundEditMode], WILDBackgroundEditModeKey,
												nil]];
	if( mBackgroundEditMode )
		[UKMenuBarOverlay show];
	else
		[UKMenuBarOverlay hide];
}


-(IBAction)	toolsMenuRowDummyAction: (id)sender
{
	[NSApp sendAction: @selector(chooseToolWithTag:) to: nil from: sender];
	[mToolsMenu cancelTracking];
}

@end
