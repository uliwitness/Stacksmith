//
//  UKPropagandaCardViewController.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaCardViewController.h"
#import "UKPropagandaStack.h"
#import "UKPropagandaBackground.h"
#import "UKPropagandaCard.h"
#import "UKPropagandaPart.h"
#import "UKPropagandaPartContents.h"
#import "UKPropagandaDrawAddColorBezel.h"
#import <QuartzCore/QuartzCore.h>
#import "UKPropagandaButtonCell.h"
#import "UKPropagandaNotifications.h"
#import "UKPropagandaSelectionView.h"
#import "UKPropagandaPictureView.h"
#import "UKPropagandaWindowBodyView.h"
#import "UKPropagandaTextView.h"
#import "UKPropagandaClickablePopUpButtonLabel.h"


@implementation UKPropagandaCardViewController

-(id)	init
{
	if(( self = [super init] ))
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
												name: UKPropagandaPeekingStateChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(backgroundEditModeChanged:)
												name: UKPropagandaBackgroundEditModeChangedNotification
												object: nil];
	}
	
	return self;
}


-(void)	dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaBackgroundEditModeChangedNotification
											object: nil];
	
	[mPartViews release];
	mPartViews = nil;
	
	[mAddColorOverlay release];
	mAddColorOverlay = nil;
	
	[mSearchContext release];
	mSearchContext = nil;
	
	[mCurrentSearchString release];
	mCurrentSearchString = nil;
	
	[super dealloc];
}


-(void)	setView: (NSView *)view
{
	[super setView: view];
	
	[view setWantsLayer: YES];
	NSResponder*	nxResp = [[view window] nextResponder];
	[[view window] setNextResponder: self];
	[self setNextResponder: nxResp];
}


-(void)	loadPopupButton: (UKPropagandaPart*)currPart withContents: (UKPropagandaPartContents*)contents
{
	NSRect			partRect = [currPart rectangle];
	NSTextField*	label = nil;
	UKPropagandaSelectionView*	selView = [[[UKPropagandaSelectionView alloc] initWithFrame: NSInsetRect(partRect, -2, -2)] autorelease];
	[selView setHidden: ![currPart visible]];
	[selView setWantsLayer: YES];
	[selView setRepresentedPart: currPart];
	[[self view] addSubview: selView];
	partRect.origin = NSMakePoint( 2, 2 );
	
	[mPartViews setObject: selView forKey: [NSString stringWithFormat: @"%p", currPart]];
	
	NSRect		popupBox = partRect;
	if( [currPart titleWidth] > 0 )
	{
		NSRect	titleBox = popupBox;
		titleBox.size.width = [currPart titleWidth];
		popupBox.origin.x += titleBox.size.width;
		popupBox.size.width -= titleBox.size.width;
		
		label = [[UKPropagandaClickablePopUpButtonLabel alloc] initWithFrame: titleBox];
		[label setWantsLayer: YES];
		[label setEditable: NO];
		[label setSelectable: NO];
		[label setDrawsBackground: NO];
		[label setBezeled: NO];
		[label setBordered: NO];
		[[label cell] setWraps: NO];
		if( [currPart showName] )
			[label setStringValue: [currPart name]];
		[label setFont: [currPart textFont]];
		[label sizeToFit];
		titleBox.origin.y -= truncf((titleBox.size.height -[label bounds].size.height) /2);
		[label setFrame: titleBox];
		[selView addSubview: label];
		
		[selView setHelperView: label];
	}
	
	NSPopUpButton	*	bt = [[NSPopUpButton alloc] initWithFrame: popupBox];
	[bt setWantsLayer: YES];
	[bt setFont: [currPart textFont]];
	
	NSArray*	popupItems = [contents listItems];
	for( NSString* itemName in popupItems )
	{
		if( [itemName hasPrefix: @"-"] )
			[[bt menu] addItem: [NSMenuItem separatorItem]];
		else
			[bt addItemWithTitle: itemName];
	}
	[bt selectItemAtIndex: [[currPart selectedListItemIndexes] firstIndex]];
	[bt setState: [currPart highlighted] ? NSOnState : NSOffState];
	
	if( [selView helperView] )
		[(UKPropagandaClickablePopUpButtonLabel*)[selView helperView] setPopUpButton: bt];
	
	[selView addSubview: bt];
	
	[selView setControl: bt];
	
//	if( label )
//		[bt accessibilitySetValue: label forAttribute: NSAccessibilityTitleUIElementAttribute];
	
	[bt release];
}


