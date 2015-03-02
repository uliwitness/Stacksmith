//
//  WILDAppDelegate.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDAppDelegate.h"
#import "WILDBackgroundModeIndicator.h"
#import "WILDAboutPanelController.h"
#import "Forge.h"
#import "WILDGlobalProperties.h"
#import "WILDHostCommands.h"
#import "WILDHostFunctions.h"
#import "LEORemoteDebugger.h"
#import "UKCrashReporter.h"
#include "CDocumentMac.h"
#include "CStackMac.h"
#include "CMessageBoxMac.h"
#include "CMessageWatcherMac.h"
#include "LEOObjCCallInstructions.h"
#import "ULIURLHandlingApplication.h"
#include "CAlert.h"
#import <Sparkle/Sparkle.h>
#include <ios>
#include <sstream>
#include "CRecentCardsList.h"
#import "UKHelperMacros.h"
#import "WILDTemplateProjectPickerController.h"


// On startup, if not asked to open any stack, we will look for a stack
//	of this name, first in our resources folder, and if none is there,
//	we will look next to the application for it.
#define HOME_STACK_NAME		"Home"


using namespace Carlson;


void	WILDFirstNativeCall( void );

void	WILDFirstNativeCall( void )
{
	LEOLoadNativeHeadersFromFile( [[NSBundle mainBundle] pathForResource: @"frameworkheaders" ofType: @"hhc"].fileSystemRepresentation );
}


void	WILDScheduleResumeOfScript( void );

void	WILDScheduleResumeOfScript( void )
{
	[(WILDAppDelegate*)[NSApplication.sharedApplication delegate] performSelector: @selector(checkForScriptToResume:) withObject: nil afterDelay: 0.0];
}


@implementation WILDAppDelegate

-(id)	init
{
	self = [super init];
	if( self )
	{
		new CDocumentManagerMac;	// Create the singleton of our subclass.
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowChanged:) name: NSWindowDidBecomeMainNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowMightHaveGoneAway:) name: NSWindowWillCloseNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(screenConfigurationMayHaveChanged:) name: NSApplicationDidChangeScreenParametersNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(toolMayHaveChanged:) name: WILDToolDidChangeNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(toolMayHaveChanged:) name: WILDBackgroundEditingDidChangeNotification object: nil];
	}
	
	return self;
}


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
	
	LEOSetFirstNativeCallCallback( WILDFirstNativeCall );	// This calls us to lazily load the (several MB) of native headers when needed.
	LEOSetCheckForResumeProc( WILDScheduleResumeOfScript );	// This calls us whenever someone requests to queue up their context to resume a script that has been paused.
	
	#if REMOTE_DEBUGGER
	LEOInitRemoteDebugger( "127.0.0.1" );
	#endif
	
	// Register Mac-specific variants of our card/background part classes:
	CStackMac::RegisterPartCreators();
	
	CMessageBox::SetSharedInstance( new CMessageBoxMac );
	CMessageWatcher::SetSharedInstance( new CMessageWatcherMac );
	CRecentCardsList::SetSharedInstance( new CRecentCardsListConcrete<CRecentCardInfo>() );
	
	Carlson::CMediaCache::SetStandardResourcesPath( [[[NSBundle mainBundle] pathForResource: @"resources" ofType: @"xml"] UTF8String] );
}


-(NSEvent*)	handleFlagsChangedEvent: (NSEvent*)inEvent
{
	BOOL		peekingStateDidChange = NO;
	if( !mPeeking && ([inEvent modifierFlags] & NSAlternateKeyMask)
		&& ([inEvent modifierFlags] & NSCommandKeyMask) )
	{
		mPeeking = YES;
		peekingStateDidChange = YES;
	}
	else if( mPeeking )
	{
		mPeeking = NO;
		peekingStateDidChange = YES;
	}
	
	if( peekingStateDidChange )
	{
		CDocumentManager::GetSharedDocumentManager()->SetPeeking( mPeeking == YES );
	}

	return inEvent;
}


-(void)	applicationWillFinishLaunching:(NSNotification *)notification
{
	[self initializeParser];
	
	mFlagsChangedEventMonitor = [[NSEvent addLocalMonitorForEventsMatchingMask: NSFlagsChangedMask handler: ^(NSEvent* inEvent){ return [self handleFlagsChangedEvent: inEvent]; }] retain];
	
	[[NSColorPanel sharedColorPanel] setShowsAlpha: YES];
	
	CStack::SetFrontStackChangedCallback( [self]( CStack* inFrontStack )
	{
		[mLockPseudoMenu setHidden: inFrontStack == NULL || (inFrontStack->GetEffectiveCantModify() == false)];
	} );
}


