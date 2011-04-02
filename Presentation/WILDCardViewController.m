//
//  WILDCardViewController.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDCardViewController.h"
#import "WILDStack.h"
#import "WILDBackground.h"
#import "WILDCard.h"
#import "WILDPart.h"
#import "WILDPartContents.h"
#import "WILDDrawAddColorBezel.h"
#import <QuartzCore/QuartzCore.h>
#import "WILDButtonCell.h"
#import "WILDNotifications.h"
#import "WILDPartView.h"
#import "WILDPictureView.h"
#import "WILDCardView.h"
#import "WILDTextView.h"
#import "WILDClickablePopUpButtonLabel.h"
#import "WILDButtonInfoWindowController.h"
#import "WILDFieldInfoWindowController.h"
#import "WILDPresentationConstants.h"
#import "WILDCardInfoWindowController.h"
#import "WILDBackgroundInfoWindowController.h"
#import "WILDRecentCardsList.h"
#import "WILDRecentCardPickerWindowController.h"


@implementation WILDCardViewController

-(id)	init
{
	if(( self = [super init] ))
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
												name: WILDPeekingStateChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(backgroundEditModeChanged:)
												name: WILDBackgroundEditModeChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
												name: WILDCurrentToolDidChangeNotification
												object: nil];
	}
	
	return self;
}


-(void)	dealloc
{
	if( mCurrentCard )
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerDidAddPartNotification object: mCurrentCard];
		[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerWillRemovePartNotification object: mCurrentCard];
		[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerDidAddPartNotification object: [mCurrentCard owningBackground]];
		[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerWillRemovePartNotification object: [mCurrentCard owningBackground]];
	}
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDBackgroundEditModeChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDCurrentToolDidChangeNotification
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


-(WILDCard*)	currentCard
{
	return mCurrentCard;
}


-(void)	setView: (NSView *)view
{
	[super setView: view];
	[(WILDCardView*)view setOwner: self];
	
	[view setWantsLayer: YES];
	NSResponder*	nxResp = [[view window] nextResponder];
	if( nxResp != self )
	{
		[[view window] setNextResponder: self];
		[self setNextResponder: nxResp];
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
		WILDPartView*	partView = [mPartViews objectForKey: [NSString stringWithFormat: @"%p", mSearchContext.currentPart]];
		[partView highlightSearchResultInRange: mSearchContext.currentResultRange];
	}
}