-(void)	loadPushButton: (UKPropagandaPart*)currPart withContents: (UKPropagandaPartContents*)contents
{
	NSRect						partRect = [currPart rectangle];
	UKPropagandaSelectionView*	selView = [[[UKPropagandaSelectionView alloc] initWithFrame: NSInsetRect(partRect, -2, -2)] autorelease];
	[selView setHidden: ![currPart visible]];
	[selView setWantsLayer: YES];
	[selView setRepresentedPart: currPart];
	[[self view] addSubview: selView];
	partRect.origin = NSMakePoint( 2, 2 );

	[mPartViews setObject: selView forKey: [NSString stringWithFormat: @"%p", currPart]];
	
	BOOL			canHaveIcon = YES;
	NSButton	*	bt = [[NSButton alloc] initWithFrame: partRect];
	[bt setWantsLayer: YES];
	
	if( [[currPart style] isEqualToString: @"transparent"]
		|| [[currPart style] isEqualToString: @"oval"] )
	{
		[bt setCell: [[[UKPropagandaButtonCell alloc] initTextCell: @""] autorelease]];
		[bt setBordered: NO];

		if( [[currPart style] isEqualToString: @"oval"] )
			[bt setBezelStyle: NSCircularBezelStyle];
		[bt setAlignment: [currPart textAlignment]];	
		[bt setButtonType: NSToggleButton];
	}
	else if( [[currPart style] isEqualToString: @"opaque"] )
	{
		[bt setCell: [[[UKPropagandaButtonCell alloc] initTextCell: @""] autorelease]];
		[bt setBordered: NO];
		[[bt cell] setBackgroundColor: [NSColor whiteColor]];
		[bt setAlignment: [currPart textAlignment]];	
		[bt setButtonType: NSToggleButton];
	}
	else if( [[currPart style] isEqualToString: @"rectangle"]
			|| [[currPart style] isEqualToString: @"shadow"]
			|| [[currPart style] isEqualToString: @"roundrect"]
			|| [[currPart style] isEqualToString: @"standard"]
			|| [[currPart style] isEqualToString: @"default"] )
	{
		UKPropagandaButtonCell*	ourCell = [[[UKPropagandaButtonCell alloc] initTextCell: @""] autorelease];
		[bt setCell: ourCell];
		[[bt cell] setBackgroundColor: [NSColor whiteColor]];
		[bt setBordered: YES];
		
		if( [[currPart style] isEqualToString: @"shadow"]
			|| [[currPart style] isEqualToString: @"roundrect"] )
		{
			CGColorRef theColor = CGColorCreateGenericRGB( 0.4, 0.4, 0.4, 1.0 );
			[[bt layer] setShadowColor: theColor];
			[[bt layer] setShadowOpacity: 0.8];
			[[bt layer] setShadowOffset: CGSizeMake( 1, -1 )];
			[[bt layer] setShadowRadius: 0.0];
			CFRelease( theColor );
			
			// Compensate for shadow
			partRect.size.width -= 1;
			partRect.size.height -= 1;
			partRect.origin.y += 1;
			[bt setFrame: partRect];
		}
		
		if( [[currPart style] isEqualToString: @"roundrect"]
			|| [[currPart style] isEqualToString: @"standard"]
			|| [[currPart style] isEqualToString: @"default"] )
			[bt setBezelStyle: NSRoundedBezelStyle];
		
		if( [[currPart style] isEqualToString: @"default"] )
		{
			[bt setKeyEquivalent: @"\r"];
			[ourCell setDrawAsDefault: YES];
		}
		[bt setAlignment: [currPart textAlignment]];	
		[bt setButtonType: NSToggleButton];
	}
	else if( [[currPart style] isEqualToString: @"checkbox"] )
	{
		[bt setButtonType: NSSwitchButton];
		canHaveIcon = NO;
	}
	else if( [[currPart style] isEqualToString: @"radiobutton"] )
	{
		[bt setButtonType: NSRadioButton];
		canHaveIcon = NO;
	}

	[bt setFont: [currPart textFont]];
	[bt setTitle: [currPart name]];
	[bt setTarget: currPart];
	[bt setAction: @selector(updateOnClick:)];
	[bt setState: [currPart highlighted] ? NSOnState : NSOffState];
	
	if( canHaveIcon )
	{
		[bt setImage: [currPart iconImage]];
		
		if( [currPart iconID] == -1 || [[currPart name] length] == 0
			|| ![currPart showName] )
			[bt setImagePosition: NSImageOnly];
		else
			[bt setImagePosition: NSImageAbove];
		if( [currPart iconID] != -1 && [currPart iconID] != 0 )
			[bt setFont: [NSFont fontWithName: @"Geneva" size: 9.0]];
		[[bt cell] setImageScaling: NSImageScaleNone];
	}
	
	[selView addSubview: bt];
	[selView setControl: bt];
	
	[bt release];
}


