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
#import "WILDAboutPanelController.h"
#import "WILDMessageBox.h"
#import "Forge.h"
#import "LEOGlobalProperties.h"
#import "ForgeHostCommandsStacksmith.h"
#import "ForgeHostFunctionsStacksmith.h"
#import "LEORemoteDebugger.h"
#import <openssl/err.h>
#import "WILDToolsPalette.h"


@implementation WILDAppDelegate

-(void)	initializeParser
{
	LEOInitInstructionArray();
	
	// Message box related instructions:
	LEOAddInstructionsToInstructionArray( gMsgInstructions, gMsgInstructionNames, LEO_NUMBER_OF_MSG_INSTRUCTIONS, &kFirstMsgInstruction );
	
	// Object properties:
	LEOAddInstructionsToInstructionArray( gPropertyInstructions, gPropertyInstructionNames, LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS, &kFirstPropertyInstruction );
	
	// Global properties:
	LEOAddInstructionsToInstructionArray( gGlobalPropertyInstructions, gGlobalPropertyInstructionNames, LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS, &kFirstGlobalPropertyInstruction );
	LEOAddGlobalPropertiesAndOffsetInstructions( gHostGlobalProperties, kFirstGlobalPropertyInstruction );
	
	// Commands specific to this host application:
	LEOAddInstructionsToInstructionArray( gStacksmithHostCommandInstructions, gStacksmithHostCommandInstructionNames, WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS, &kFirstStacksmithHostCommandInstruction );
	LEOAddHostCommandsAndOffsetInstructions( gStacksmithHostCommands, kFirstStacksmithHostCommandInstruction );
	
	// Functions specific to this host application:
	LEOAddInstructionsToInstructionArray( gStacksmithHostFunctionInstructions, gStacksmithHostFunctionInstructionNames, WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS, &kFirstStacksmithHostFunctionInstruction );
	LEOAddHostFunctionsAndOffsetInstructions( gStacksmithHostFunctions, kFirstStacksmithHostFunctionInstruction );
	
	[WILDToolsPalette showToolsPaletteIfNeeded];
	
	#if REMOTE_DEBUGGER
	LEOInitRemoteDebugger( "127.0.0.1" );
	#endif
}


-(NSEvent*)	handleFlagsChangedEvent: (NSEvent*)inEvent
{
	if( !mPeeking && ([inEvent modifierFlags] & NSAlternateKeyMask)
		&& ([inEvent modifierFlags] & NSCommandKeyMask) )
	{
		mPeeking = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPeekingStateChangedNotification
												object: nil userInfo:
													[NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithBool: mPeeking], WILDPeekingStateKey,
													nil]];
	}
	else if( mPeeking )
	{
		mPeeking = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPeekingStateChangedNotification
												object: nil userInfo:
													[NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithBool: mPeeking], WILDPeekingStateKey,
													nil]];
	}

	return inEvent;
}


-(void)	applicationWillFinishLaunching:(NSNotification *)notification
{
	[self initializeParser];
	
	mFlagsChangedEventMonitor = [[NSEvent addLocalMonitorForEventsMatchingMask: NSFlagsChangedMask handler: ^(NSEvent* inEvent){ return [self handleFlagsChangedEvent: inEvent]; }] retain];
	
	[[NSColorPanel sharedColorPanel] setShowsAlpha: YES];
}


-(BOOL)	openStandardStackNamed: (NSString*)inStackName
{
	NSString	*	homeStackPath = nil;
	NSString	*	standaloneStackPath = [[NSBundle mainBundle] pathForResource: inStackName ofType: @"xstk"];
	if( standaloneStackPath && [[NSFileManager defaultManager] fileExistsAtPath: standaloneStackPath] )
		homeStackPath = standaloneStackPath;
	else
		standaloneStackPath = [[NSBundle mainBundle] pathForResource: inStackName ofType: @""];
	
	if( standaloneStackPath && [[NSFileManager defaultManager] fileExistsAtPath: standaloneStackPath] )
		homeStackPath = standaloneStackPath;
	else
        standaloneStackPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: [inStackName stringByAppendingString: @".xstk"]];
	
	if( standaloneStackPath && [[NSFileManager defaultManager] fileExistsAtPath: standaloneStackPath] )
		homeStackPath = standaloneStackPath;
	else
        homeStackPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: inStackName];
	
	NSError		*	theError = nil;
	NSDocument	*	theDoc = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: [NSURL fileURLWithPath: homeStackPath]
                                                                                                 display: YES error: &theError];
	[theDoc showWindows];
	
	return theDoc != nil;
}


-(BOOL)	applicationOpenUntitledFile: (NSApplication *)sender
{
	static BOOL	sDidTryToOpenOverrideStack = NO;
	
	if( !sDidTryToOpenOverrideStack )
	{
		sDidTryToOpenOverrideStack = YES;
		
		NSString *	stackPath = nil;
		NSArray	*	cmdLineParams = [[NSProcessInfo processInfo] arguments];
		NSUInteger	x = 0;
		for( NSString* theParam in cmdLineParams )
		{
			if( [theParam isEqualToString: @"--stack"] )
			{
				if( [cmdLineParams count] > (x +1) )
				{
					stackPath = [cmdLineParams objectAtIndex: x+1];
					return [self application: NSApp openFile: stackPath];
				}
			}
			x++;
		}
	}
	
	return [self openStandardStackNamed: @"Home"];
}


-(BOOL)	application:(NSApplication *)sender openFile:(NSString *)filename
{
	NSError		*		theError = nil;
	
	if( [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: [NSURL fileURLWithPath: filename] display: YES error: &theError] == nil )
		[[NSApplication sharedApplication] presentError: theError];
	
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


-(IBAction)	orderFrontMessageBox: (id)sender
{
	[[WILDMessageBox sharedMessageBox] orderFrontMessageBox: self];
}


-(IBAction)	orderFrontToolsPalette: (id)sender
{
	[[WILDToolsPalette sharedToolsPalette] orderFrontToolsPalette: self];
}

@end
