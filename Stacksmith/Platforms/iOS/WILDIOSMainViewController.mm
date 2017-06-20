//
//  WILDIOSMainViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 17.06.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#import "WILDIOSMainViewController.h"
#import "Forge.h"
#import "WILDHostCommands.h"
#import "WILDHostFunctions.h"
#import "LEORemoteDebugger.h"
#include "CRecentCardsList.h"
#include "CDocument.h"
#include "CStack.h"
#include "CMessageBox.h"
#include "CMessageWatcher.h"
#include "CVariableWatcher.h"
#include "CDocumentIOS.h"
#include "CAlert.h"
#include <sstream>


using namespace Carlson;


@interface WILDIOSMainViewController ()

-(void) checkForScriptToResume: (id)sender;

@end

static WILDIOSMainViewController * sSharedMainViewController;


static inline unsigned TimeToUnsigned( time_t inTime ) { return (unsigned)inTime; }	// Typecast that breaks when srand's type ever changes during a port.

void	WILDFirstNativeCall( void );

void	WILDFirstNativeCall( void )
{
	LEOLoadNativeHeadersFromFile( [[NSBundle mainBundle] pathForResource: @"frameworkheaders" ofType: @"hhc"].fileSystemRepresentation );
}


void	WILDScheduleResumeOfScript( void );

void	WILDScheduleResumeOfScript( void )
{
	[sSharedMainViewController performSelector: @selector(checkForScriptToResume:) withObject: nil afterDelay: 0.0];
}



@implementation WILDIOSMainViewController

+(WILDIOSMainViewController*) sharedMainViewController
{
	return sSharedMainViewController;
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	srand( TimeToUnsigned(time(NULL)) );

	sSharedMainViewController = self;
	
	new CDocumentManagerIOS;	// Create the singleton of our subclass.
	
	CDocument::LoadNewPartMenuItemsFromFilePath( [NSBundle.mainBundle pathForResource: @"new_part_descriptions" ofType: @"xml"].fileSystemRepresentation );

	LEOInitInstructionArray();
	
	// Add various instruction functions to the base set of instructions the
	//	interpreter knows. First add those that the compiler knows to parse,
	//	but which have a platform/host-specific implementation:
	// Object properties:
	LEOAddInstructionsToInstructionArray( gPropertyInstructions, LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS, &kFirstPropertyInstruction );
	LEOAddHostFunctionsAndOffsetInstructions( gPropertyHostFunctions, kFirstPropertyInstruction );
	LEOAddOperatorsAndOffsetInstructions( gPropertyOperators, kFirstPropertyInstruction );
	
	// Global properties:
//	LEOAddInstructionsToInstructionArray( gGlobalPropertyInstructions, LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS, &kFirstGlobalPropertyInstruction );
//	LEOAddGlobalPropertiesAndOffsetInstructions( gHostGlobalProperties, kFirstGlobalPropertyInstruction );
	
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
//	CStack::RegisterPartCreators();
	
	CMessageBox::SetSharedInstance( new CMessageBox );
	CMessageWatcher::SetSharedInstance( new CMessageWatcher );
	CVariableWatcher::SetSharedInstance( new CVariableWatcher );
	CRecentCardsList::SetSharedInstance( new CRecentCardsListConcrete<CRecentCardInfo>() );
	
	Carlson::CMediaCache::SetStandardResourcesPath( [[[NSBundle mainBundle] pathForResource: @"resources" ofType: @"xml"] UTF8String] );
	
	[self goHome];
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


-(void) goHome
{
	NSURL		*	theFile = [NSURL fileURLWithPath: self.homeStackPath];
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
																		  CDocumentManager::GetSharedDocumentManager()->SetHomeDocument( inNewDocument );
																	  }, "", EVisualEffectSpeedNormal, nullptr, EOpenInvisibly);
	if( !CDocumentManager::GetSharedDocumentManager()->HaveDocuments() )
		[self openURL: theFile];
}


-(void)	openURL: (NSURL*)theFile
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
}


-(void) checkForScriptToResume: (id)sender
{
	CAutoreleasePool    pool;
	
	LEOContextResumeIfAvailable();
}


- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end
