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
#import "LEOFileInstructionsGeneric.h"
#import "WILDGlobalProperties.h"
#import "WILDHostCommands.h"
#import "WILDHostFunctions.h"
#import "LEORemoteDebugger.h"
#import "UKCrashReporter.h"
#include "CDocumentMac.h"
#include "CStackMac.h"
#include "CMessageBoxMac.h"
#include "CMessageWatcherMac.h"
#include "CVariableWatcherMac.h"
#include "LEOObjCCallInstructions.h"
#import "ULIURLHandlingApplication.h"
#include "CAlert.h"
#import <Sparkle/Sparkle.h>
#include <ios>
#include <sstream>
#include "CRecentCardsList.h"
#import "UKHelperMacros.h"
#import "WILDStackWindowController.h"
#import "WILDTransitionFilter.h"


void*	kWILDAppDelegateMenuBarHeightKVOContext = &kWILDAppDelegateMenuBarHeightKVOContext;


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
		NSDictionary * initialDefaults = [NSDictionary dictionaryWithContentsOfURL: [[NSBundle mainBundle] URLForResource: @"WILDInitialUserDefaults" withExtension: @"plist"]];
		if( initialDefaults )
			[[NSUserDefaults standardUserDefaults] registerDefaults: initialDefaults];
		
		new CDocumentManagerMac;	// Create the singleton of our subclass.
		
		CDocument::LoadNewPartMenuItemsFromFilePath( [NSBundle.mainBundle pathForResource: @"new_part_descriptions" ofType: @"xml"].fileSystemRepresentation );
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowChanged:) name: NSWindowDidBecomeMainNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowMightHaveGoneAway:) name: NSWindowDidResignMainNotification object: nil];

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowMightHaveGoneAway:) name: NSWindowWillCloseNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(screenConfigurationMayHaveChanged:) name: NSApplicationDidChangeScreenParametersNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(toolMayHaveChanged:) name: WILDToolDidChangeNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowChanged:) name: NSWindowDidBecomeKeyNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowChanged:) name: NSWindowDidResignKeyNotification object: nil];
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
	LEOAddHostFunctionsAndOffsetInstructions( gPropertyHostFunctions, kFirstPropertyInstruction );
	LEOAddOperatorsAndOffsetInstructions( gPropertyOperators, kFirstPropertyInstruction );
	
		// Global properties:
	LEOAddInstructionsToInstructionArray( gGlobalPropertyInstructions, LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS, &kFirstGlobalPropertyInstruction );
	LEOAddGlobalPropertiesAndOffsetInstructions( gHostGlobalProperties, kFirstGlobalPropertyInstruction );

		// Internet protocol stuff:
	LEOAddInstructionsToInstructionArray( gDownloadInstructions, LEO_NUMBER_OF_DOWNLOAD_INSTRUCTIONS, &kFirstDownloadInstruction );
	LEOAddGlobalPropertiesAndOffsetInstructions( gDownloadGlobalProperties, kFirstDownloadInstruction );
	
		// File Access:
	LEOAddInstructionsToInstructionArray( gFileInstructions, LEO_NUMBER_OF_FILE_INSTRUCTIONS, &kFirstFileInstruction );
	LEOAddHostCommandsAndOffsetInstructions( gFileCommands, kFirstFileInstruction );
	LEOAddHostFunctionsAndOffsetInstructions( gFileHostFunctions, kFirstFileInstruction );
	
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
	
	struct TStringConstantEntry	visualEffectNames[] = {
		{ { EBarnIdentifier, EDoorIdentifier, EOpenIdentifier }, "barn door open", EVisualIdentifier },
		{ { EBarnIdentifier, EDoorIdentifier, ECloseIdentifier }, "barn door close", EVisualIdentifier },
		{ { EIrisIdentifier, EOpenIdentifier, ELastIdentifier_Sentinel }, "iris open", EVisualIdentifier },
		{ { EIrisIdentifier, ECloseIdentifier, ELastIdentifier_Sentinel }, "iris close", EVisualIdentifier },
		{ { EPushIdentifier, EUpIdentifier, ELastIdentifier_Sentinel }, "push up", EVisualIdentifier },
		{ { EPushIdentifier, EDownIdentifier, ELastIdentifier_Sentinel }, "push down", EVisualIdentifier },
		{ { EPushIdentifier, ELeftIdentifier, ELastIdentifier_Sentinel }, "push left", EVisualIdentifier },
		{ { EPushIdentifier, ERightIdentifier, ELastIdentifier_Sentinel }, "push right", EVisualIdentifier },
		{ { EScrollIdentifier, EUpIdentifier, ELastIdentifier_Sentinel }, "scroll up", EVisualIdentifier },
		{ { EScrollIdentifier, EDownIdentifier, ELastIdentifier_Sentinel }, "scroll down", EVisualIdentifier },
		{ { EScrollIdentifier, ELeftIdentifier, ELastIdentifier_Sentinel }, "scroll left", EVisualIdentifier },
		{ { EScrollIdentifier, ERightIdentifier, ELastIdentifier_Sentinel }, "scroll right", EVisualIdentifier },
		{ { EShrinkIdentifier, EToIdentifier, ETopIdentifier }, "shrink to top", EVisualIdentifier },
		{ { EShrinkIdentifier, EToIdentifier, ECenterIdentifier }, "shrink to center", EVisualIdentifier },
		{ { EShrinkIdentifier, EToIdentifier, EBottomIdentifier }, "shrink to bottom", EVisualIdentifier },
		{ { EStretchIdentifier, EFromIdentifier, ETopIdentifier }, "stretch from top", EVisualIdentifier },
		{ { EStretchIdentifier, EFromIdentifier, ECenterIdentifier }, "stretch from center", EVisualIdentifier },
		{ { EStretchIdentifier, EFromIdentifier, EBottomIdentifier }, "stretch from bottom", EVisualIdentifier },
		{ { EVenetianIdentifier, EBlindsIdentifier, ELastIdentifier_Sentinel }, "venetian blinds", EVisualIdentifier },
		{ { EWipeIdentifier, EUpIdentifier, ELastIdentifier_Sentinel }, "wipe up", EVisualIdentifier },
		{ { EWipeIdentifier, EDownIdentifier, ELastIdentifier_Sentinel }, "wipe down", EVisualIdentifier },
		{ { EWipeIdentifier, ELeftIdentifier, ELastIdentifier_Sentinel }, "wipe left", EVisualIdentifier },
		{ { EWipeIdentifier, ERightIdentifier, ELastIdentifier_Sentinel }, "wipe right", EVisualIdentifier },
		{ { EZoomIdentifier, ECloseIdentifier, ELastIdentifier_Sentinel }, "zoom close", EVisualIdentifier },
		{ { EZoomIdentifier, EInIdentifier, ELastIdentifier_Sentinel }, "zoom in", EVisualIdentifier },
		{ { EZoomIdentifier, EOpenIdentifier, ELastIdentifier_Sentinel }, "zoom open", EVisualIdentifier },
		{ { EZoomIdentifier, EOutIdentifier, ELastIdentifier_Sentinel }, "zoom out", EVisualIdentifier },
		{ { EVeryIdentifier, ESlowIdentifier, ELastIdentifier_Sentinel }, "very slow", ESpeedIdentifier },
		{ { EVeryIdentifier, ESlowlyIdentifier, ELastIdentifier_Sentinel }, "very slowly", ESpeedIdentifier },
		{ { ESlowIdentifier, ELastIdentifier_Sentinel, ELastIdentifier_Sentinel }, "slow", ESpeedIdentifier },
		{ { ESlowlyIdentifier, ELastIdentifier_Sentinel, ELastIdentifier_Sentinel }, "slowly", ESpeedIdentifier },
		{ { EFastIdentifier, ELastIdentifier_Sentinel, ELastIdentifier_Sentinel }, "fast", ESpeedIdentifier },
		{ { EVeryIdentifier, EFastIdentifier, ELastIdentifier_Sentinel }, "very fast", ESpeedIdentifier },
		{ { EButtonIdentifier, ELastIdentifier_Sentinel }, "button", EPartIdentifier },
		{ { EMenuItemIdentifier, ELastIdentifier_Sentinel }, "menuItem", EPartIdentifier },
		{ { EMenuIdentifier, EItemIdentifier, ELastIdentifier_Sentinel }, "menuItem", EPartIdentifier },
		{ { EMenuIdentifier, ELastIdentifier_Sentinel }, "menu", EPartIdentifier },
		{ { EFieldIdentifier, ELastIdentifier_Sentinel }, "field", EPartIdentifier },
		{ { EBrowserIdentifier, ELastIdentifier_Sentinel }, "browser", EPartIdentifier },
		{ { EMovieIdentifier, EPlayerIdentifier, ELastIdentifier_Sentinel }, "moviePlayer", EPartIdentifier },
		{ { ETimerIdentifier, ELastIdentifier_Sentinel }, "timer", EPartIdentifier },
//		{ { ERectangleIdentifier, ELastIdentifier_Sentinel }, "rectangle", EPartIdentifier },
//		{ { EPictureIdentifier, ELastIdentifier_Sentinel }, "picture", EPartIdentifier },
		{ { EGraphicIdentifier, ELastIdentifier_Sentinel }, "graphic", EPartIdentifier },
		{ { EBrowseIdentifier, ELastIdentifier_Sentinel }, "browse", EToolIdentifier },
		{ { EPointerIdentifier, ELastIdentifier_Sentinel }, "pointer", EToolIdentifier },
		{ { EEditIdentifier, ETextIdentifier, ELastIdentifier_Sentinel }, "edit text", EToolIdentifier },
		{ { EOvalIdentifier, ELastIdentifier_Sentinel }, "oval", EToolIdentifier },
		{ { ERectangleIdentifier, ELastIdentifier_Sentinel }, "rectangle", EToolIdentifier },
		{ { ERoundedIdentifier, ERectangleIdentifier, ELastIdentifier_Sentinel }, "rounded rectangle", EToolIdentifier },
		{ { ELineIdentifier, ELastIdentifier_Sentinel }, "line", EToolIdentifier },
		{ { EBezierIdentifier, EPathIdentifier, ELastIdentifier_Sentinel }, "bezier path", EToolIdentifier },
		{ { ECheckMarkIdentifier, ELastIdentifier_Sentinel, ELastIdentifier_Sentinel }, EMenuItemMarkCharChecked, ELastIdentifier_Sentinel },
		{ { EMixedMarkIdentifier, ELastIdentifier_Sentinel, ELastIdentifier_Sentinel }, EMenuItemMarkCharMixed, ELastIdentifier_Sentinel },
		{ { ELastIdentifier_Sentinel, ELastIdentifier_Sentinel, ELastIdentifier_Sentinel }, NULL, ELastIdentifier_Sentinel },
	};
	LEOAddStringConstants( visualEffectNames );
	
	#if REMOTE_DEBUGGER
	LEOInitRemoteDebugger( "127.0.0.1" );
	#endif
	
	// Register Mac-specific variants of our card/background part classes:
	CStackMac::RegisterPartCreators();
	
	CMessageBox::SetSharedInstance( new CMessageBoxMac );
	CMessageWatcher::SetSharedInstance( new CMessageWatcherMac );
	CVariableWatcher::SetSharedInstance( new CVariableWatcherMac );
	CRecentCardsList::SetSharedInstance( new CRecentCardsListConcrete<CRecentCardInfo>() );
	
	Carlson::CMediaCache::SetStandardResourcesPath( [[[NSBundle mainBundle] pathForResource: @"resources" ofType: @"xml"] UTF8String] );
}