-(void)	applicationDidFinishLaunching:(NSNotification *)notification
{
	[self positionToolbarOnScreen: [[NSScreen screens] firstObject]];
	
	UKCrashReporterCheckForCrash();
	
	if( !CDocumentManager::GetSharedDocumentManager()->HaveDocuments() )
		[self applicationOpenUntitledFile: NSApp];
}


-(void)	applicationWillTerminate:(NSNotification *)notification
{
	CDocumentManager::GetSharedDocumentManager()->SaveAll();
}


//-(void)	applicationWillResignActive:(NSNotification *)notification
//{
//	CDocumentManager::GetSharedDocumentManager()->SaveAll();
//}


-(void)	positionToolbarOnScreen: (NSScreen*)scr
{
	NSRect		box = [mToolPanel frame];
	NSRect		screenBox = scr.visibleFrame;
	box.origin.x = screenBox.origin.x;
	box.size.width = screenBox.size.width;
	box.origin.y = NSMaxY(screenBox) -box.size.height;
	[mToolPanel setFrame: box display: YES];
	mToolPanel.movableByWindowBackground = NO;
	[mToolPanel orderFront: self];
}


-(IBAction) showStackCanvasWindow: (id)sender
{
	CDocumentManager::GetSharedDocumentManager()->GetFrontDocument()->ShowStackCanvasWindow();
}


-(IBAction)	openDocument: (id)sender
{
	NSOpenPanel*	thePanel = [NSOpenPanel openPanel];
	[thePanel setAllowedFileTypes: @[ @"xstk" ]];
	[thePanel beginWithCompletionHandler:^(NSInteger result)
	{
		if( result == NSFileHandlingPanelOKButton )
		{
			for( NSURL* theFile in thePanel.URLs )
			{
				[self application: NSApp openURL: theFile];
			}
		}
	}];
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

	NSString*	thePath = [[NSBundle mainBundle] pathForResource: @"" HOME_STACK_NAME ofType: @"xstk"];
	if( !thePath )
	{
		thePath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"" HOME_STACK_NAME ".xstk"];
	}
	return [self application: NSApp openFile: thePath];
}


-(IBAction)	goHome: (id)sender
{
	NSString*	thePath = [[NSBundle mainBundle] pathForResource: @"" HOME_STACK_NAME ofType: @"xstk"];
	if( !thePath )
	{
		thePath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"" HOME_STACK_NAME ".xstk"];
	}
	[self application: NSApp openFile: thePath];
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return CDocumentManager::GetSharedDocumentManager()->HaveDocuments();
}

-(BOOL)	application:(NSApplication *)sender openFile:(NSString *)filename
{
	return [self application: (ULIURLHandlingApplication*)sender openURL: [NSURL fileURLWithPath: filename]];
}

-(BOOL)	application: (ULIURLHandlingApplication*)sender openURL: (NSURL*)theFile
{
	std::string		fileURL( theFile.absoluteString.UTF8String );
	CDocumentManager::GetSharedDocumentManager()->OpenDocumentFromURL( fileURL,
	[]( CDocument * inNewDocument )
	{
		
	});
	
	return YES;	// We show our own errors asynchronously.
}


