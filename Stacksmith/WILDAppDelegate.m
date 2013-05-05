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
#import "WILDBackgroundModeIndicator.h"
#import "WILDTools.h"
#import "WILDAboutPanelController.h"
#import "WILDMessageBox.h"
#import "Forge.h"
#import "WILDGlobalProperties.h"
#import "WILDHostCommands.h"
#import "WILDHostFunctions.h"
#import "LEORemoteDebugger.h"
#import "UKCrashReporter.h"


@protocol WILDCreateObjectMethodMenuItemAction

-(void)	createNewPartFromTemplateAtPathInRepresentedObject: (NSMenuItem*)templateItem;

@end


@implementation WILDAppDelegate

-(void)	initializeParser
{
	LEOInitInstructionArray();
	
	// Add various instruction functions to the base set of instructions the
	//	interpreter knows. First add those that the compiler knows to parse,
	//	but which have a platform/host-specific implementation:
		// Object properties:
	LEOAddInstructionsToInstructionArray( gPropertyInstructions, LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS, &kFirstPropertyInstruction );
	
		// Global properties:
	LEOAddInstructionsToInstructionArray( gGlobalPropertyInstructions, LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS, &kFirstGlobalPropertyInstruction );
	LEOAddGlobalPropertiesAndOffsetInstructions( gHostGlobalProperties, kFirstGlobalPropertyInstruction );

		// Internet protocol stuff:
	LEOAddInstructionsToInstructionArray( gDownloadInstructions, LEO_NUMBER_OF_DOWNLOAD_INSTRUCTIONS, &kFirstDownloadInstruction );
	LEOAddGlobalPropertiesAndOffsetInstructions( gDownloadGlobalProperties, kFirstDownloadInstruction );
	
	// Now add the instructions for the syntax that Stacksmith adds itself:
		// Commands specific to this host application:
	LEOAddInstructionsToInstructionArray( gStacksmithHostCommandInstructions, WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS, &kFirstStacksmithHostCommandInstruction );
	LEOAddHostCommandsAndOffsetInstructions( gStacksmithHostCommands, kFirstStacksmithHostCommandInstruction );
	
		// Functions specific to this host application:
	LEOAddInstructionsToInstructionArray( gStacksmithHostFunctionInstructions, WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS, &kFirstStacksmithHostFunctionInstruction );
	LEOAddHostFunctionsAndOffsetInstructions( gStacksmithHostFunctions, kFirstStacksmithHostFunctionInstruction );
	
		// Native function calls:
	LEOAddInstructionsToInstructionArray( gObjCCallInstructions, LEO_NUMBER_OF_OBJCCALL_INSTRUCTIONS, &kFirstObjCCallInstruction );
	LEOLoadNativeHeadersFromFile( [[NSBundle mainBundle] pathForResource: @"frameworkheaders" ofType: @"hhc"].fileSystemRepresentation );
	
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


-(void)	applicationDidFinishLaunching:(NSNotification *)notification
{
	UKCrashReporterCheckForCrash();
	
	NSString	*	templatePath = [NSBundle.mainBundle pathForResource: @"WILDObjectTemplates" ofType: @""];
	NSArray		*	partTemplates = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: templatePath error: NULL];
	NSMenu		*	theMenu = mNewObjectSeparator.menu;
	NSInteger		theIndex = [theMenu indexOfItem: mNewObjectSeparator] +1;
	for( NSString * currPath in partTemplates )
	{
		NSString	*	theName = [currPath lastPathComponent];
		NSRange			theEnd = [theName rangeOfString: @"PartTemplate.xml"];
		if( theEnd.location == NSNotFound )
			continue;
		theName = [theName substringToIndex: theEnd.location];
		NSString	*	theTitle = [NSString stringWithFormat: @"New %@", theName];
		NSMenuItem	*	theItem = [[[NSMenuItem alloc] initWithTitle: theTitle action: @selector(createNewPartFromTemplateAtPathInRepresentedObject:) keyEquivalent: @""] autorelease];
		theItem.representedObject = [templatePath stringByAppendingPathComponent: currPath];
		[theMenu insertItem: theItem atIndex: theIndex];
		theIndex ++;
	}
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


-(IBAction)	orderFrontStandardAboutPanel: (id)sender
{
	[WILDAboutPanelController showAboutPanel];
}


-(IBAction)	goHelp: (id)sender;
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://hammer-language.org"]];
}


-(IBAction)	orderFrontMessageBox: (id)sender
{
	[[WILDMessageBox sharedMessageBox] orderFrontMessageBox: self];
}

@end