-(NSEvent*)	handleFlagsChangedEvent: (NSEvent*)inEvent
{
	BOOL		peekingStateDidChange = NO;
	if( !mPeeking && ([inEvent modifierFlags] & NSEventModifierFlagOption)
		&& ([inEvent modifierFlags] & NSEventModifierFlagCommand) )
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
	
	size_t			numItems = CDocument::GetNewPartMenuItemCount();
	for( size_t x = 0; x < numItems; x++ )
	{
		NSMenuItem	*	theItem = [mNewObjectSeparator.menu addItemWithTitle: [NSString stringWithUTF8String: CDocument::GetNewPartMenuItemAtIndex(x).c_str()] action: @selector(newPart:) keyEquivalent: @""];
		theItem.tag = x;
	}
	
	mFlagsChangedEventMonitor = [[NSEvent addLocalMonitorForEventsMatchingMask: NSEventMaskFlagsChanged handler: ^(NSEvent* inEvent){ return [self handleFlagsChangedEvent: inEvent]; }] retain];
	
	[[NSColorPanel sharedColorPanel] setShowsAlpha: YES];
	
//	[WILDTransitionFilter registerFiltersFromFile: [[NSBundle mainBundle] pathForResource: @"TransitionMappings" ofType: @"plist"]];
	
	CStack::SetMainStackChangedCallback( [self]( CStack* inMainStack )
	{
		[mLockPseudoMenu setHidden: inMainStack == NULL || (inMainStack->GetEffectiveCantModify() == false)];
	} );
	CStack::SetActiveStackChangedCallback( [self]( CStack* inFrontStack )
	{
		if( CStack::GetMainStack() == NULL )	// User closed last document window?
			[mLockPseudoMenu setHidden: YES];
	} );
}


