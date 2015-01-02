//
//  WILDScriptEditorWindowController.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDScriptEditorWindowController.h"
#import "UKSyntaxColoredTextViewController.h"
#import "NSWindow+ULIZoomEffect.h"
#include "Forge.h"
#include "CMacPartBase.h"
#include "CStackMac.h"
#include "CDocument.h"
#import "UKHelperMacros.h"


using namespace Carlson;


static NSString	*	WILDScriptEditorTopAreaToolbarItemIdentifier = @"WILDScriptEditorTopAreaToolbarItemIdentifier";



@protocol WILDScriptEditorHandlerListDelegate <NSObject>

-(void)	scriptEditorAddHandlersPopupDidSelectHandler: (NSDictionary*)inDictionary;

@end


@interface WILDScriptEditorHandlerListPopoverViewController : NSViewController <NSTableViewDataSource>
{
	NSArray*		mHandlerList;
}

@property (nonatomic,assign) IBOutlet NSTableView*		handlersTable;
@property (nonatomic,assign) id<WILDScriptEditorHandlerListDelegate>	delegate;

@end


@implementation WILDScriptEditorHandlerListPopoverViewController

-(id)	initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
	if( self )
	{
		ASSIGN(mHandlerList,[NSArray arrayWithContentsOfFile: [[NSBundle bundleForClass: [self class]] pathForResource: @"WILDAddHandlersList" ofType: @"plist"]]);
	}
	return self;
}


-(void)	dealloc
{
	DESTROY_DEALLOC(mHandlerList);
	[super dealloc];
}


-(NSInteger)	numberOfRowsInTableView: (NSTableView *)tableView
{
	return mHandlerList.count;
}


-(id)	tableView: (NSTableView *)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	return [[mHandlerList objectAtIndex: row] objectForKey: @"WILDHandlerName"];
}


-(BOOL)	tableView: (NSTableView *)tableView isGroupRow: (NSInteger)row
{
	return [[[mHandlerList objectAtIndex: row] objectForKey: @"WILDHandlerGroupRow"] boolValue];
}


-(NSString *)	tableView: (NSTableView *)tableView toolTipForCell: (NSCell *)cell rect: (NSRectPointer)rect tableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row mouseLocation: (NSPoint)mouseLocation
{
	if( ![[[mHandlerList objectAtIndex: row] objectForKey: @"WILDHandlerGroupRow"] boolValue] )
	{
		return [NSString stringWithFormat: @"%@ - %@", [[mHandlerList objectAtIndex: row] objectForKey: @"WILDHandlerName"], [[mHandlerList objectAtIndex: row] objectForKey: @"WILDHandlerDescription"]];
	}
	else
		return [[mHandlerList objectAtIndex: row] objectForKey: @"WILDHandlerName"];
}


-(void)	tableViewSelectionDidChange: (NSNotification*)notif
{
	[self.delegate scriptEditorAddHandlersPopupDidSelectHandler: [mHandlerList objectAtIndex: self.handlersTable.selectedRow]];
}

@end


@interface WILDScriptEditorWindowController () <NSToolbarDelegate,NSPopoverDelegate,WILDScriptEditorHandlerListDelegate>

@end


@implementation WILDScriptEditorWindowController

-(id)	initWithScriptContainer: (CConcreteObject*)inContainer
{
	if(( self = [super initWithWindowNibName: NSStringFromClass( [self class] )] ))
	{
		mContainer = inContainer;
	}
	
	return self;
}


