//
//  WILDScriptEditorWindowController.mm
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
#include "CCodeSnippets.h"
#import "UKHelperMacros.h"


using namespace Carlson;


static NSString	*	WILDScriptEditorTopAreaToolbarItemIdentifier = @"WILDScriptEditorTopAreaToolbarItemIdentifier";

void*	kWILDScriptEditorWindowControllerKVOContext = &kWILDScriptEditorWindowControllerKVOContext;



@interface WILDScriptEditorUndoInfo : NSObject

@property NSRange range;
@property (copy) NSString * text;

+(instancetype) undoInfo;

@end

@implementation WILDScriptEditorUndoInfo : NSObject

+(instancetype) undoInfo
{
	return [[[[self class] alloc] init] autorelease];
}


-(void) dealloc
{
	[self->_text release];
	self->_text = nil;
	
	[super dealloc];
}

@end



@interface WILDScriptEditorRulerView : NSRulerView
{
	NSTextView			*	targetView;
	NSMutableIndexSet	*	selectedLines;
}

@property (copy,nonatomic) NSIndexSet	*	selectedLines;

@end

@implementation WILDScriptEditorRulerView

-(id)	initWithTargetView: (NSTextView*)inTargetView
{
	self = [super initWithFrame: NSMakeRect(0, 0, 8, 8)];
	if( self )
	{
		targetView = inTargetView;
		selectedLines = [[NSMutableIndexSet alloc] init];
		
		#if REMOTE_DEBUGGER
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(debuggerMayHaveLaunchedNotification:) name: NSWorkspaceDidLaunchApplicationNotification object: [NSWorkspace sharedWorkspace]];
		#endif
	}
	return self;
}


-(void)	dealloc
{
#if REMOTE_DEBUGGER
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name: NSWorkspaceDidLaunchApplicationNotification object: [NSWorkspace sharedWorkspace]];
#endif

	DESTROY_DEALLOC(selectedLines);
	targetView = nil;
	
	[super dealloc];
}


#if REMOTE_DEBUGGER
-(void)	debuggerMayHaveLaunchedNotification: (NSNotification*)notif
{
	NSRunningApplication	*	launchedApp = [notif.userInfo objectForKey: NSWorkspaceApplicationKey];
	if( [launchedApp.bundleIdentifier isEqualToString: @"com.thevoidsoftware.ForgeDebugger"] )
	{
		LEOInitRemoteDebugger( NULL );
	}
}
#endif


-(NSIndexSet*)	selectedLines
{
	return selectedLines;
}


-(void)	setSelectedLines: (NSIndexSet*)inSelectedLines
{
	[self willChangeValueForKey: PROPERTY(selectedLines)];
	DESTROY(selectedLines);
	selectedLines = [inSelectedLines mutableCopy];
	[self didChangeValueForKey: PROPERTY(selectedLines)];
	[self setNeedsDisplay: YES];
}


-(CGFloat)	ruleThickness
{
	return 16;
}


-(CGFloat)	requiredThickness
{
	return 16;
}


-(void)	drawRect: (NSRect)inFrame
{
	[NSColor.whiteColor set];
	[NSBezierPath fillRect: self.bounds];
	NSRect			theBox = [self bounds];
	NSString	*	string = targetView.string;
	
	NSUInteger	currIndex = [selectedLines indexGreaterThanOrEqualToIndex: 0];
	while(( currIndex != NSNotFound ))
	{
		NSUInteger numberOfLines = 1, index = 0;

		for( ; numberOfLines < currIndex; numberOfLines++ )
			index = NSMaxRange([string lineRangeForRange:NSMakeRange(index, 0)]);
		
		NSUInteger	theGlyphIdx = [targetView.layoutManager glyphIndexForCharacterAtIndex: index];
		NSRange		effectiveRange = { 0, 0 };
		NSRect		lineFragmentBox = [targetView.layoutManager lineFragmentRectForGlyphAtIndex:theGlyphIdx effectiveRange: &effectiveRange];
		NSRect		checkpointBox = { NSZeroPoint, { 8, 8 } };
		
		checkpointBox.origin.y = lineFragmentBox.origin.y + truncf((lineFragmentBox.size.height -checkpointBox.size.height) /2) -self.scrollView.documentVisibleRect.origin.y;
		checkpointBox.origin.x = truncf((theBox.size.width -checkpointBox.size.width) /2);
		
		[NSColor.redColor set];
		[[NSBezierPath bezierPathWithOvalInRect: checkpointBox] fill];
		
		currIndex = [selectedLines indexGreaterThanIndex: currIndex];
	}
}