-(IBAction)	findStringOfObject: (id)sender
{
	BOOL		foundSomething = NO;
	NSString*	newSearchStr = [sender stringValue];
	if( mCurrentSearchString && [newSearchStr isEqualToString: mCurrentSearchString] )
		foundSomething = [self searchAgainForPattern: mCurrentSearchString flags: WILDSearchCaseInsensitive];
	else
	{
		[mCurrentSearchString release];
		mCurrentSearchString = nil;
		
		if( [newSearchStr isEqualToString: @""] )
			return;
		
		mCurrentSearchString = [newSearchStr retain];
		foundSomething = [self searchForPattern: mCurrentSearchString flags: WILDSearchCaseInsensitive];
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
				flags: WILDSearchCaseInsensitive | (forwardNotBackward ? 0 : WILDSearchBackwards)];
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
	if( [menuItem action] == @selector(chooseToolWithTag:) )
	{
		[menuItem setState: ([menuItem tag] == [[WILDTools sharedTools] currentTool]) ? NSOnState : NSOffState];
		return YES;
	}
	else if( [menuItem action] == @selector(showButtonInfoPanel:) )
	{
		return( [[WILDTools sharedTools] numberOfSelectedClients] > 0
			&& [[WILDTools sharedTools] currentTool] == WILDButtonTool );
	}
	else if( [menuItem action] == @selector(showFieldInfoPanel:) )
	{
		return( [[WILDTools sharedTools] numberOfSelectedClients] > 0
			&& [[WILDTools sharedTools] currentTool] == WILDFieldTool );
	}
	else if( [menuItem action] == @selector(bringObjectCloser:)
				|| [menuItem action] == @selector(sendObjectFarther:) )
	{
		return( [[WILDTools sharedTools] numberOfSelectedClients] > 0
			&& ([[WILDTools sharedTools] currentTool] == WILDButtonTool
				|| [[WILDTools sharedTools] currentTool] == WILDFieldTool) );
	}
	else if( [menuItem action] == @selector(goRecentCard:)
				|| [menuItem action] == @selector(goBack:) )
	{
		return( [[WILDRecentCardsList sharedRecentCardsList] count] > 0 );
	}
	else if( [menuItem action] == @selector(selectAll:) )
	{
		bool canSelect = ( [[WILDTools sharedTools] currentTool] != WILDBrowseTool );
		if( canSelect )
		{
			NSUInteger	numSelectableParts = 0;
			NSArray	*	views = [[self view] subviews];
			for( WILDPartView	*	currPartView in views )
			{
				if( [currPartView myToolIsCurrent] )
					numSelectableParts += 1;
			}
			
			return [[WILDTools sharedTools] numberOfSelectedClients] != numSelectableParts;
		}
		else
			return NO;
	}
	else if( [menuItem action] == @selector(deselectAll:) )
	{
		return ( [[WILDTools sharedTools] numberOfSelectedClients] > 0 );
	}
	else
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


-(BOOL)	searchForPattern: (NSString *)inPattern flags: (WILDSearchFlags)inFlags
{
	[mSearchContext release];
	mSearchContext = nil;
	
	mSearchContext = [[WILDSearchContext alloc] init];
	mSearchContext.startCard = mCurrentCard;
	
	return [[mCurrentCard stack] searchForPattern: inPattern withContext: mSearchContext flags: inFlags];
}


-(BOOL)	searchAgainForPattern: (NSString *)inPattern flags: (WILDSearchFlags)inFlags
{
	if( !mSearchContext )
		return NO;
	return [[mCurrentCard stack] searchForPattern: inPattern withContext: mSearchContext flags: inFlags];
}


-(void)	drawAddColorPartsInLayer: (WILDLayer*)theLayer
{
	for( WILDPart* currPart in [theLayer addColorParts] )
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
			WILDDrawAddColorBezel( [NSBezierPath bezierPathWithRect: [currPart rectangle]],
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
			
			WILDDrawAddColorBezel( partPath,
												[currPart fillColor],
												[currPart bevel],
												nil, nil );
		}
	}
}


-(void)	reloadCard
{
	NSArray*	subviews = [mPartViews allObjects];
	for( NSView* currSubview in subviews )
		[currSubview partDidChange: nil];
}