-(void)	applicationDidFinishLaunching:(NSNotification *)notification
{
	[self positionToolbarOnScreen: [[NSScreen screens] firstObject]];
	
	UKCrashReporterCheckForCrash();
	
	NSStatusItem	*	si = [[[NSStatusBar systemStatusBar] statusItemWithLength: 1.0] retain];
	[si.button.window addObserver: self forKeyPath: @"frame" options: 0 context: kWILDAppDelegateMenuBarHeightKVOContext];

	std::string		fileURL( [NSURL fileURLWithPath: self.homeStackPath].absoluteString.UTF8String );
	CDocumentManager::GetSharedDocumentManager()->OpenDocumentFromURL( fileURL,
	[fileURL]( CDocument * inNewDocument )
	{
        if( !inNewDocument )
        {
            std::stringstream	errMsg;
            errMsg << "Can't find home stack at " << fileURL << ".";
			CAlert::RunMessageAlert( errMsg.str(), "", "", "", []( size_t buttonNumber ){
				[[NSApplication sharedApplication] terminate: nil];
			} );
			return;
        }
		CDocumentManager::GetSharedDocumentManager()->SetHomeDocument( inNewDocument );
	}, "", EVisualEffectSpeedNormal, nullptr, EOpenInvisibly);
	
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
	NSRect		screenBox = scr.frame;
	box.origin.x = screenBox.origin.x;
	box.size.width = screenBox.size.width;
	box.origin.y = NSMaxY(screenBox) -box.size.height -[[[NSApplication sharedApplication] mainMenu] menuBarHeight];
	[mToolPanel setFrame: box display: YES];
	mToolPanel.movableByWindowBackground = NO;
	[mToolPanel orderFront: self];
}