-(void)	mouseDown: (NSEvent*)inEvent
{
	NSPoint		pos = [self convertPoint: inEvent.locationInWindow fromView: nil];
	CGFloat		insertionMarkFraction = 0;
	pos.x = 4;
	NSUInteger	charIndex = [targetView.layoutManager characterIndexForPoint: pos inTextContainer:targetView.textContainer fractionOfDistanceBetweenInsertionPoints: &insertionMarkFraction];
	
	NSString *string = targetView.string;
	NSUInteger numberOfLines = 0, index = 0;

	if( string.length == 0 )
		return;

	for( ; index <= charIndex; numberOfLines++ )
		index = NSMaxRange([string lineRangeForRange:NSMakeRange(index, 0)]);
	
	[self willChangeValueForKey: PROPERTY(selectedLines)];
	if( [selectedLines containsIndex: numberOfLines] )
		[selectedLines removeIndex: numberOfLines];
	else
		[selectedLines addIndex: numberOfLines];
	[self didChangeValueForKey: PROPERTY(selectedLines)];
	[self setNeedsDisplay: YES];
}

@end


@interface WILDScriptEditorWindowController () <NSToolbarDelegate,UKSyntaxColoredTextViewDelegate>
{
	CCodeSnippets			codeBlocksList;
	std::vector<NSRange>	handlerRanges;
}

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
	[mTextBreakpointsRulerView removeObserver: self forKeyPath: PROPERTY(selectedLines) context: kWILDScriptEditorWindowControllerKVOContext];
	
	mContainer = NULL;
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	mTextView.customSnippetPasteboardType = @"WILDCodeSnippetPBoardType";
	mTextView.customSnippetsInsertionGranularity = NSSelectByParagraph;
	
	// Set up a ruler view (for indicating what lines breakpoints are on and setting/removing them):
	mTextBreakpointsRulerView = [[WILDScriptEditorRulerView alloc] initWithTargetView: mTextView];
	[mTextScrollView setHasVerticalRuler: YES];
	[mTextScrollView setVerticalRulerView: mTextBreakpointsRulerView];
	[mTextScrollView setRulersVisible: YES];
	
	[mTextBreakpointsRulerView addObserver: self forKeyPath: PROPERTY(selectedLines) options:0 context: kWILDScriptEditorWindowControllerKVOContext];
	
	NSMutableIndexSet	*	indexes = [NSMutableIndexSet indexSet];
	std::vector<size_t>		breakpointLines;
	mContainer->GetBreakpointLines( breakpointLines );
	for( size_t currIndex : breakpointLines )
		[indexes addIndex: currIndex];
	mTextBreakpointsRulerView.selectedLines = indexes;
	
	// Format our script so it looks pretty:
	[self formatText];
	
	// Create a toolbar containing our handler list popup etc.:
	NSToolbar	*	editToolbar = [[[NSToolbar alloc] initWithIdentifier: @"WILDScriptEditorToolbar"] autorelease];
	[editToolbar setDelegate: self];
	[editToolbar setAllowsUserCustomization: NO];
	[editToolbar setVisible: NO];
	[editToolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
	[editToolbar setSizeMode: NSToolbarSizeModeSmall];
	[self.window setToolbar: editToolbar];
	[self.window toggleToolbarShown: self];

	// Make sure we don't do smart quotes in the script editor:
	mTextView.automaticQuoteSubstitutionEnabled = NO;
	mTextView.automaticDashSubstitutionEnabled = NO;
	mTextView.automaticTextReplacementEnabled = NO;
	
	NSNib * sectionHeaderNib = [[[NSNib alloc] initWithNibNamed: @"WILDScriptEditorCodeBlocksSectionHeader" bundle: nil] autorelease];
	[self.codeBlocksListView registerNib: sectionHeaderNib forSupplementaryViewOfKind: NSCollectionElementKindSectionHeader withIdentifier: @"WILDScriptEditorCollectionViewSectionHeader"];
	NSNib * theNib = [[[NSNib alloc] initWithNibNamed: @"WILDScriptEditorWindowController" bundle: nil] autorelease];
	[self.codeBlocksListView registerNib: theNib forItemWithIdentifier: @"WILDScriptEditorCollectionViewItem"];
	[self rebuildCodeBlocksList];
}


