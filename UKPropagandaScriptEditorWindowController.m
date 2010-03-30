//
//  UKPropagandaScriptEditorWindowController.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaScriptEditorWindowController.h"
#import "UKPropagandaScriptContainer.h"
#import "UKSyntaxColoredTextViewController.h"


@implementation UKPropagandaScriptEditorWindowController

-(id)	initWithScriptContainer: (id<UKPropagandaScriptContainer>)inContainer
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
	[mTextView setString: UKPropagandaFormatScript( [mContainer script], &symbols )];
	[mSymbols release];
	mSymbols = [symbols retain];
	
	[mPopUpButton removeAllItems];
	if( [mSymbols count] > 0 )
	{
		for( UKPropagandaSymbol* currSym in mSymbols )
		{
			[mPopUpButton addItemWithTitle: [currSym symbolName]];
			NSMenuItem*	theItem = [mPopUpButton lastItem];
			[theItem setImage: [NSImage imageNamed: ([currSym symbolType] == UKPropagandaSymbolTypeFunction) ? @"HandlerPopupFunction" : @"HandlerPopupMessage"]];
		}
		[mPopUpButton setEnabled: YES];
	}
	else
	{
		[mPopUpButton addItemWithTitle: @"None"];
		[mPopUpButton setEnabled: NO];
	}
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
	UKPropagandaSymbol* currSym = [mSymbols objectAtIndex: idx];
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

@end