-(IBAction) showStackCanvasWindow: (id)sender
{
	CDocumentManager	*dman = CDocumentManager::GetSharedDocumentManager();
	CDocument			*fdoc = dman->GetFrontDocument();
	if( fdoc )
		fdoc->ShowStackCanvasWindow();
}


-(IBAction)	openDocument: (id)sender
{
	NSOpenPanel*	thePanel = [NSOpenPanel openPanel];
	[thePanel setAllowedFileTypes: @[ @"xstk" ]];
	[thePanel beginWithCompletionHandler:^(NSInteger result)
	{
		if( result == NSModalResponseOK )
		{
			for( NSURL* theFile in thePanel.URLs )
			{
				[self application: NSApp openURL: theFile];
			}
		}
	}];
}


-(NSString*)	homeStackPath
{
	NSString*	homeStackName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"WILDHomeStack"];
	NSString*	thePath = [[NSBundle mainBundle] pathForResource: homeStackName ofType: @"xstk"];
	if( !thePath )
	{
		thePath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: [homeStackName stringByAppendingString: @".xstk"]];
	}
	return thePath;
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

	return [self application: NSApp openFile: self.homeStackPath];
}


-(IBAction)	goHome: (id)sender
{
	[self application: NSApp openFile: self.homeStackPath];
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
	[fileURL]( CDocument * inNewDocument )
	{
        if( !inNewDocument )
        {
            std::stringstream	errMsg;
            errMsg << "Can't find stack at " << fileURL << ".";
			CAlert::RunMessageAlert( errMsg.str(), "", "", "", [](size_t){} );
        }
	}, "", EVisualEffectSpeedNormal, CDocumentManager::GetSharedDocumentManager()->GetHomeDocument()->GetScriptContextGroupObject(), EOpenVisibly);
	
	return YES;	// We show our own errors asynchronously.
}


