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
#import "UKPropagandaTools.h"


@implementation UKPropagandaAppDelegate

-(void)	applicationDidFinishLaunching:(NSNotification *)notification
{
	NSView	*	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 32)] autorelease];
	
	NSButton*	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"BrowseTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaBrowseTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"ButtonTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaButtonTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"FieldTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaFieldTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];

	[[mToolsMenu itemAtIndex: 0] setView: oneRow];

	
	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 37)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"SelectTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaSelectTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"LassoTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaLassoTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"PencilTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaPencilTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];

	[[mToolsMenu itemAtIndex: 1] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"BrushTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaBrushTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"EraserTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaEraserTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6+ 64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"LineTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaLineTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 2] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"SprayTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaSprayTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"RectTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaRectangleTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"RoundRectTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaRoundRectTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 3] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"BucketTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaBucketTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"OvalTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaOvalTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"CurveTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaCurveTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	[[mToolsMenu itemAtIndex: 4] setView: oneRow];


	oneRow = [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, 106, 31)] autorelease];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"TextTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaTextTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +32 -1, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"RegPolygonTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaRegularPolygonTool];
	[oneButton setTarget: nil];
	[oneButton setAction: @selector(toolsMenuRowDummyAction:)];
	[oneRow addSubview: oneButton];
	
	oneButton = [[[NSButton alloc] initWithFrame: NSMakeRect( 6 +64 -2, 0, 32, 32)] autorelease];
	[oneButton setImage: [NSImage imageNamed: @"PolygonTool"]];
	[oneButton setBezelStyle: NSShadowlessSquareBezelStyle];
	[oneButton setButtonType: NSPushOnPushOffButton];
	[oneButton setTag: UKPropagandaPolygonTool];
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
			BOOL	isCurrent = [theBtn tag] == [[UKPropagandaTools propagandaTools] currentTool];
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


-(IBAction)	toolsMenuRowDummyAction: (id)sender
{
	[NSApp sendAction: @selector(chooseToolWithTag:) to: nil from: sender];
	[mToolsMenu cancelTracking];
}

@end