-(void)	loadButton: (UKPropagandaPart*)currPart withContents: (UKPropagandaPartContents*)contents
{
	if( [[currPart style] isEqualToString: @"popup"] )
	{
		[self loadPopupButton: currPart withContents: contents];
	}
	else
	{
		[self loadPushButton: currPart withContents: contents];
	}
}


-(IBAction)	hideFindPanel: (id)sender
{
	NSView*		container = [[self view] superview];
	NSWindow*	wd = [container window];
	NSRect		wdBox = [wd frame];
	CGFloat		searchBarHeight = [container bounds].size.height -NSMaxY( [[self view] frame] );

	if( NSMaxY([container frame]) != [container frame].size.height )	// Don't have find panel in view!
		return;
	
	wdBox.size.height -= searchBarHeight;
	wdBox.origin.y += searchBarHeight;

	[container setAutoresizingMask: NSViewMaxYMargin];
	[wd setFrame: wdBox display: YES animate: YES];
	[container setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable | NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];

	[mSearchField setEnabled: NO];
}


-(IBAction)	showFindPanel: (id)sender
{
	NSView*		container = [[self view] superview];
	NSWindow*	wd = [container window];
	NSRect		wdFrame = [wd frame];
	NSRect		wdBounds = [wd contentRectForFrameRect: wdFrame];
	CGFloat		searchBarHeight = [container bounds].size.height -NSMaxY( [[self view] frame] );
	
	if( NSMaxY([container frame]) == wdBounds.size.height )	// Already have find panel in view!
		return;
	
	[mSearchField setEnabled: YES];
	[[mSearchField window] makeFirstResponder: mSearchField];
	
	wdFrame.size.height += searchBarHeight;
	wdFrame.origin.y -= searchBarHeight;

	[container setAutoresizingMask: NSViewMaxYMargin];
	[wd setFrame: wdFrame display: YES animate: YES];
	[container setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable | NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
}


-(void)	highlightSearchResult
{
	if( mCurrentCard != mSearchContext.currentCard && mSearchContext.currentCard != nil )
		[self loadCard: mSearchContext.currentCard];
	
	if( mSearchContext.currentPart )
	{
		UKPropagandaSelectionView*	partView = [mPartViews objectForKey: [NSString stringWithFormat: @"%p", mSearchContext.currentPart]];
		[partView highlightSearchResultInRange: mSearchContext.currentResultRange];
	}
}


-(IBAction)	findStringOfObject: (id)sender
{
	BOOL		foundSomething = NO;
	NSString*	newSearchStr = [sender stringValue];
	if( mCurrentSearchString && [newSearchStr isEqualToString: mCurrentSearchString] )
		foundSomething = [self searchAgainForPattern: mCurrentSearchString flags: UKPropagandaSearchCaseInsensitive];
	else
	{
		[mCurrentSearchString release];
		mCurrentSearchString = nil;
		
		if( [newSearchStr isEqualToString: @""] )
			return;
		
		mCurrentSearchString = [newSearchStr retain];
		foundSomething = [self searchForPattern: mCurrentSearchString flags: UKPropagandaSearchCaseInsensitive];
	}
	
	if( !foundSomething )
	{
		NSBeep();
		[mCurrentSearchString release];	// Make sure we start a new search next time someone tries to hit return.
		mCurrentSearchString = nil;
	}
	else
		[self highlightSearchResult];
}


-(IBAction)	findNext: (id)sender
{
	[self findNextForward: YES];
}


-(IBAction)	findPrevious: (id)sender
{
	[self findNextForward: NO];
}


-(void)	findNextForward: (BOOL)forwardNotBackward
{
	BOOL	foundSomething = [self searchAgainForPattern: mCurrentSearchString
				flags: UKPropagandaSearchCaseInsensitive | (forwardNotBackward ? 0 : UKPropagandaSearchBackwards)];
	if( !foundSomething )
	{
		NSBeep();
		[mCurrentSearchString release];	// Make sure we start a new search next time someone tries to hit return.
		mCurrentSearchString = nil;
	}
	else
		[self highlightSearchResult];
}


-(BOOL)	validateMenuItem: (NSMenuItem *)menuItem
{
	return( [self respondsToSelector: [menuItem action]] );
}


-(IBAction)	performFindPanelAction: (id)sender
{
	NSFindPanelAction	theAction = [sender tag];
	switch( theAction )
	{
		case NSFindPanelActionShowFindPanel:
			
			break;

		case NSFindPanelActionNext:
			[self findNextForward: YES];
			break;

		case NSFindPanelActionPrevious:
			[self findNextForward: NO];
			break;

		case NSFindPanelActionSetFindString:
			
			break;
	}
}


-(BOOL)	searchForPattern: (NSString *)inPattern flags: (UKPropagandaSearchFlags)inFlags
{
	[mSearchContext release];
	mSearchContext = nil;
	
	mSearchContext = [[UKPropagandaSearchContext alloc] init];
	mSearchContext.startCard = mCurrentCard;
	
	return [[mCurrentCard stack] searchForPattern: inPattern withContext: mSearchContext flags: inFlags];
}


-(BOOL)	searchAgainForPattern: (NSString *)inPattern flags: (UKPropagandaSearchFlags)inFlags
{
	if( !mSearchContext )
		return NO;
	return [[mCurrentCard stack] searchForPattern: inPattern withContext: mSearchContext flags: inFlags];
}


-(void)	loadEditField: (UKPropagandaPart*)currPart withContents: (UKPropagandaPartContents*)contents
{
	NSRect						partRect = [currPart rectangle];
	UKPropagandaSelectionView*	selView = [[[UKPropagandaSelectionView alloc] initWithFrame: NSInsetRect(partRect, -2, -2)] autorelease];
	[selView setHidden: ![currPart visible]];
	[selView setWantsLayer: YES];
	[selView setRepresentedPart: currPart];
	[[self view] addSubview: selView];
	partRect.origin = NSMakePoint( 2, 2 );

	[mPartViews setObject: selView forKey: [NSString stringWithFormat: @"%p", currPart]];
	
	UKPropagandaTextView	*	tv = [[UKPropagandaTextView alloc] initWithFrame: partRect];
	[tv setFont: [currPart textFont]];
	[tv setWantsLayer: YES];
	[tv setUsesFindPanel: NO];
	[tv setAlignment: [currPart textAlignment]];
	if( [currPart wideMargins] )
		[tv setTextContainerInset: NSMakeSize( 5, 2 )];
	[tv setRepresentedPart: currPart];
	
	NSAttributedString*	attrStr = [contents styledTextForPart: currPart];
	if( attrStr )
		[[tv textStorage] setAttributedString: attrStr];
	else
	{
		NSString*	theText = [contents text];
		if( theText )
			[tv setString: [contents text]];
	}
	
	[tv setEditable: ![currPart textLocked]];
	[tv setSelectable: ![currPart textLocked]];
	
	NSScrollView*	sv = [[NSScrollView alloc] initWithFrame: partRect];
	[sv setDocumentCursor: [[mCurrentCard stack] cursorWithID: 128]];
	[sv setWantsLayer: YES];
	NSRect			txBox = partRect;
	txBox.origin = NSZeroPoint;
	if( [[currPart style] isEqualToString: @"transparent"] )
	{
		[sv setBorderType: NSNoBorder];
		[sv setDrawsBackground: NO];
		[tv setDrawsBackground: NO];
		[sv setHasVerticalScroller: NO];
	}
	else if( [[currPart style] isEqualToString: @"opaque"] )
	{
		[sv setBorderType: NSNoBorder];
		[sv setHasVerticalScroller: NO];
		[sv setBackgroundColor: [NSColor whiteColor]];
	}
	else if( [[currPart style] isEqualToString: @"scrolling"] )
	{
		txBox.size.width -= 15;
		[sv setBorderType: NSLineBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: YES];
	}
	else
	{
		if( [[currPart style] isEqualToString: @"shadow"] )
		{
			CGColorRef theColor = CGColorCreateGenericRGB( 0.4, 0.4, 0.4, 1.0 );
			[[sv layer] setShadowColor: theColor];
			[[sv layer] setShadowOpacity: 0.8];
			[[sv layer] setShadowOffset: CGSizeMake( 2, -2 )];
			[[sv layer] setShadowRadius: 0.0];
			CFRelease( theColor );
			
			txBox.size.width -= 2;
			txBox.size.height -= 2;
			txBox.origin.y += 2;
			
			partRect.size.width -= 2;
			partRect.size.height -= 2;
			partRect.origin.y += 2;
			[sv setFrame: partRect];
		}
		[sv setBorderType: NSLineBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: NO];
	}
	[sv setHasHorizontalScroller: NO];
	[tv setFrame: txBox];
	[sv setDocumentView: tv];
	[selView addSubview: sv];
	[selView setHelperView: tv];
	
	[tv release];
}


-(void)	loadListField: (UKPropagandaPart*)currPart withContents: (UKPropagandaPartContents*)contents
{
	NSRect						partRect = [currPart rectangle];
	UKPropagandaSelectionView*	selView = [[[UKPropagandaSelectionView alloc] initWithFrame: NSInsetRect(partRect, -2, -2)] autorelease];
	[selView setHidden: ![currPart visible]];
	[selView setWantsLayer: YES];
	[selView setRepresentedPart: currPart];
	[[self view] addSubview: selView];
	partRect.origin = NSMakePoint( 2, 2 );

	[mPartViews setObject: selView forKey: [NSString stringWithFormat: @"%p", currPart]];
	
	// Build the table view:
	NSTableView	*	tv = [[NSTableView alloc] initWithFrame: partRect];
	[tv setWantsLayer: YES];
	[tv setFont: [currPart textFont]];
	[tv setAlignment: [currPart textAlignment]];
	[tv setColumnAutoresizingStyle: NSTableViewUniformColumnAutoresizingStyle];
	if( [currPart showLines] )
	{
		[tv setGridStyleMask: NSTableViewSolidHorizontalGridLineMask];
		[tv setGridColor: [NSColor lightGrayColor]];
	}
	else
		[tv setGridStyleMask: NSTableViewGridNone];
	[tv setAllowsColumnSelection: NO];
	[tv setAllowsMultipleSelection: [currPart canSelectMultipleLines]];
	[tv setHeaderView: nil];
	
	NSTableColumn*		tc = [[NSTableColumn alloc] initWithIdentifier: @"mainColumn"];
	NSTextFieldCell*	dc = [[NSTextFieldCell alloc] initTextCell: @"Are you my mommy?"];
	[tc setDataCell: dc];
	[dc release];
	[tv addTableColumn: tc];
	[tc release];
	NSArrayController*	arrayc = [[NSArrayController alloc] init];
	[arrayc setContent: [contents listItems]];
	[tv bind: @"content" toObject: arrayc withKeyPath: @"arrangedObjects" options: nil];
	[tc bind: @"value" toObject: arrayc withKeyPath: @"arrangedObjects.description" options: nil];
	[arrayc release];
	
	// Build surrounding scroll view:
	NSScrollView*	sv = [[NSScrollView alloc] initWithFrame: partRect];
	[sv setDocumentCursor: [[mCurrentCard stack] cursorWithID: 128]];
	[sv setWantsLayer: YES];
	NSRect			txBox = [currPart rectangle];
	txBox.origin = NSZeroPoint;
	if( [[currPart style] isEqualToString: @"transparent"] )
	{
		[sv setBorderType: NSNoBorder];
		[sv setDrawsBackground: NO];
		[tv setBackgroundColor: [NSColor clearColor]];
		[sv setHasVerticalScroller: NO];
	}
	else if( [[currPart style] isEqualToString: @"opaque"] )
	{
		[sv setBorderType: NSNoBorder];
		[tv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: NO];
	}
	else if( [[currPart style] isEqualToString: @"scrolling"] )
	{
		txBox.size.width -= 15;
		[sv setBorderType: NSLineBorder];
		[tv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: YES];
	}
	else
	{
		if( [[currPart style] isEqualToString: @"shadow"] )
		{
			CGColorRef theColor = CGColorCreateGenericRGB( 0.4, 0.4, 0.4, 1.0 );
			[[sv layer] setShadowColor: theColor];
			[[sv layer] setShadowOpacity: 0.8];
			[[sv layer] setShadowOffset: CGSizeMake( 2, -2 )];
			[[sv layer] setShadowRadius: 0.0];
			CFRelease( theColor );
		}
		[sv setBorderType: NSLineBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: NO];
	}
	[sv setHasHorizontalScroller: NO];
	[tv setFrame: txBox];
	[tc setWidth: txBox.size.width];
	[tc setMaxWidth: 1000000.0];
	[tc setMinWidth: 10.0];
	[sv setDocumentView: tv];
	[selView addSubview: sv];
	[selView setHelperView: tv];

	NSIndexSet*	idxes = [currPart selectedListItemIndexes];
	if( idxes )
		[tv selectRowIndexes: idxes byExtendingSelection: NO];
	
	[tv release];
}


-(void)	loadField: (UKPropagandaPart*)currPart withContents: (UKPropagandaPartContents*)contents
{
	if( [currPart autoSelect] && [currPart textLocked] )
	{
		[self loadListField: currPart withContents: contents];
	}
	else if( [[currPart style] isEqualToString: @"transparent"] || [[currPart style] isEqualToString: @"opaque"]
		 || [[currPart style] isEqualToString: @"rectangle"] || [[currPart style] isEqualToString: @"shadow"]
		|| [[currPart style] isEqualToString: @"scrolling"] )
	{
		[self loadEditField: currPart withContents: contents];
	}
	else
	{
		[self loadEditField: currPart withContents: contents];
	}
}


-(void)	loadPart: (UKPropagandaPart*)currPart withContents: (UKPropagandaPartContents*)contents
{
	if( [[currPart partType] isEqualToString: @"button"] )
		[self loadButton: currPart withContents: contents];
	else
		[self loadField: currPart withContents: contents];
}


-(void)	drawAddColorPartsInLayer: (UKPropagandaBackground*)theLayer
{
	for( UKPropagandaPart* currPart in [theLayer addColorParts] )
	{
		if( ![currPart visible] )
			continue;
		
		if( [[currPart partType] isEqualToString: @"picture"] )
		{
			[[currPart iconImage] drawInRect: [currPart rectangle] fromRect: NSZeroRect
						operation: NSCompositeCopy fraction: 1.0];
		}
		else if( [[currPart partType] isEqualToString: @"rectangle"] )
		{
			UKPropagandaDrawAddColorBezel( [NSBezierPath bezierPathWithRect: [currPart rectangle]],
												[currPart fillColor],
												[currPart bevel],
												nil, nil );
		}
		else
		{
			NSBezierPath*	partPath = nil;
			
			if( [[currPart style] isEqualToString: @"oval"] )
				partPath = [NSBezierPath bezierPathWithOvalInRect: [currPart rectangle]];
			else if( [[currPart style] isEqualToString: @"roundrect"]
						|| [[currPart style] isEqualToString: @"standard"]
						|| [[currPart style] isEqualToString: @"default"] )
				partPath = [NSBezierPath bezierPathWithRoundedRect: [currPart rectangle] xRadius: 8 yRadius: 8];
			else
				partPath = [NSBezierPath bezierPathWithRect: [currPart rectangle]];
			
			UKPropagandaDrawAddColorBezel( partPath,
												[currPart fillColor],
												[currPart bevel],
												nil, nil );
		}
	}
}


-(void)	loadCard: (UKPropagandaCard*)theCard
{
	
	UKPropagandaCard*		prevCard = mCurrentCard;
	NSMutableDictionary*	uiDict = nil;
	if( theCard != prevCard )
	{
		uiDict = [NSMutableDictionary dictionary];
		if( prevCard )
			[uiDict setObject: prevCard forKey: UKPropagandaSourceCardKey];
		if( theCard )
			[uiDict setObject: theCard forKey: UKPropagandaDestinationCardKey];
		[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaCurrentCardWillChangeNotification
							object: self userInfo: uiDict];
	}
	
	// Get rid of previous card's views:
	NSArray*	subviews = [[[[self view] subviews] copy] autorelease];
	for( NSView* currSubview in subviews )
		[currSubview removeFromSuperview];
	
	[mPartViews release];
	mPartViews = nil;
	
	mCurrentCard = theCard;
	
	mPartViews = [[NSMutableDictionary alloc] init];
	
	// Tell the view about the new current card:
	[(UKPropagandaWindowBodyView*)[self view] setCard: mCurrentCard];
	
	// Load the background for this card:
	UKPropagandaStack*		theStack = [theCard stack];
	UKPropagandaBackground*	theBg = [theCard owningBackground];
	
	NSImage*		bgPicture = [theBg picture];
	if( bgPicture )
	{
		UKPropagandaPictureView*	imgView = [[UKPropagandaPictureView alloc] initWithFrame: [[self view] bounds]];
		[imgView setImage: bgPicture];
		[imgView setHidden: ![theBg showPicture]];
		[imgView setWantsLayer: YES];
		[[self view] addSubview: imgView];
		[imgView release];
	}
	
	for( UKPropagandaPart* currPart in [theBg parts] )
	{
		UKPropagandaPartContents*	contents = nil;
		if( [currPart sharedText] )
			contents = [theBg contentsForPart: currPart];
		else
			contents = mBackgroundEditMode ? nil : [theCard contentsForPart: currPart];
		
		[self loadPart: currPart withContents: contents];
	}
	
	// Load the actual card parts:
	NSImage*		cdPicture = [theCard picture];
	if( cdPicture )
	{
		UKPropagandaPictureView*	imgView = [[UKPropagandaPictureView alloc] initWithFrame: [[self view] bounds]];
		[imgView setImage: cdPicture];
		[imgView setHidden: ![theCard showPicture]];
		[imgView setWantsLayer: YES];
		[[self view] addSubview: imgView];
		[imgView release];
	}

	if( !mBackgroundEditMode )
	{
		for( UKPropagandaPart* currPart in [theCard parts] )
		{
			UKPropagandaPartContents*	contents = [theCard contentsForPart: currPart];
			[self loadPart: currPart withContents: contents];
		}
	}
	
	// Load AddColor stuff:
	NSSize	cardSize = [theStack cardSize];
	CGColorSpaceRef	colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGContextRef	theContext = CGBitmapContextCreate( NULL, cardSize.width, cardSize.height, 8,
														cardSize.width * 4, colorSpace,
							kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host );
	CGColorSpaceRelease( colorSpace );
	colorSpace = NULL;
	
	NSGraphicsContext*	cocoaContext = [NSGraphicsContext graphicsContextWithGraphicsPort: theContext flipped: NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext: cocoaContext];
	
	[self drawAddColorPartsInLayer: theBg];
	if( !mBackgroundEditMode )
		[self drawAddColorPartsInLayer: theCard];
	[NSGraphicsContext restoreGraphicsState];
	
	CGImageRef	theImage = CGBitmapContextCreateImage( theContext );
	CGContextRelease( theContext );
	
	if( mAddColorOverlay )
	{
		[mAddColorOverlay removeFromSuperlayer];
		[mAddColorOverlay release];
		mAddColorOverlay = nil;
	}
	mAddColorOverlay = [[CALayer layer] retain];
	[mAddColorOverlay setContents: (id)theImage];
	[mAddColorOverlay setAnchorPoint: CGPointMake( 0, 0 )];	// Lower left in a 0...1 normalized coordinate system.
	[mAddColorOverlay setFrame: CGRectMake( 0, 0, cardSize.width, cardSize.height )];
	CIFilter*	theFilter = [CIFilter filterWithName: @"CIDarkenBlendMode"];
	[theFilter setDefaults];
	[mAddColorOverlay setCompositingFilter: theFilter];
	[[[self view] layer] addSublayer: mAddColorOverlay];
	CFRelease( theImage );
	
	if( uiDict )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: UKPropagandaCurrentCardDidChangeNotification
							object: self userInfo: uiDict];
	}
}