-(void)	loadCard: (WILDCard*)theCard
{
	WILDCard			*	prevCard = mCurrentCard;
	NSMutableDictionary	*	uiDict = nil;
	if( theCard != prevCard )
	{
		if( mCurrentCard )
			[[WILDRecentCardsList sharedRecentCardsList] addCard: mCurrentCard inCardView: self.view];
		
		uiDict = [NSMutableDictionary dictionary];
		if( prevCard )
			[uiDict setObject: prevCard forKey: WILDSourceCardKey];
		if( theCard )
			[uiDict setObject: theCard forKey: WILDDestinationCardKey];
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDCurrentCardWillChangeNotification
							object: self userInfo: uiDict];
		
		if( prevCard )
		{
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerDidAddPartNotification object: prevCard];
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerWillRemovePartNotification object: prevCard];
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerDidAddPartNotification object: [prevCard owningBackground]];
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerWillRemovePartNotification object: [prevCard owningBackground]];
		}
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
	[(WILDCardView*)[self view] setCard: mCurrentCard];
	[[[self view] window] makeFirstResponder: [self view]];
	
	if( theCard )
	{
		// Load the background for this card:
		WILDStack*		theStack = [theCard stack];
		WILDBackground*	theBg = [theCard owningBackground];
		
		NSImage*		bgPicture = [theBg picture];
		if( bgPicture )
		{
			WILDPictureView*	imgView = [[WILDPictureView alloc] initWithFrame: [[self view] bounds]];
			[imgView setImage: bgPicture];
			[imgView setHidden: ![theBg showPicture]];
			[imgView setWantsLayer: YES];
			[[self view] addSubview: imgView];
			[imgView release];
		}
		
		for( WILDPart* currPart in [theBg parts] )
		{
			WILDPartView*	selView = [[[WILDPartView alloc] initWithFrame: NSInsetRect([currPart rectangle], -2, -2)] autorelease];
			[selView setWantsLayer: YES];
			[[self view] addSubview: selView];
			[mPartViews setObject: selView forKey: [NSString stringWithFormat: @"%p", currPart]];
			[selView loadPart: currPart forBackgroundEditing: mBackgroundEditMode];
		}
		
		// Load the actual card parts:
		NSImage*		cdPicture = [theCard picture];
		if( cdPicture )
		{
			WILDPictureView*	imgView = [[WILDPictureView alloc] initWithFrame: [[self view] bounds]];
			[imgView setImage: cdPicture];
			[imgView setHidden: ![theCard showPicture]];
			[imgView setWantsLayer: YES];
			[[self view] addSubview: imgView];
			[imgView release];
		}

		if( !mBackgroundEditMode )
		{
			for( WILDPart* currPart in [theCard parts] )
			{
				WILDPartView*	selView = [[[WILDPartView alloc] initWithFrame: NSInsetRect([currPart rectangle], -2, -2)] autorelease];
				[selView setWantsLayer: YES];
				[[self view] addSubview: selView];
				[mPartViews setObject: selView forKey: [NSString stringWithFormat: @"%p", currPart]];
				[selView loadPart: currPart forBackgroundEditing: NO];
			}
		}
		
		// Load AddColor stuff:
		NSSize          cardSize = [theStack cardSize];
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
		
		if( prevCard != theCard )
		{
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(layerDidAddPart:) name: WILDLayerDidAddPartNotification object: theCard];
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(layerWillRemovePart:) name: WILDLayerWillRemovePartNotification object: theCard];
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(layerDidAddPart:) name: WILDLayerDidAddPartNotification object: [theCard owningBackground]];
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(layerWillRemovePart:) name: WILDLayerWillRemovePartNotification object: [theCard owningBackground]];
		}
	}
	if( uiDict )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDCurrentCardDidChangeNotification
							object: self userInfo: uiDict];
	}
}


-(IBAction)	goHome: (id)sender
{
	[[NSApp delegate] applicationOpenUntitledFile: NSApp];
}


-(IBAction)	goRecentCard: (id)sender
{
	WILDRecentCardPickerWindowController	*	recentWindowController = [[[WILDRecentCardPickerWindowController alloc] initWithCardViewController: self] autorelease];
	[[[[[self view] window] windowController] document] addWindowController: recentWindowController];
	[recentWindowController showWindow: self];
}


-(IBAction)	goBack: (id)sender
{
	if( [[WILDRecentCardsList sharedRecentCardsList] count] > 0 )
	{
		WILDCard	*	theCard = [[WILDRecentCardsList sharedRecentCardsList] cardAtIndex: [[WILDRecentCardsList sharedRecentCardsList] count] -1];
		[self loadCard: theCard];
	}
}


-(IBAction)	goFirstCard: (id)sender
{
	WILDStack*	theStack = [mCurrentCard stack];
	WILDCard*	nextCard = [[theStack cards] objectAtIndex: 0];
	[self loadCard: nextCard];
}


-(IBAction)	goPrevCard: (id)sender
{
	WILDStack*	theStack = [mCurrentCard stack];
	NSInteger			currCdIdx = [[theStack cards] indexOfObject: mCurrentCard];
	if( --currCdIdx < 0 )
		currCdIdx = [[theStack cards] count] -1;
	WILDCard*	nextCard = [[theStack cards] objectAtIndex: currCdIdx];
	[self loadCard: nextCard];
}