-(void)	dealloc
{
	mContainer = NULL;
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	[self formatText];
	
	NSToolbar	*	editToolbar = [[[NSToolbar alloc] initWithIdentifier: @"WILDScriptEditorToolbar"] autorelease];
	[editToolbar setDelegate: self];
	[editToolbar setAllowsUserCustomization: NO];
	[editToolbar setVisible: NO];
	[editToolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
	[editToolbar setSizeMode: NSToolbarSizeModeSmall];
	[self.window setToolbar: editToolbar];
	[self.window toggleToolbarShown: self];
}


-(void)	formatText
{
	char*			theText = NULL;
	size_t			theTextLen = 0;
	NSRange			selRange = mTextView.selectedRange;
	size_t			cursorPos = selRange.location,
					cursorEndPos = selRange.location +selRange.length;
	size_t			theLine = 0;
	size_t			errOffset = 0;
	size_t			x = 0;
	const char*		currErrMsg = "";
	LEOParseTree*	parseTree = LEOParseTreeCreateFromUTF8Characters( mContainer->GetScript().c_str(), mContainer->GetScript().length(), 0 );
	for( x = 0; currErrMsg != NULL; x++ )
	{
		LEOParserGetNonFatalErrorMessageAtIndex( x, &currErrMsg, &theLine, &errOffset );
		if( !currErrMsg )
			break;
		fprintf( stderr, "Error: %s\n", currErrMsg );
	}
	LEODisplayInfoTable*	displayInfo = LEODisplayInfoTableCreateForParseTree( parseTree );
	LEODisplayInfoTableApplyToText( displayInfo, mContainer->GetScript().c_str(), mContainer->GetScript().length(), &theText, &theTextLen, &cursorPos, &cursorEndPos );
	NSString	*	formattedText = [[[NSString alloc] initWithBytesNoCopy: theText length: theTextLen encoding: NSUTF8StringEncoding freeWhenDone: YES] autorelease];
	[mTextView setString: formattedText];
	[mTextView setSelectedRange: NSMakeRange(cursorPos,cursorEndPos -cursorPos)];
	
	[mPopUpButton removeAllItems];
	const char*	theName = "";
	
	bool		isCommand = false;
	for( x = 0; theName != NULL; x++ )
	{
		LEODisplayInfoTableGetHandlerInfoAtIndex( displayInfo, x, &theName, &theLine, &isCommand );
		if( !theName ) break;
		if( theName[0] == ':' )	// Skip any fake internal handlers we add.
			continue;
		NSMenuItem*	theItem = [mPopUpButton.menu addItemWithTitle: [NSString stringWithUTF8String: theName] action: Nil keyEquivalent: @""];
		[theItem setImage: [NSImage imageNamed: isCommand ? @"HandlerPopupMessage" : @"HandlerPopupFunction"]];
		[theItem setRepresentedObject: @(theLine)];
	}
	LEOCleanUpDisplayInfoTable( displayInfo );
	LEOCleanUpParseTree( parseTree );
	
	if( x == 0 )	// We added no items?
	{
		[mPopUpButton addItemWithTitle: @"None"];
		[mPopUpButton setEnabled: NO];
	}
}


-(void)	showWindow:(id)sender
{
	NSWindow	*	theWindow = [self window];
	NSURL		*	theURL = [NSURL URLWithString: [NSString stringWithUTF8String: mContainer->GetDocument()->GetURL().c_str()]];
	[theWindow setTitleWithRepresentedFilename: theURL.path];

	NSButton				*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	CMacScriptableObjectBase*	macPart = dynamic_cast<CMacScriptableObjectBase*>(mContainer);
	if( macPart )
		[btn setImage: macPart->GetDisplayIcon()];
	[theWindow setTitle: [self windowTitleForDocumentDisplayName: nil]];
	
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
	mContainer->SetScript( std::string(mTextView.string.UTF8String, [mTextView.string lengthOfBytesUsingEncoding: NSUTF8StringEncoding]) );
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	NSButton*					btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	CMacScriptableObjectBase*	macPart = dynamic_cast<CMacScriptableObjectBase*>(mContainer);
	if( macPart )
		[btn setImage: macPart->GetDisplayIcon()];
}


-(IBAction)	handlerPopupSelectionChanged: (id)sender
{
	NSNumber*	destLineObj = [mPopUpButton.selectedItem representedObject];
	[mSyntaxController goToLine: [destLineObj integerValue]];
}


-(IBAction)	addHandler: (id)sender
{
	if( mAddHandlersPopover )
	{
		[mAddHandlersPopover close];
	}
	else
	{
		mAddHandlersPopover = [[NSPopover alloc] init];
		WILDScriptEditorHandlerListPopoverViewController	*	vc = [[[WILDScriptEditorHandlerListPopoverViewController alloc] initWithNibName: @"WILDScriptEditorHandlerListPopover" bundle: [NSBundle bundleForClass: [self class]]] autorelease];
		vc.delegate = self;
		mAddHandlersPopover.contentViewController = vc;
		mAddHandlersPopover.behavior = NSPopoverBehaviorTransient;
		mAddHandlersPopover.delegate = self;
		[mAddHandlersPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMaxYEdge];
	}
}


-(void)	popoverDidClose:(NSNotification *)notification
{
	DESTROY(mAddHandlersPopover);
}


-(void)	scriptEditorAddHandlersPopupDidSelectHandler: (NSDictionary*)inDictionary
{
	NSString*	handlerName = [inDictionary objectForKey: @"WILDHandlerName"];
	NSNumber*	destLineObj = [[mPopUpButton itemWithTitle: handlerName.lowercaseString] representedObject];
	if( destLineObj )
	{
		[mSyntaxController goToLine: [destLineObj integerValue]];
	}
	else
	{
		[self addHandlerNamed: handlerName];
	}
	[mAddHandlersPopover close];
}


-(void)	addHandlerNamed: (NSString*)handlerName
{
	//[mTextView.textStorage beginEditing];
	NSString	*	str = [NSString stringWithFormat: @"\n\non %1$@\n\t\nend %1$@", handlerName];
	NSMutableAttributedString	*	attrStr = [[NSMutableAttributedString alloc] initWithString: str attributes: mSyntaxController.defaultTextAttributes];
	[mTextView.textStorage appendAttributedString: attrStr];
	//[mTextView.textStorage endEditing];
	
	[self reformatText];
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%1$@’s Script", [NSString stringWithUTF8String: mContainer->GetDisplayName().c_str()]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	CStackMac*		macStack = dynamic_cast<CStackMac*>(mContainer->GetStack());
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: macStack->GetMacWindow()];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@’s Script", [NSString stringWithUTF8String: mContainer->GetDisplayName().c_str()]]
											action: nil keyEquivalent: @"" atIndex: 0];
	CMacScriptableObjectBase*	macPart = dynamic_cast<CMacScriptableObjectBase*>(mContainer);
	if( macPart )
		[newItem setImage: macPart->GetDisplayIcon()];
	
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