-(void)	rebuildCodeBlocksList
{
	codeBlocksList.Clear();
	std::vector<CAddHandlerListEntry> addHandlerList = mContainer->GetAddHandlerList();
	codeBlocksList.AddSectionsAndBlocksFromHandlerList( addHandlerList );
	
	[self.codeBlocksListView reloadData];
}


- (void)replaceUndoableCharactersInRange:(NSRange)range withString:(NSString *)string
{
	WILDScriptEditorUndoInfo * undoInfo = [WILDScriptEditorUndoInfo undoInfo];
	undoInfo.text = [mTextView.string substringWithRange: range];
	undoInfo.range = NSMakeRange( range.location, string.length);
	[mTextView replaceCharactersInRange: range withString: string];
	[mTextView.undoManager registerUndoWithTarget: self selector: @selector(undoRange:) object:undoInfo];
}


-(void) undoRange: (WILDScriptEditorUndoInfo*)undoInfo
{
	WILDScriptEditorUndoInfo * redoInfo = [WILDScriptEditorUndoInfo undoInfo];
	redoInfo.text = [mTextView.string substringWithRange: undoInfo.range];
	redoInfo.range = NSMakeRange( undoInfo.range.location, undoInfo.text.length);
	[mTextView replaceCharactersInRange: undoInfo.range withString: undoInfo.text];
	[mTextView.undoManager registerUndoWithTarget: self selector: @selector(undoRange:) object:redoInfo];
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
	if( parseTree )
	{
		LEODisplayInfoTable*	displayInfo = LEODisplayInfoTableCreateForParseTree( parseTree );
		//LEODebugPrintDisplayInfoTable(displayInfo);
		LEODisplayInfoTableApplyToText( displayInfo, mContainer->GetScript().c_str(), mContainer->GetScript().length(), &theText, &theTextLen, &cursorPos, &cursorEndPos );
		NSString	*	formattedText = [[[NSString alloc] initWithBytesNoCopy: theText length: theTextLen encoding: NSUTF8StringEncoding freeWhenDone: YES] autorelease];
		[mTextView setString: formattedText];
		NSRange		newSelRange = NSMakeRange(cursorPos,cursorEndPos -cursorPos);
		if( (newSelRange.location + newSelRange.length) > formattedText.length )
		{
			newSelRange.location = formattedText.length;
			newSelRange.length = 0;
		}
		[mTextView setSelectedRange: newSelRange];
	
		[mPopUpButton removeAllItems];
		const char*	theName = "";
		
		bool		isCommand = false;
		bool		isHandlerEnd = false;
		NSRange 	currRange;
		for( x = 0; theName != NULL; x++ )
		{
			LEODisplayInfoTableGetHandlerInfoAtIndex( displayInfo, x, &theName, &theLine, &isHandlerEnd, &isCommand );
			if( !theName ) break;
			if( theName[0] == ':' )	// Skip any fake internal handlers we add.
				continue;
			if( !isHandlerEnd )
			{
				NSMenuItem*	theItem = [mPopUpButton.menu addItemWithTitle: [NSString stringWithUTF8String: theName] action: Nil keyEquivalent: @""];
				[theItem setImage: [NSImage imageNamed: isCommand ? @"CommandHandlerIcon" : @"FunctionHandlerIcon"]];
				[theItem setRepresentedObject: @(theLine)];
				
				currRange.location = theLine;
				currRange.length = 0;
			}
			
			if( isHandlerEnd )
			{
				currRange.length = theLine - currRange.location;
				handlerRanges.push_back(currRange);
			}
		}
		LEOCleanUpDisplayInfoTable( displayInfo );
		LEOCleanUpParseTree( parseTree );
	
		if( x == 0 )	// We added no items?
		{
			[mPopUpButton addItemWithTitle: @"None"];
			[mPopUpButton setEnabled: NO];
		}
		else
		{
			[mPopUpButton setEnabled: YES];
		}
	}

	[self rebuildCodeBlocksList];
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
	[theWindow setTitle: [self windowTitleForDocumentDisplayName: @""]];
	
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
	if( mContainer )
	{
		mContainer->SetScript( std::string(mTextView.string.UTF8String, [mTextView.string lengthOfBytesUsingEncoding: NSUTF8StringEncoding]) );
		CMacScriptableObjectBase* msob = dynamic_cast<CMacScriptableObjectBase*>(mContainer);
		if( msob )
			msob->SetMacScriptEditor(nil);
	}
}


