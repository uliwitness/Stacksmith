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
#import "UKLicense.h"
#import "WILDLicensePanelController.h"
#import "WILDAboutPanelController.h"
#import <ForgeFramework/ForgeFramework.h>
#import <openssl/err.h>


@implementation WILDAppDelegate

-(void)	applicationWillFinishLaunching:(NSNotification *)notification
{
	LEOInitInstructionArray();
	LEOAddInstructionsToInstructionArray( gMsgInstructions, gMsgInstructionNames, LEO_NUMBER_OF_MSG_INSTRUCTIONS, &kFirstMsgInstruction );
	
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

-(void)	applicationDidFinishLaunching:(NSNotification *)notification	// This gets called *after* application:openFile:
{
	// Check serial number:
	while( true )
	{
		struct UKLicenseInfo	theInfo;
		NSString			*	textString = [[NSUserDefaults standardUserDefaults] stringForKey: @"WILDLicenseKey"];
		NSData				*	textData = [textString dataUsingEncoding: NSASCIIStringEncoding];
		int						numBinaryBytes = UKBinaryLengthForReadableBytesOfLength( [textData length] );
		NSMutableData		*	binaryBytes = [NSMutableData dataWithLength: numBinaryBytes];
		UKBinaryDataForReadableBytesOfLength( [textData bytes], [textData length], [binaryBytes mutableBytes] );
		UKGetLicenseData( [binaryBytes mutableBytes], [binaryBytes length], &theInfo );
		
		if( (theInfo.ukli_licenseFlags & UKLicenseFlagValid) == 0
			|| (theInfo.ukli_licenseExpiration > 0 && CFAbsoluteTimeGetCurrent() > theInfo.ukli_licenseExpiration) )
		{
			WILDLicensePanelController	*	licenseSheet = [[WILDLicensePanelController alloc] init];
			[licenseSheet runModal];
			[licenseSheet release];
		}
		else
			break;
	}
}

-(BOOL)	applicationShouldHandleReopen: (NSApplication *)sender hasVisibleWindows: (BOOL)hasVisibleWindows
{
	// Check serial number:
	struct UKLicenseInfo	theInfo;
	NSString			*	textString = [[NSUserDefaults standardUserDefaults] stringForKey: @"WILDLicenseKey"];
	NSData				*	textData = [textString dataUsingEncoding: NSASCIIStringEncoding];
	int						numBinaryBytes = UKBinaryLengthForReadableBytesOfLength( [textData length] );
	NSMutableData		*	binaryBytes = [NSMutableData dataWithLength: numBinaryBytes];
	UKBinaryDataForReadableBytesOfLength( [textData bytes], [textData length], [binaryBytes mutableBytes] );
	UKGetLicenseData( [binaryBytes mutableBytes], [binaryBytes length], &theInfo );
	
	if( (theInfo.ukli_licenseFlags & UKLicenseFlagValid) == 0 )
		exit(0);
	else if( theInfo.ukli_licenseExpiration > 0 && CFAbsoluteTimeGetCurrent() > theInfo.ukli_licenseExpiration )
		exit(0);
	else
	{
		NSString	*	person = [[[NSString alloc] initWithBytes: theInfo.ukli_licenseeName length: 40 encoding: NSUTF8StringEncoding] autorelease];
		NSCharacterSet*	ws = [NSCharacterSet whitespaceCharacterSet];
		if( [[person stringByTrimmingCharactersInSet: ws] length] == 0 )
			exit(0);
	}

	return !hasVisibleWindows;
}


-(BOOL)	openStandardStackNamed: (NSString*)inStackName
{
	NSString	*	homeStackPath = nil;
	NSString	*	standaloneStackPath = [[NSBundle mainBundle] pathForResource: inStackName ofType: @"xstk"];
	if( standaloneStackPath && [[NSFileManager defaultManager] fileExistsAtPath: standaloneStackPath] )
		homeStackPath = standaloneStackPath;
	else
        homeStackPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: [inStackName stringByAppendingString: @".xstk"]];
	NSError		*	theError = nil;
	NSDocument	*	theDoc = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: [NSURL fileURLWithPath: homeStackPath]
                                                                                                 display: YES error: &theError];
	[theDoc showWindows];
	
	return theDoc != nil;
}


-(BOOL)	applicationOpenUntitledFile: (NSApplication *)sender
{
	return [self openStandardStackNamed: @"Home"];
}


-(BOOL)	application:(NSApplication *)sender openFile:(NSString *)filename
{
	NSError		*		theError = nil;
	
	if( [[filename pathExtension] isEqualToString: @"StacksmithLicense"] )
	{
		WILDLicensePanelController	*	licensePanel = [WILDLicensePanelController currentLicensePanelController];
		NSString		*	licenseKeyString = [NSString stringWithContentsOfURL: [NSURL fileURLWithPath: filename] encoding: NSASCIIStringEncoding error: &theError];
		if( licenseKeyString )
		{
			[NSApp activateIgnoringOtherApps: YES];
			if( licensePanel == nil )
				[[NSUserDefaults standardUserDefaults] setValue: licenseKeyString forKey: @"WILDLicenseKey"];
			else
				[licensePanel setLicenseKeyString: licenseKeyString];
			
			if( [[[NSDocumentController sharedDocumentController] documents] count] == 0 )	// No other documents open? We were started up with a license file.
				[self applicationOpenUntitledFile: NSApp];
		}
		else
			[[NSApplication sharedApplication] presentError: theError];
	}
	else
	{
		if( [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: [NSURL fileURLWithPath: filename] display: YES error: &theError] == nil )
			[[NSApplication sharedApplication] presentError: theError];
	}
	
	return YES;	// We show our own errors.
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
		return [self respondsToSelector: [menuItem action]];
}


-(IBAction)	orderFrontStandardAboutPanel: (id)sender
{
	[WILDAboutPanelController showAboutPanel];
}


-(IBAction)	goHelp: (id)sender;
{
	if( ![self openStandardStackNamed: @"Help"] )
	{
		if( ![self openStandardStackNamed: @"HyperCard Help"] )
			[self openStandardStackNamed: @"HyperCard Help/HyperCard Help"];
	}
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