-(IBAction)	goNextCard: (id)sender
{
	WILDStack*	theStack = [mCurrentCard stack];
	NSInteger			currCdIdx = [[theStack cards] indexOfObject: mCurrentCard];
	if( ++currCdIdx >= [[theStack cards] count] )
		currCdIdx = 0;
	WILDCard*	nextCard = [[theStack cards] objectAtIndex: currCdIdx];
	[self loadCard: nextCard];
}


-(IBAction)	goLastCard: (id)sender
{
	WILDStack*	theStack = [mCurrentCard stack];
	WILDCard*	nextCard = [[theStack cards] objectAtIndex: [[theStack cards] count] -1];
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


-(void)	selectAll: (id)sender
{
	NSArray	*	views = [[self view] subviews];
	for( WILDPartView	*	currPartView in views )
	{
		if( [currPartView respondsToSelector: @selector(setSelected:)]
			&& [currPartView myToolIsCurrent] )
			[currPartView setSelected: YES];
	}
}


-(void)	deselectAll: (id)sender
{
	[[WILDTools sharedTools] deselectAllClients];
}


-(void)	peekingStateChanged: (NSNotification*)notification
{
	mPeeking = [[[notification userInfo] objectForKey: WILDPeekingStateKey] boolValue];
}


-(void)	backgroundEditModeChanged: (NSNotification*)notification
{
	mBackgroundEditMode = [[[notification userInfo] objectForKey: WILDBackgroundEditModeKey] boolValue];
	[self loadCard: mCurrentCard];
}


-(void)	currentToolDidChange: (NSNotification*)notification
{
	[[self view] setNeedsDisplay: YES];
}


-(void)	layerDidAddPart: (NSNotification*)notif
{
	[self loadCard: mCurrentCard];
}


-(void)	layerWillRemovePart: (NSNotification*)notif
{
	[self performSelector: @selector(loadCard:) withObject: mCurrentCard afterDelay: 0.0];
}


-(IBAction)	showButtonInfoPanel: (id)sender
{
	NSArray*			allSels = [[[WILDTools sharedTools] clients] allObjects];
	for( WILDPartView* currView in allSels )
	{
		WILDPart*	thePart = [currView part];
		WILDButtonInfoWindowController*	buttonInfo = [[[WILDButtonInfoWindowController alloc] initWithPart: thePart ofCardView: (WILDCardView*) [self view]] autorelease];
		[[[[[self view] window] windowController] document] addWindowController: buttonInfo];
		[buttonInfo showWindow: self];
	}
}

-(IBAction)	showFieldInfoPanel: (id)sender
{
	NSArray*			allSels = [[[WILDTools sharedTools] clients] allObjects];
	for( WILDPartView* currView in allSels )
	{
		WILDPart*	thePart = [currView part];
		WILDFieldInfoWindowController*	fieldInfo = [[[WILDFieldInfoWindowController alloc] initWithPart: thePart ofCardView: (WILDCardView*) [self view]] autorelease];
		[[[[[self view] window] windowController] document] addWindowController: fieldInfo];
		[fieldInfo showWindow: self];
	}
}

-(IBAction)	showCardInfoPanel: (id)sender
{
	WILDCardInfoWindowController*	cardInfo = [[[WILDCardInfoWindowController alloc] initWithCard: mCurrentCard ofCardView: (WILDCardView*) [self view]] autorelease];
	[[[[[self view] window] windowController] document] addWindowController: cardInfo];
	[cardInfo showWindow: self];
}

-(IBAction)	showBackgroundInfoPanel: (id)sender
{
	WILDBackgroundInfoWindowController*	backgroundInfo = [[[WILDBackgroundInfoWindowController alloc] initWithBackground: [mCurrentCard owningBackground] ofCardView: (WILDCardView*) [self view]] autorelease];
	[[[[[self view] window] windowController] document] addWindowController: backgroundInfo];
	[backgroundInfo showWindow: self];
}

//-(IBAction)	showStackInfoPanel: (id)sender
//{
//	
//}
//
//-(IBAction)	bringObjectCloser: (id)sender
//{
//	
//}
//
//-(IBAction)	sendObjectFarther: (id)sender
//{
//	
//}

-(IBAction)	createNewButton: (id)sender
{
	WILDLayer	*	layer = mBackgroundEditMode ? [mCurrentCard owningBackground] : mCurrentCard;
	[layer createNewButton: sender];
	[[WILDTools sharedTools] setCurrentTool: WILDButtonTool];
}


-(IBAction)	createNewField: (id)sender
{
	WILDLayer	*	layer = mBackgroundEditMode ? [mCurrentCard owningBackground] : mCurrentCard;
	[layer createNewField: sender];	
	[[WILDTools sharedTools] setCurrentTool: WILDFieldTool];
}


-(IBAction)	createNewCard: (id)sender
{
	WILDStack		*	theStack = [mCurrentCard stack];
	WILDBackground	*	owningBackground = [mCurrentCard owningBackground];
	WILDCard		*	theNewCard = [[[WILDCard alloc] initForStack: theStack] autorelease];
	[theNewCard setOwningBackground: owningBackground];
	[theStack addCard: theNewCard];
	[owningBackground addCard: theNewCard];
	
	[self loadCard: theNewCard];
}


-(IBAction)	cutCard: (id)sender
{
	[self copyCard: sender];
	[self deleteCard: sender];
}


-(IBAction)	copyCard: (id)sender
{
	NSString	*	cdXmlString = [mCurrentCard xmlStringForWritingToURL: nil error: nil];
	NSString	*	bgXmlString = [[mCurrentCard owningBackground] xmlStringForWritingToURL: nil error: nil];
	NSPasteboard*	pb = [NSPasteboard generalPasteboard];
	[pb clearContents];
	[pb addTypes: [NSArray arrayWithObjects: WILDCardPboardType, WILDBackgroundPboardType, nil] owner: self];
	[pb setString: cdXmlString forType: WILDCardPboardType];
	[pb setString: bgXmlString forType: WILDBackgroundPboardType];
}


-(IBAction)	deleteCard: (id)sender
{
	WILDCard		*	cardToDelete = [[mCurrentCard retain] autorelease];
	WILDBackground	*	owningBackground = [cardToDelete owningBackground];
	WILDStack		*	theStack = [mCurrentCard stack];
	
	if( [[theStack cards] count] > 1 )
	{
		[self goNextCard: self];
		[[WILDRecentCardsList sharedRecentCardsList] removeCard: cardToDelete];
		[cardToDelete setOwningBackground: nil];
		[owningBackground removeCard: cardToDelete];
		[theStack removeCard: cardToDelete];
		
		if( ![owningBackground hasCards] )
			[theStack removeBackground: owningBackground];
	}
	else
		; // TODO: Show err msg. if last card.
}


-(IBAction)	createNewBackground: (id)sender
{
	WILDStack		*	theStack = [mCurrentCard stack];
	WILDBackground	*	theNewBackground = [[[WILDBackground alloc] initForStack: theStack] autorelease];
	[theStack addBackground: theNewBackground];
	WILDCard		*	theNewCard = [[[WILDCard alloc] initForStack: theStack] autorelease];
	[theNewCard setOwningBackground: theNewBackground];
	[theNewBackground addCard: theNewCard];
	[theStack addCard: theNewCard];
	
	[self loadCard: theNewCard];
}


-(IBAction)	chooseToolWithTag: (id)sender
{
	[[WILDTools sharedTools] setCurrentTool: [sender tag]];
}

-(IBAction)	paste: (id)sender
{
	NSPasteboard*	pb = [NSPasteboard generalPasteboard];
	NSArray*		imgs = [pb readObjectsForClasses: [NSArray arrayWithObject: [NSImage class]] options: [NSDictionary dictionary]];
	if( [imgs count] > 0 )
	{
		NSImage*		anImg = [imgs objectAtIndex: 0];
		
	}
}


-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind
{
	NSArray	*	views = [[self view] subviews];
	for( WILDPartView	*	currPartView in views )
	{
		if( [currPartView respondsToSelector: @selector(part)] && [currPartView part] == inObjectToFind )
			return currPartView;
	}
	
	return nil;
}

@end
