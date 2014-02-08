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


using namespace Carlson;


static std::vector<CDocumentRef>		sOpenDocuments;


void	WILDFirstNativeCall( void );

void	WILDFirstNativeCall( void )
{
	LEOLoadNativeHeadersFromFile( [[NSBundle mainBundle] pathForResource: @"frameworkheaders" ofType: @"hhc"].fileSystemRepresentation );
}


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
	
	LEOSetFirstNativeCallCallback( WILDFirstNativeCall );	// This calls us to lazily load the (several MB) of native headers when needed.
	
	#if REMOTE_DEBUGGER
	LEOInitRemoteDebugger( "127.0.0.1" );
	#endif
	
	// Register Mac-specific variants of our card/background part classes:
	CStackMac::RegisterPartCreators();
	
	CMessageBox::SetSharedInstance( new CMessageBoxMac );
	CMessageWatcher::SetSharedInstance( new CMessageWatcherMac );
	CRecentCardsList::SetSharedInstance( new CRecentCardsListConcrete<CRecentCardInfo>() );
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
		for( auto currDoc : sOpenDocuments )
		{
			currDoc->SetPeeking( mPeeking == YES );
		}
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

	return [self application: NSApp openFile: [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"Home.xstk"]];
}


-(BOOL)	application:(NSApplication *)sender openFile:(NSString *)filename
{
	return [self application: (ULIURLHandlingApplication*)sender openURL: [NSURL fileURLWithPath: filename]];
}

-(BOOL)	application: (ULIURLHandlingApplication*)sender openURL: (NSURL*)theFile
{
	Carlson::CDocumentMac::SetStandardResourcesPath( [[[NSBundle mainBundle] pathForResource: @"resources" ofType: @"xml"] UTF8String] );
	
	std::string		fileURL( theFile.absoluteString.UTF8String );
	fileURL.append("/project.xml");
	size_t	foundPos = fileURL.find("x-stack://");
	size_t	foundPos2 = fileURL.find("file://");
    if( foundPos == 0 )
		fileURL.replace(foundPos, 10, "http://");
	else if( foundPos2 == 0 )
	{
		NSError		*		err = nil;
		if( ![[NSURL URLWithString: [NSString stringWithUTF8String: fileURL.c_str()]]checkResourceIsReachableAndReturnError: &err] )	// File not found?
		{
			fileURL = theFile.absoluteString.UTF8String;
			fileURL.append("/toc.xml");	// +++ old betas used toc.xml for the main file.
		}
	}
	
	sOpenDocuments.push_back( new CDocumentMac() );
	CDocumentRef	currDoc = sOpenDocuments.back();
	
	currDoc->LoadFromURL( fileURL, [self](Carlson::CDocument * inDocument)
	{
		Carlson::CStack		*		theCppStack = inDocument->GetStack( 0 );
		if( !theCppStack )
		{
			std::stringstream	errMsg;
			errMsg << "Can't find stack at " << inDocument->GetURL() << ".";
			CAlert::RunMessageAlert( errMsg.str() );
			return;
		}
		theCppStack->Load( [inDocument,self](Carlson::CStack* inStack)
		{
			inStack->GetCard(0)->Load( [inDocument,inStack,self](Carlson::CLayer*inCard)
			{
				inCard->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL );
			} );
		} );
	});
	
	return YES;	// We show our own errors asynchronously.
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
	else
		return [self respondsToSelector: inItem.action];
}


-(NSString*)	feedURLStringForUpdater: (SUUpdater*)inUpdater
{
	return @"http://stacksmith.org/nightlies/stacksmith_nightlies.rss";
}

@end
