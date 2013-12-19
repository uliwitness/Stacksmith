//
//  WILDScriptEditorWindowController.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDScriptEditorWindowController.h"
#import "WILDScriptContainer.h"
#import "UKSyntaxColoredTextViewController.h"
#import "NSWindow+ULIZoomEffect.h"


@implementation WILDScriptEditorWindowController

-(id)	initWithScriptContainer: (id<WILDScriptContainer>)inContainer
{
	if(( self = [super initWithWindowNibName: NSStringFromClass( [self class] )] ))
	{
		mContainer = inContainer;
	}
	
	return self;
}


-(void)	dealloc
{
	mContainer = nil;
	
	[mSymbols release];
	mSymbols = nil;
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	NSArray*		symbols = nil;
	NSRange			selRange = { 0, 0 };
	NSString*		theScript = [mContainer script];
	if( [theScript length] == 0 && [mContainer respondsToSelector: @selector(defaultScriptReturningSelectionRange:)] )
		theScript = [mContainer defaultScriptReturningSelectionRange: &selRange];
	[mTextView setString: WILDFormatScript( theScript, &symbols )];
	[mTextView setSelectedRange: selRange];
	[mSymbols release];
	mSymbols = [symbols retain];
	
	[mPopUpButton removeAllItems];
	if( [mSymbols count] > 0 )
	{
		for( WILDSymbol* currSym in mSymbols )
		{
			[mPopUpButton addItemWithTitle: [currSym symbolName]];
			NSMenuItem*	theItem = [mPopUpButton lastItem];
			[theItem setImage: [NSImage imageNamed: ([currSym symbolType] == WILDSymbolTypeFunction) ? @"HandlerPopupFunction" : @"HandlerPopupMessage"]];
		}
		[mPopUpButton setEnabled: YES];
	}
	else
	{
		[mPopUpButton addItemWithTitle: @"None"];
		[mPopUpButton setEnabled: NO];
	}
}


-(void)	showWindow:(id)sender
{
	NSWindow	*	theWindow = [self window];
	
	[theWindow makeKeyAndOrderFrontWithZoomEffectFromRect: mGlobalStartRect];
}


-(BOOL)	windowShouldClose: (id)sender
{
	NSWindow	*	theWindow = [self window];
	
	[theWindow orderOutWithZoomEffectToRect: mGlobalStartRect];
	
	return YES;
}


-(void)	windowWillClose: (NSNotification*)notification
{
	[mContainer setScript: [mTextView string]];
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	NSButton*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	[btn setImage: [mContainer displayIcon]];
}

-(IBAction)	handlerPopupSelectionChanged: (id)sender
{
	NSInteger			idx = [mPopUpButton indexOfSelectedItem];
	WILDSymbol* currSym = [mSymbols objectAtIndex: idx];
	[mSyntaxController goToLine: [currSym lineIndex] +1];
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%1$@’s Script", [mContainer displayName]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@’s Script", [mContainer displayName]]
											action: nil keyEquivalent: @"" atIndex: 0];
	[newItem setImage: [mContainer displayIcon]];
	
	return YES;
}


-(void)		setGlobalStartRect: (NSRect)theBox
{
	mGlobalStartRect = theBox;
}


-(void)		goToLine: (NSUInteger)lineNum
{
	[mSyntaxController goToLine: lineNum];
}


-(void)		goToCharacter: (NSUInteger)charNum
{
	[mSyntaxController goToCharacter: charNum];
}

@end