-(IBAction)	newDocumentFromTemplate: (id)sender
{
	if( mTemplatePickerWindow )
	{
		[mTemplatePickerWindow.window makeKeyAndOrderFront: self];
	}
	else
	{
		mTemplatePickerWindow = [[WILDTemplateProjectPickerController alloc] init];
		mTemplatePickerWindow.callbackHandler = ^(NSString* inSelectedPath)
		{
			NSSavePanel		*	savePanel = [NSSavePanel savePanel];
			savePanel.allowedFileTypes = @[@"xstk"];
			savePanel.allowsOtherFileTypes = NO;
			savePanel.canCreateDirectories = YES;
			savePanel.canSelectHiddenExtension = YES;
			savePanel.showsTagField = YES;
			savePanel.nameFieldStringValue = [inSelectedPath lastPathComponent];
			
			[savePanel beginWithCompletionHandler: ^(NSInteger result)
			{
				if( result == NSFileHandlingPanelCancelButton )
					return;
				
				NSError	*	err = nil;
				NSString*	newPath = savePanel.URL.path;
				[[NSFileManager defaultManager] removeItemAtPath: newPath error: &err];
				
				NSArray	*	filesInTemplate = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: inSelectedPath error:&err];
				if( [filesInTemplate containsObject: @"_new_empty_file_template"] )
				{
					CAutoreleasePool	pool;
					NSURL		*	newFileURL = [NSURL fileURLWithPath: newPath];
					CDocumentMac*	theDoc = new CDocumentMac();
					CDocumentManager::GetSharedDocumentManager()->AddDocument( theDoc );
					theDoc->CreateAtURL( [newFileURL URLByAppendingPathComponent: @"project.xml"].absoluteString.UTF8String );
					[newFileURL setResourceValue: @YES forKey: NSURLIsPackageKey error: NULL];
					[newFileURL setResourceValue: savePanel.tagNames forKey: NSURLTagNamesKey error: NULL];
					
					theDoc->GetStack(0)->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [](){  } );
					theDoc->Release();
				}
				else
				{
					if( ![[NSFileManager defaultManager] copyItemAtPath: inSelectedPath toPath: newPath error: &err])
					{
						[[NSApplication sharedApplication] presentError: err];
						return;
					}
					NSURL		*	newFileURL = [NSURL fileURLWithPath: newPath];
					[newFileURL setResourceValue: @YES forKey: NSURLIsPackageKey error: NULL];
					[newFileURL setResourceValue: savePanel.tagNames forKey: NSURLTagNamesKey error: NULL];
					
					[self application: [NSApplication sharedApplication] openFile: newPath];
				}
			}];
			
		};
		[mTemplatePickerWindow showWindow: self];
	}
}


-(IBAction)	newDocument: (id)sender
{
	NSSavePanel		*	savePanel = [NSSavePanel savePanel];
	savePanel.allowedFileTypes = @[@"xstk"];
	savePanel.allowsOtherFileTypes = NO;
	savePanel.canCreateDirectories = YES;
	savePanel.canSelectHiddenExtension = YES;
	savePanel.showsTagField = YES;
	[savePanel beginWithCompletionHandler: ^(NSInteger result)
	{
		if( result == NSFileHandlingPanelCancelButton )
			return;
		
		NSError	*	err = nil;
		[[NSFileManager defaultManager] removeItemAtPath: savePanel.URL.path error: &err];
		
        try
        {
            CDocumentMac*	theDoc = new CDocumentMac();
            CDocumentManager::GetSharedDocumentManager()->AddDocument( theDoc );
            theDoc->CreateAtURL( [savePanel.URL URLByAppendingPathComponent: @"project.xml"].absoluteString.UTF8String );
			[savePanel.URL setResourceValue: @YES forKey: NSURLIsPackageKey error: NULL];
			[savePanel.URL setResourceValue: savePanel.tagNames forKey: NSURLTagNamesKey error: NULL];
            
            theDoc->GetStack(0)->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [](){  } );
			theDoc->Release();
        }
        catch( std::exception& inException )
        {
            UKLog( @"Exception caught: %s", inException.what() );
        }
        catch( ... )
        {
            UKLog( @"Unknown exception caught" );
        }
	}];
}


-(BOOL)	applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
	return NO;
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
	CMessageBox::GetSharedInstance()->SetVisible( !CMessageBox::GetSharedInstance()->IsVisible() );
}


-(IBAction)	orderFrontMessageWatcher: (id)sender
{
	CMessageWatcher::GetSharedInstance()->SetVisible( !CMessageWatcher::GetSharedInstance()->IsVisible() );
}


-(BOOL)	validateMenuItem: (NSMenuItem*)inItem
{
	if( inItem.action == @selector(orderFrontMessageBox:) )
	{
		if( CMessageBox::GetSharedInstance()->IsVisible() )
			[inItem setTitle: @"Hide Message Box"];
		else
			[inItem setTitle: @"Show Message Box"];
		return YES;
	}
	else if( inItem.action == @selector(orderFrontMessageWatcher:) )
	{
		if( CMessageWatcher::GetSharedInstance()->IsVisible() )
			[inItem setTitle: @"Hide Message Watcher"];
		else
			[inItem setTitle: @"Show Message Watcher"];
		return YES;
	}
	else if( inItem.action == @selector(showStackCanvasWindow:) )
	{
		return (CDocumentManager::GetSharedDocumentManager()->GetFrontDocument() != NULL);
	}
	else
		return [self respondsToSelector: inItem.action];
}


-(BOOL)	validateUserInterfaceItem: (id<NSValidatedUserInterfaceItem>)sender
{
	if( sender.action == @selector(showStackCanvasWindow:) )
	{
		return (CDocumentManager::GetSharedDocumentManager()->GetFrontDocument() != NULL);
	}
	else if( sender.action == @selector(orderFrontMessageBox:) )
	{
		return YES;
	}
	else if( sender.action == @selector(orderFrontMessageWatcher:) )
	{
		return YES;
	}
	else
		return [self respondsToSelector: sender.action];
}