-(IBAction) saveDocument: (id)sender
{
	if( mContainer )
	{
		mContainer->SetScript( std::string(mTextView.string.UTF8String, [mTextView.string lengthOfBytesUsingEncoding: NSUTF8StringEncoding]) );
		mContainer->GetDocument()->Save();
	}
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


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%1$@’s Script", [NSString stringWithUTF8String: mContainer->GetDisplayName().c_str()]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	CStackMac*		macStack = dynamic_cast<CStackMac*>(mContainer->GetStack());
	if( macStack )
	{
		NSMenuItem*		fileItem = [menu itemAtIndex: 0];
		[fileItem setTarget: macStack->GetMacWindow()];
		[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	}
	
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
		[self performSelector: @selector(reformatText) withObject: nil afterDelay: 0.0];
		return YES;
	}
	else if( commandSelector == @selector(insertNewline:) )
	{
		[self performSelector: @selector(reformatText) withObject: nil afterDelay: 0.0];
		return NO;
	}
	else if( commandSelector == @selector(deleteBackward:) || commandSelector == @selector(deleteForward:) )
	{
		[self performSelector: @selector(reformatText) withObject: nil afterDelay: 0.0];
		return NO;
	}
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


-(void) textViewControllerTextDidChange: (UKSyntaxColoredTextViewController*)sender;
{
//	[self reformatText];
}


-(void)	textViewControllerHandleEnterKey: (UKSyntaxColoredTextViewController*)sender
{
	[self close];
}


-(void) textViewController: (UKSyntaxColoredTextViewController*)sender willInsertSnippetInRange: (NSRange*)insertionRange
{
//	NSRange oldInsertionRange = *insertionRange;
	
	// find line matching insertionRange.location
	NSUInteger insertionLine = [sender lineAtOffset: insertionRange->location];
	NSUInteger newInsertionLine = insertionLine;
	
	// Check if line is within any ranges in handlerRanges
	for( const NSRange& currRange : handlerRanges )
	{
		if( (insertionLine >= currRange.location) && (insertionLine <= NSMaxRange(currRange)) )
		{
			// If it is, adjust the line to be before/after the given handler (whatever is closer).
			NSUInteger startHandlerDistance = insertionLine - currRange.location;
			NSUInteger endHandlerDistance = currRange.length - startHandlerDistance;
			if( startHandlerDistance < endHandlerDistance )
			{
				newInsertionLine = currRange.location - 1;
			}
			else if( startHandlerDistance >= endHandlerDistance )
			{
				newInsertionLine = NSMaxRange(currRange) + 1;
			}
			NSLog(@"%lu -> %lu | %lu/%lu | %@", insertionLine, newInsertionLine, startHandlerDistance, endHandlerDistance, NSStringFromRange(currRange));
			break;
		}
	}
	
	// Translate the line back into an offset and store it back in insertionRange.location.
	if( newInsertionLine != insertionLine )
	{
		insertionRange->location = [sender rangeForLine: (newInsertionLine != insertionLine) ? newInsertionLine : insertionLine].location;
	}
	
	NSLog(@"\t%@", NSStringFromRange(*insertionRange));

//	NSLog(@"%@ -> %@ [%lu -> %lu]", NSStringFromRange(oldInsertionRange), NSStringFromRange(*insertionRange), insertionLine, newInsertionLine);
}


-(NSString*) textViewController: (UKSyntaxColoredTextViewController*)sender stringForSnippetOnPasteboard: (NSPasteboard*)pboard forRange: (NSRange)dropRange
{
	NSString * dropSnippetText = [pboard stringForType: ((ULISyntaxColoredTextView*)sender.view).customSnippetPasteboardType];
	NSString * myText = [(ULISyntaxColoredTextView *)sender.view textStorage].string;
	NSUInteger endOffset = NSMaxRange(dropRange);
	if (dropRange.location > 0 && [myText rangeOfString:@"\n\n" options:NSBackwardsSearch | NSAnchoredSearch range: NSMakeRange(0, dropRange.location)].location == NSNotFound) {
		dropSnippetText = [@"\n\n" stringByAppendingString: dropSnippetText];
	}
	if (endOffset < myText.length && [myText rangeOfString:@"\n\n" options:NSAnchoredSearch range: NSMakeRange(endOffset, myText.length - endOffset)].location == NSNotFound) {
		dropSnippetText = [dropSnippetText stringByAppendingString: @"\n\n"];
	}
	return dropSnippetText;
}


-(NSInteger)	numberOfSectionsInCollectionView: (NSCollectionView *)collectionView
{
	return codeBlocksList.GetNumSections();
}


-(NSView *)	collectionView:(NSCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
	NSView * theView = nil;
	if( [kind isEqualToString: NSCollectionElementKindSectionHeader] )
	{
		theView = [collectionView makeSupplementaryViewOfKind: kind withIdentifier: @"WILDScriptEditorCollectionViewSectionHeader" forIndexPath: indexPath];
		NSTextField* titleView = theView.subviews.firstObject;
		titleView.stringValue = [NSString stringWithUTF8String: codeBlocksList.GetSectionAt(indexPath.section).GetName().c_str()];
	}
	return theView;
}


-(NSInteger) collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return codeBlocksList.GetSectionAt(section).GetNumBlockEntries();
}