-(IBAction)	newDocumentFromTemplate: (id)sender
{
	NSString * inSelectedPath = [NSBundle.mainBundle pathForResource: @"Empty Project" ofType: @"xstk" inDirectory: @"Project Templates/Empty Stacks"];
	
	NSSavePanel		*	savePanel = [NSSavePanel savePanel];
	savePanel.allowedFileTypes = @[@"xstk"];
	savePanel.allowsOtherFileTypes = NO;
	savePanel.canCreateDirectories = YES;
	savePanel.canSelectHiddenExtension = YES;
	savePanel.showsTagField = YES;
	savePanel.nameFieldStringValue = [inSelectedPath lastPathComponent];
	
	[savePanel beginWithCompletionHandler: ^(NSInteger result) {
		if( result == NSModalResponseCancel )
			return;
		
		NSError	*	err = nil;
		NSString*	newPath = savePanel.URL.path;
		[[NSFileManager defaultManager] removeItemAtPath: newPath error: &err];
		
		NSArray	*	filesInTemplate = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: inSelectedPath error:&err];
		if( [filesInTemplate containsObject: @"_new_empty_file_template"] )
		{
			CAutoreleasePool	pool;
			NSURL		*	newFileURL = [NSURL fileURLWithPath: newPath];
			CDocumentMac*	theDoc = new CDocumentMac( CDocumentManager::GetSharedDocumentManager()->GetHomeDocument()->GetScriptContextGroupObject() );
			CDocumentManager::GetSharedDocumentManager()->AddDocument( theDoc );
			theDoc->CreateAtURL( [newFileURL URLByAppendingPathComponent: @"project.xml"].absoluteString.UTF8String, [[newFileURL lastPathComponent] stringByDeletingPathExtension].UTF8String );
			[newFileURL setResourceValue: @YES forKey: NSURLIsPackageKey error: NULL];
			[newFileURL setResourceValue: savePanel.tagNames forKey: NSURLTagNamesKey error: NULL];
			
			theDoc->GetStack(0)->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [](){  }, "", EVisualEffectSpeedNormal );
			theDoc->Release();
		}
		else
		{
			if( ![[NSFileManager defaultManager] copyItemAtPath: inSelectedPath toPath: newPath error: &err])
			{
				[[NSApplication sharedApplication] presentError: err];
				return;
			}
			NSString*		stackName = [[newPath lastPathComponent] stringByDeletingPathExtension];
			NSArray	*		filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: newPath error: NULL];
			for( NSString* currName in filenames )
			{
				if( [currName hasPrefix: @"."] )
					continue;
				if( [currName hasSuffix: @".xml"] )
				{
					NSString*	templatePath = [newPath stringByAppendingPathComponent: currName];
					[self replacePlaceholdersInTemplateFileAtPath: templatePath withStackName: stackName];
				}
			}
			
			NSURL		*	newFileURL = [NSURL fileURLWithPath: newPath];
			[newFileURL setResourceValue: @YES forKey: NSURLIsPackageKey error: NULL];
			[newFileURL setResourceValue: savePanel.tagNames forKey: NSURLTagNamesKey error: NULL];
			
			[self application: [NSApplication sharedApplication] openURL: newFileURL];
		}
	}];
}


-(NSString*)	htmlSafeString: (NSString*)inStr
{
	NSMutableString*	safeString = [[inStr mutableCopy] autorelease];
	[safeString replaceOccurrencesOfString: @"&" withString: @"&nbsp;" options: 0 range: NSMakeRange(0,safeString.length)];
	[safeString replaceOccurrencesOfString: @"<" withString: @"&lt;" options: 0 range: NSMakeRange(0,safeString.length)];
	[safeString replaceOccurrencesOfString: @">" withString: @"&gt;" options: 0 range: NSMakeRange(0,safeString.length)];
	return safeString;
}