-(IBAction)	goFirstCard: (id)sender
{
	UKPropagandaStack*	theStack = [mCurrentCard stack];
	UKPropagandaCard*	nextCard = [[theStack cards] objectAtIndex: 0];
	[self loadCard: nextCard];
}


-(IBAction)	goPrevCard: (id)sender
{
	UKPropagandaStack*	theStack = [mCurrentCard stack];
	NSInteger			currCdIdx = [[theStack cards] indexOfObject: mCurrentCard];
	if( --currCdIdx < 0 )
		currCdIdx = [[theStack cards] count] -1;
	UKPropagandaCard*	nextCard = [[theStack cards] objectAtIndex: currCdIdx];
	[self loadCard: nextCard];
}


-(IBAction)	goNextCard: (id)sender
{
	UKPropagandaStack*	theStack = [mCurrentCard stack];
	NSInteger			currCdIdx = [[theStack cards] indexOfObject: mCurrentCard];
	if( ++currCdIdx >= [[theStack cards] count] )
		currCdIdx = 0;
	UKPropagandaCard*	nextCard = [[theStack cards] objectAtIndex: currCdIdx];
	[self loadCard: nextCard];
}


-(IBAction)	goLastCard: (id)sender
{
	UKPropagandaStack*	theStack = [mCurrentCard stack];
	UKPropagandaCard*	nextCard = [[theStack cards] objectAtIndex: [[theStack cards] count] -1];
	[self loadCard: nextCard];
}


-(void)	moveRight: (id)sender
{
	[self goNextCard: sender];
}


-(void)	moveLeft: (id)sender
{
	[self goPrevCard: sender];
}


-(void)	peekingStateChanged: (NSNotification*)notification
{
	mPeeking = [[[notification userInfo] objectForKey: UKPropagandaPeekingStateKey] boolValue];
}


-(void)	backgroundEditModeChanged: (NSNotification*)notification
{
	mBackgroundEditMode = [[[notification userInfo] objectForKey: UKPropagandaBackgroundEditModeKey] boolValue];
	[self loadCard: mCurrentCard];
}

@end