-(NSCollectionViewItem *) collectionView: (NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath: (NSIndexPath *)indexPath
{
	CCodeSnippetsBlockEntry& currEntry = codeBlocksList.GetBlockEntryAt( indexPath.section, indexPath.item );
	
	NSCollectionViewItem * theItem = [collectionView makeItemWithIdentifier: @"WILDScriptEditorCollectionViewItem" forIndexPath: indexPath];
	
	theItem.textField.stringValue = [NSString stringWithUTF8String: currEntry.GetName().c_str()];
	theItem.imageView.image = [NSImage imageNamed: theItem.textField.stringValue.lowercaseString] ?: [NSImage imageNamed: NSImageNameAdvanced];
	theItem.representedObject = indexPath;
	
	return theItem;
}


- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths toPasteboard:(NSPasteboard *)pasteboard
{
	NSMutableArray * thePasteboardData = [NSMutableArray array];
	
	[pasteboard declareTypes: @[ @"WILDCodeSnippetPBoardType" ] owner: nil];
	
	for( NSIndexPath* currItemPath in indexPaths )
	{
		CCodeSnippetsBlockEntry& currEntry = codeBlocksList.GetBlockEntryAt( currItemPath.section, currItemPath.item );
		NSString * codeSnippet = [NSString stringWithUTF8String: currEntry.mHandlerEntry.mHandlerTemplate.c_str()];
		[thePasteboardData addObject: codeSnippet];
	}
	
	[pasteboard setString: thePasteboardData.firstObject forType: @"WILDCodeSnippetPBoardType"];
	
	return YES;
}


-(void)	observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if( context == kWILDScriptEditorWindowControllerKVOContext )
	{
		if( object == mTextBreakpointsRulerView && [keyPath isEqualToString: PROPERTY(selectedLines)] )
		{
			std::vector<size_t>	breakpointLines;
			NSIndexSet*	selectedLines = mTextBreakpointsRulerView.selectedLines;
			NSUInteger	currIndex = [selectedLines indexGreaterThanOrEqualToIndex: 0];
			while( currIndex != NSNotFound )
			{
				breakpointLines.push_back( currIndex );
				currIndex = [selectedLines indexGreaterThanIndex: currIndex];
			}
			mContainer->SetBreakpointLines( breakpointLines );
			
			#if REMOTE_DEBUGGER
			if( !LEOInitRemoteDebugger( NULL ) && !breakpointLines.empty() )	// Try to connect to debugger. If not able, launch it.
			{
				NSString	*	debuggerPath = [[NSBundle mainBundle] pathForResource: @"ForgeDebugger" ofType: @"app"];
				if( debuggerPath )
					[[NSWorkspace sharedWorkspace] openFile: debuggerPath];
				else
					NSLog(@"Error: Can't find debugger.");
			}
			#endif
		}
	}
	else
		[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

@end