-(void)	replacePlaceholdersInTemplateFileAtPath: (NSString*)filePath withStackName: (NSString*)stackName
{
	
	NSMutableString* fileContents = [NSMutableString stringWithContentsOfFile: filePath encoding: NSUTF8StringEncoding error: NULL];
	[fileContents replaceOccurrencesOfString: @"%%STACKNAME" withString: [self htmlSafeString: stackName] options: 0 range: NSMakeRange(0,fileContents.length)];
	[fileContents replaceOccurrencesOfString: @"%%USERNAME" withString: [self htmlSafeString: NSFullUserName()] options: 0 range: NSMakeRange(0,fileContents.length)];
	[fileContents replaceOccurrencesOfString: @"%%SHORTUSERNAME" withString: [self htmlSafeString: NSUserName()] options: 0 range: NSMakeRange(0,fileContents.length)];
	[fileContents writeToFile: filePath atomically: YES encoding: NSUTF8StringEncoding error: NULL];
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
		if( result == NSModalResponseCancel )
			return;
		
		NSError	*	err = nil;
		[[NSFileManager defaultManager] removeItemAtPath: savePanel.URL.path error: &err];
		
        try
        {
            CDocumentMac*	theDoc = new CDocumentMac(nullptr);
            CDocumentManager::GetSharedDocumentManager()->AddDocument( theDoc );
            theDoc->CreateAtURL( [savePanel.URL URLByAppendingPathComponent: @"project.xml"].absoluteString.UTF8String );
			[savePanel.URL setResourceValue: @YES forKey: NSURLIsPackageKey error: NULL];
			[savePanel.URL setResourceValue: savePanel.tagNames forKey: NSURLTagNamesKey error: NULL];
            
            theDoc->GetStack(0)->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [](){  }, "", EVisualEffectSpeedNormal );
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


-(IBAction)	orderFrontVariableWatcher: (id)sender
{
	CVariableWatcher::GetSharedInstance()->SetVisible( !CVariableWatcher::GetSharedInstance()->IsVisible() );
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
	else if( inItem.action == @selector(orderFrontVariableWatcher:) )
	{
		if( CVariableWatcher::GetSharedInstance()->IsVisible() )
			[inItem setTitle: @"Hide Variable Watcher"];
		else
			[inItem setTitle: @"Show Variable Watcher"];
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
	return @"https://stacksmith.org/nightlies/stacksmith_nightlies.rss";
}


-(void)	checkForScriptToResume: (id)sender
{
    CAutoreleasePool    pool;
    
	LEOContextResumeIfAvailable();
}


-(void)	toolMayHaveChanged: (NSNotification*)notif
{
	//UKLog(@"changed? %@ %@",notif.name,[NSApplication sharedApplication].mainWindow.title);
	[self validateUIItemsForWindow: [NSApplication sharedApplication].mainWindow];
}


-(void)	mainWindowMightHaveGoneAway: (NSNotification*)notif
{
	if( mObservedMainWindow && [NSApplication sharedApplication].mainWindow != mObservedMainWindow )
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidChangeScreenNotification object: mObservedMainWindow];
		mObservedMainWindow = nil;
	}
	//UKLog(@"main gone away? %@ %@",notif.name,[NSApplication sharedApplication].mainWindow.title);
	[self validateUIItemsForWindow: [NSApplication sharedApplication].mainWindow];
}


-(void)	mainWindowChanged: (NSNotification*)notif
{
	NSWindow*		wd = notif.object;
	NSWindow*		mainWd = [NSApplication sharedApplication].mainWindow;
	if( mainWd )
		[self validateUIItemsForWindow: mainWd];
	//UKLog(@"main changed? %@ %@ %@",notif.name,wd.title,[NSApplication sharedApplication].mainWindow.title);
	
	if( wd )
	{
		[self positionToolbarOnScreen: wd.screen];
	}
	
	if( mObservedMainWindow )
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidChangeScreenNotification object: mObservedMainWindow];
	}
	mObservedMainWindow = wd;
	if( wd )
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowDidChangeScreen:) name: NSWindowDidChangeScreenNotification object: mObservedMainWindow];
	}
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
		{ mLineToolButton, NO },
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
			[buttons[x].button setState: NSControlStateValueOff];
	}
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	if( context == kWILDAppDelegateMenuBarHeightKVOContext )
	{
		CAutoreleasePool	pool;
		NSScreen	*theScreen = [[NSApplication sharedApplication] mainWindow].screen;
		if( !theScreen )
			theScreen = [NSScreen mainScreen];
		if( !theScreen )
			theScreen = [NSScreen screens][0];
		[self positionToolbarOnScreen: theScreen];
		
		CStack	*	frontStack = CStack::GetActiveStack();
		CCard	*	frontCard = nullptr;
		if( frontStack )
			frontCard = frontStack->GetCurrentCard();
		if( frontCard )
		{
			frontCard->SendMessage( NULL, [](const char*,size_t,size_t,CScriptableObject*,bool){}, EMayGoUnhandled, "menuBarHeightChange %f", [[[NSApplication sharedApplication] mainMenu] menuBarHeight] );
		}
	}
}

@end