-(void)	reformatText
{
	mContainer->SetScript( std::string(mTextView.string.UTF8String, [mTextView.string lengthOfBytesUsingEncoding: NSUTF8StringEncoding]) );
	[self formatText];
}


-(BOOL) textView: (NSTextView *)textView doCommandBySelector: (SEL)commandSelector
{
	if( commandSelector == @selector(insertTab:) )
	{
		[self reformatText];
		return YES;
	}
//	else if( commandSelector == @selector(insertNewline:) )
//	{
//		[self performSelector: @selector(reformatText) withObject: nil afterDelay: 0.0];
//		return NO;
//	}
	else
		return NO;
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem	*	theItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
	
	if( [itemIdentifier isEqualToString: WILDScriptEditorTopAreaToolbarItemIdentifier] )
	{
		[theItem setLabel: @"Top Area"];
		[theItem setView: mTopNavAreaView];
	}
	
	return theItem;
}

/* Returns the ordered list of items to be shown in the toolbar by default.   If during initialization, no overriding values are found in the user defaults, or if the user chooses to revert to the default items this set will be used. */
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return @[ WILDScriptEditorTopAreaToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier ];
}

/* Returns the list of all allowed items by identifier.  By default, the toolbar does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed.  The set of allowed items is used to construct the customization palette.  The order of items does not necessarily guarantee the order of appearance in the palette.  At minimum, you should return the default item list.*/
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return @[ WILDScriptEditorTopAreaToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier ];
}

@end