-(NSString*)	feedURLStringForUpdater: (SUUpdater*)inUpdater
{
	return @"http://stacksmith.org/nightlies/stacksmith_nightlies.rss";
}


-(void)	checkForScriptToResume: (id)sender
{
	LEOContextResumeIfAvailable();
}


-(void)	toolMayHaveChanged: (NSNotification*)notif
{
	[self validateUIItemsForWindow: [NSApplication sharedApplication].mainWindow];
}


-(void)	mainWindowMightHaveGoneAway: (NSNotification*)notif
{
	if( mObservedMainWindow && [NSApplication sharedApplication].mainWindow != mObservedMainWindow )
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidChangeScreenNotification object: mObservedMainWindow];
		mObservedMainWindow = nil;
	}
	[self validateUIItemsForWindow: [NSApplication sharedApplication].mainWindow];
}


-(void)	mainWindowChanged: (NSNotification*)notif
{
	NSWindow*		wd = notif.object;
	[self validateUIItemsForWindow: wd];
	
	[self positionToolbarOnScreen: wd.screen];
	
	if( mObservedMainWindow )
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidChangeScreenNotification object: mObservedMainWindow];
	mObservedMainWindow = wd;
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowDidChangeScreen:) name: NSWindowDidChangeScreenNotification object: mObservedMainWindow];
}


-(void)	screenConfigurationMayHaveChanged: (NSNotification*)notif
{
	NSWindow*		wd = [NSApplication sharedApplication].mainWindow;
	[self validateUIItemsForWindow: wd];
	
	[self positionToolbarOnScreen: wd.screen];
}


-(void)	mainWindowDidChangeScreen: (NSNotification*)notif
{
	NSWindow*		wd = [NSApplication sharedApplication].mainWindow;
	[self validateUIItemsForWindow: wd];
	
	[self positionToolbarOnScreen: wd.screen];
}


struct WILDAppDelegateValidatableButtonInfo
{
	NSButton	*	button;
	BOOL			enable;
};


-(void)	validateUIItemsForWindow: (NSWindow*)wd
{
	NSResponder*	currResponder = [wd firstResponder];
	WILDAppDelegateValidatableButtonInfo	buttons[] =
	{
		{ mBrowseToolButton, NO },
		{ mPointerToolButton, NO },
		{ mEditTextToolButton, NO },
		{ mOvalToolButton, NO },
		{ mRectangleToolButton, NO },
		{ mRoundrectToolButton, NO },
		{ mBezierPathToolButton, NO },
		{ mStackInfoButton, NO },
		{ mBackgroundInfoButton, NO },
		{ mCardInfoButton, NO },
		{ mEditBackgroundButton, NO },
		{ mMessageBoxButton, NO },
		{ mMessageWatcherButton, NO },
		{ mStackCanvasButton, NO },
		{ mGoPrevButton, NO },
		{ mGoNextButton, NO },
		{ nil, NO }
	};
	
	bool	didAppDelegateYet = NO;
	
	while( currResponder )
	{
		//UKLog(@"------");
		if( [currResponder respondsToSelector: @selector(validateUserInterfaceItem:)] )
		{
			id<NSUserInterfaceValidations>	uiv = (id<NSUserInterfaceValidations>)currResponder;
			
			for( int x = 0; buttons[x].button != nil; x++ )
			{
				if( [currResponder respondsToSelector: buttons[x].button.action] && [uiv validateUserInterfaceItem: (id<NSValidatedUserInterfaceItem>)buttons[x].button] )
				{
					buttons[x].enable = YES;
				}
				//UKLog(@"%@: %@ %s-> %s", currResponder, NSStringFromSelector(buttons[x].button.action), [currResponder respondsToSelector: buttons[x].button.action]? "(implemented) " :"", buttons[x].enable? "YES" : "no");
			}
		}
		else
			;//UKLog(@"%@", currResponder);
		
		currResponder = [currResponder respondsToSelector: @selector(nextResponder)] ? [currResponder nextResponder] : nil;
		
		if( !currResponder && !didAppDelegateYet )
		{
			didAppDelegateYet = YES;
			currResponder = (NSResponder*)[[NSApplication sharedApplication] delegate];
		}
	}
	
	for( int x = 0; buttons[x].button != nil; x++ )
	{
		[buttons[x].button setEnabled: buttons[x].enable];
		if( !buttons[x].enable )
			[buttons[x].button setState: NSOffState];
	}
}

@end
