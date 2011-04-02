//
//  WILDFieldInfoWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 03.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDFieldInfoWindowController.h"
#import "WILDPart.h"
#import "WILDPartContents.h"
#import "WILDCard.h"
#import "WILDStack.h"
#import "WILDCardView.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDNotifications.h"


static 	NSArray*	sStylesInMenuOrder = nil;
	



@implementation WILDFieldInfoWindowController

-(id)	initWithPart: (WILDPart*)inPart ofCardView: (WILDCardView*)owningView
{
	if( !sStylesInMenuOrder )
		sStylesInMenuOrder = [[NSArray alloc] initWithObjects:
													@"transparent",
													@"opaque",
													@"rectangle",
													@"roundrect",
													@"shadow",
													@"scrolling",
													nil];
	
	if(( self = [super initWithWindowNibName: NSStringFromClass([self class])] ))
	{
		mPart = inPart;
		mCardView = owningView;
		
		[self setShouldCascadeWindows: NO];
	}
	
	return self;
}


-(void)	dealloc
{
	[super dealloc];
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	[mNameField setStringValue: [mPart name]];
	
	NSString*	layerName = [[mPart partLayer] capitalizedString];
	[mButtonNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Field Number:", layerName]];
	[mButtonNumberField setIntegerValue: [mPart partNumberAmongPartsOfType: @"field"] +1];
	[mPartNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Part Number:", layerName]];
	[mPartNumberField setIntegerValue: [mPart partNumber] +1];
	[mIDLabel setStringValue: [NSString stringWithFormat: @"%@ Field ID:", layerName]];
	[mIDField setIntegerValue: [mPart partID]];
	
	[mLockTextSwitch setState: [mPart lockText]];
	[mDontWrapSwitch setState: [mPart dontWrap]];
	[mAutoSelectSwitch setState: [mPart autoSelect]];
	[mMultipleLinesSwitch setState: [mPart canSelectMultipleLines]];
	[mWideMarginsSwitch setState: [mPart wideMargins]];
	[mFixedLineHeightSwitch setState: [mPart fixedLineHeight]];
	[mShowLinesSwitch setState: [mPart showLines]];
	[mAutoTabSwitch setState: [mPart autoTab]];
	[mDontSearchSwitch setState: [mPart dontSearch]];
	[mSharedTextSwitch setState: [mPart sharedText]];
	[mSharedTextSwitch setEnabled: [[mPart partLayer] isEqualToString: @"background"]];
	[mEnabledSwitch setState: [mPart isEnabled]];
	[mVisibleSwitch setState: [mPart visible]];
	
	[mStylePopUp selectItemAtIndex: [sStylesInMenuOrder indexOfObject: [mPart style]]];
	
	WILDPartContents*	theContents = nil;
	if( [mPart sharedText] )
		theContents = [[[mCardView card] owningBackground] contentsForPart: mPart];
	else
		theContents = [[mCardView card] contentsForPart: mPart];
	NSAttributedString*			contentsStr = [theContents styledTextForPart: mPart];
	if( contentsStr )
		[[mContentsTextField textStorage] setAttributedString: contentsStr];
	else
		[mContentsTextField setString: @""];
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%@ Info", [mPart displayName]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@ Info", [mPart displayName]]
											action: nil keyEquivalent: @"" atIndex: 0];
	[newItem setImage: [mPart displayIcon]];
	
	return YES;
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	NSButton*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	[btn setImage: [mPart displayIcon]];
}


-(IBAction)	showWindow: (id)sender
{
	NSWindow*	theWindow = [self window];
	NSRect		buttonRect = [mPart rectangle];
	buttonRect = [mCardView convertRectToBase: buttonRect];
	buttonRect.origin = [[mCardView window] convertBaseToScreen: buttonRect.origin];
	
	[theWindow makeKeyAndOrderFrontWithZoomEffectFromRect: buttonRect];
}


-(IBAction)	doOKButton: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: mPart];

	[mPart setName: [mNameField stringValue]];
	
	[mPart setLockText: [mLockTextSwitch state] == NSOnState];
	[mPart setDontWrap: [mDontWrapSwitch state] == NSOnState];
	[mPart setAutoSelect: [mAutoSelectSwitch state] == NSOnState];
	[mPart setCanSelectMultipleLines: [mMultipleLinesSwitch state] == NSOnState];
	[mPart setWideMargins: [mWideMarginsSwitch state] == NSOnState];
	[mPart setFixedLineHeight: [mFixedLineHeightSwitch state] == NSOnState];
	[mPart setShowLines: [mShowLinesSwitch state] == NSOnState];
	[mPart setAutoTab: [mAutoTabSwitch state] == NSOnState];
	[mPart setDontSearch: [mDontSearchSwitch state] == NSOnState];
	[mPart setSharedText: [mSharedTextSwitch state] == NSOnState];
	[mPart setEnabled: [mEnabledSwitch state] == NSOnState];
	[mPart setVisible: [mVisibleSwitch state] == NSOnState];
	
	[mPart setStyle: [sStylesInMenuOrder objectAtIndex: [mStylePopUp indexOfSelectedItem]]];
	
	WILDPartContents*	theContents = nil;
	if( [mPart sharedText] )
		theContents = [[[mCardView card] owningBackground] contentsForPart: mPart];
	else
		theContents = [[mCardView card] contentsForPart: mPart];
	[theContents setStyledText: [mContentsTextField textStorage]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: mPart];
	
	[mPart updateChangeCount: NSChangeDone];
	
	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mPart] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doCancelButton: (id)sender
{
	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mPart] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doEditScriptButton: (id)sender
{
	NSRect		box = [mEditScriptButton convertRect: [mEditScriptButton bounds] toView: nil];
	NSRect		wFrame = [[self window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDScriptEditorWindowController*	se = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mPart] autorelease];
	[se setGlobalStartRect: box];
	[[[[self window] windowController] document] addWindowController: se];
	[se showWindow: self];
}

@end
