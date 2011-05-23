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
#import "WILDStackInfoWindowController.h"

#import "ULIPaintSelectionRectangleTool.h"
#import "ULIPaintSelectionLassoTool.h"
#import "ULIPaintBrushTool.h"
#import "ULIPaintFreehandTool.h"
#import "ULIPaintEraserTool.h"
#import "ULIPaintLineTool.h"
#import "ULIPaintRectangleTool.h"
#import "ULIPaintRoundedRectangleTool.h"
#import "ULIPaintOvalTool.h"
#import "ULIPaintTextTool.h"
#import "ULIPaintShapeTool.h"
#import "WILDToolsPalette.h"


@interface WILDCardViewController () <ULIPaintViewDelegate>

@end

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
	
	DESTROY_DEALLOC(mPartViews);
	DESTROY_DEALLOC(mAddColorOverlay);
	DESTROY_DEALLOC(mSearchContext);
	DESTROY_DEALLOC(mCurrentSearchString);
	DESTROY_DEALLOC(mBackgroundPictureView);
	DESTROY_DEALLOC(mCardPictureView);
	
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
				|| [menuItem action] == @selector(sendObjectFarther:)
				|| [menuItem action] == @selector(delete:)
				|| [menuItem action] == @selector(copy:)
				|| [menuItem action] == @selector(cut:) )
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
				if( [currPartView respondsToSelector: @selector(myToolIsCurrent)]
					&& [currPartView myToolIsCurrent] )
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
	else if( [menuItem action] == @selector(deleteCard:)
		|| [menuItem action] == @selector(cutCard:) )
	{
		return ( [[[mCurrentCard stack] cards] count] > 1 );
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
	
	if( prevCard != theCard )
	{
		if( prevCard != nil )
			WILDScriptContainerResultFromSendingMessage( prevCard, @"closeCard" );
		if( theCard == nil )
			WILDScriptContainerResultFromSendingMessage( prevCard, @"closeStack" );
	}
	
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
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDStackDidChangeNotification object: [prevCard stack]];
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
		
		DESTROY(mBackgroundPictureView);
		mBackgroundPictureView = [[WILDPictureView alloc] initWithFrame: [[self view] bounds]];
		NSImage*		bgPicture = [theBg picture];
		if( bgPicture )
			[mBackgroundPictureView setImage: bgPicture];
		[mBackgroundPictureView setDelegate: self];	// After setImage: so we don't mark ourselves as modified.
		[mBackgroundPictureView setHidden: ![theBg showPicture]];
		[mBackgroundPictureView setWantsLayer: YES];
		[[self view] addSubview: mBackgroundPictureView];
		
		for( WILDPart* currPart in [theBg parts] )
		{
			WILDPartView*	selView = [[[WILDPartView alloc] initWithFrame: NSInsetRect([currPart rectangle], -2, -2)] autorelease];
			[selView setWantsLayer: YES];
			[[self view] addSubview: selView];
			[mPartViews setObject: selView forKey: [NSString stringWithFormat: @"%p", currPart]];
			[selView loadPart: currPart forBackgroundEditing: mBackgroundEditMode];
		}
		
		// Load the actual card parts:
		if( !mBackgroundEditMode )
		{
			DESTROY(mCardPictureView);
			mCardPictureView = [[WILDPictureView alloc] initWithFrame: [[self view] bounds]];
			NSImage*		cdPicture = [theCard picture];
			if( cdPicture )
				[mCardPictureView setImage: cdPicture];
			[mCardPictureView setDelegate: self];	// After setImage: so we don't mark ourselves as modified.
			[mCardPictureView setHidden: ![theCard showPicture]];
			[mCardPictureView setWantsLayer: YES];
			[[self view] addSubview: mCardPictureView];

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
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(stackDidChange:) name: WILDStackDidChangeNotification object: [theCard stack]];
		}
	}
	if( uiDict )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDCurrentCardDidChangeNotification
							object: self userInfo: uiDict];
	}

	if( prevCard != theCard && theCard != nil )
	{
		if( prevCard == nil )
			WILDScriptContainerResultFromSendingMessage( theCard, @"openStack" );
		WILDScriptContainerResultFromSendingMessage( theCard, @"openCard" );
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
	if( [[WILDTools sharedTools] numberOfSelectedClients] > 0 )
	{
		NSArray*			allSels = [[[WILDTools sharedTools] clients] allObjects];
		for( WILDPartView* currView in allSels )
		{
			WILDPart*	thePart = [currView part];
			[thePart setFlippedRectangle: NSOffsetRect( [thePart flippedRectangle], 1, 0)];
			[currView setFrame: NSOffsetRect([currView frame], 1, 0)];
		}
	}
	else
		[self goNextCard: sender];
}


-(void)	moveLeft: (id)sender
{
	if( [[WILDTools sharedTools] numberOfSelectedClients] > 0 )
	{
		NSArray*			allSels = [[[WILDTools sharedTools] clients] allObjects];
		for( WILDPartView* currView in allSels )
		{
			WILDPart*	thePart = [currView part];
			[thePart setFlippedRectangle: NSOffsetRect( [thePart flippedRectangle], -1, 0)];
			[currView setFrame: NSOffsetRect([currView frame], -1, 0)];
		}
	}
	else
		[self goPrevCard: sender];
}


-(void)	moveUp: (id)sender
{
	if( [[WILDTools sharedTools] numberOfSelectedClients] > 0 )
	{
		NSArray*			allSels = [[[WILDTools sharedTools] clients] allObjects];
		for( WILDPartView* currView in allSels )
		{
			WILDPart*	thePart = [currView part];
			[thePart setFlippedRectangle: NSOffsetRect( [thePart flippedRectangle], 0, -1)];
			[currView setFrame: NSOffsetRect([currView frame], 0, 1)];
		}
	}
	else
		[self goFirstCard: sender];
}


-(void)	moveDown: (id)sender
{
	if( [[WILDTools sharedTools] numberOfSelectedClients] > 0 )
	{
		NSArray*			allSels = [[[WILDTools sharedTools] clients] allObjects];
		for( WILDPartView* currView in allSels )
		{
			WILDPart*	thePart = [currView part];
			[thePart setFlippedRectangle: NSOffsetRect( [thePart flippedRectangle], 0, 1)];
			[currView setFrame: NSOffsetRect([currView frame], 0, -1)];
		}
	}
	else
		[self goLastCard: sender];
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


-(void)	stackDidChange: (NSNotification*)notif
{
	if( [[[notif userInfo] objectForKey: WILDAffectedPropertyKey] isEqualToString: @"cardSize"] )
	{
		NSWindow	*wd = [[self view] window];
		NSRect		theFrame = [wd contentRectForFrameRect: [wd frame]];
		theFrame.size = [[mCurrentCard stack] cardSize];
		[wd setFrame: [wd frameRectForContentRect: theFrame] display: NO];
		
		NSRect		viewFrame = [[self view] frame];
		viewFrame.size = [[mCurrentCard stack] cardSize];
		[[self view] setFrame: viewFrame];
	}
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

-(IBAction)	showStackInfoPanel: (id)sender
{
	WILDStackInfoWindowController*	stackInfo = [[[WILDStackInfoWindowController alloc] initWithStack: [mCurrentCard stack] ofCardView: (WILDCardView*) [self view]] autorelease];
	[[[[[self view] window] windowController] document] addWindowController: stackInfo];
	[stackInfo showWindow: self];
}

-(void)	selectParts: (NSArray*)theParts
{
	NSArray	*	views = [[self view] subviews];
	for( WILDPartView	*	currPartView in views )
	{
		BOOL	supportsPartMethod = [currPartView respondsToSelector: @selector(part)];
		if( supportsPartMethod )
		{
			WILDPart	*	thePart = [currPartView part];
			if( [theParts containsObject: thePart] )
				[currPartView setSelected: YES];
		}
	}
}

-(IBAction)	bringObjectCloser: (id)sender
{
	NSSet			*	theSet = [[WILDTools sharedTools] clients];
	NSMutableArray	*	allParts = [NSMutableArray array];
	
	for( WILDPartView	*	currPartView in theSet )
	{
		WILDPart	*	thePart = [currPartView part];
		[[thePart partOwner] bringPartCloser: thePart];
		[allParts addObject: thePart];
	}
	
	[self loadCard: mCurrentCard];
	[self selectParts: allParts];
}

-(IBAction)	sendObjectFarther: (id)sender
{
	NSSet	*	theSet = [[WILDTools sharedTools] clients];
	NSMutableArray	*	allParts = [NSMutableArray array];
	
	for( WILDPartView	*	currPartView in theSet )
	{
		WILDPart	*	thePart = [currPartView part];
		[[thePart partOwner] sendPartFarther: thePart];
		[allParts addObject: thePart];
	}
	
	[self loadCard: mCurrentCard];
	[self selectParts: allParts];
}

-(IBAction)	createNewButton: (id)sender
{
	WILDLayer	*	layer = mBackgroundEditMode ? [mCurrentCard owningBackground] : mCurrentCard;
	[layer createNewButton: sender];
	[[WILDTools sharedTools] setCurrentTool: WILDButtonTool];
	
	[self reloadCard];
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
	NSString	*	cdXmlString = [mCurrentCard xmlStringForWritingToURL: nil forSaveOperation: NSSaveAsOperation originalContentsURL: nil error: nil];
	NSString	*	bgXmlString = [[mCurrentCard owningBackground] xmlStringForWritingToURL: nil forSaveOperation: NSSaveAsOperation originalContentsURL: nil error: nil];
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
	WILDTool		desiredTool = [sender tag];
	
	[[WILDTools sharedTools] setCurrentTool: desiredTool];
	
	if( [WILDTools toolIsPaintTool: desiredTool] )
	{
		NSInteger		idx = desiredTool -WILDFirstPaintTool;
		static NSArray*	sTools = nil;
		if( !sTools )
			sTools = [[NSArray alloc] initWithObjects: [ULIPaintSelectionRectangleTool class], [ULIPaintSelectionLassoTool class],
												[ULIPaintFreehandTool class] /*pencil*/, [ULIPaintBrushTool class],
												[ULIPaintEraserTool class], [ULIPaintLineTool class],
												[ULIPaintBrushTool class] /*spray*/, [ULIPaintRectangleTool class],
												[ULIPaintRoundedRectangleTool class],
												[ULIPaintBrushTool class] /*bucket*/, [ULIPaintOvalTool class],
												[ULIPaintFreehandTool class], [ULIPaintTextTool class],
												[ULIPaintShapeTool class], [ULIPaintFreehandTool class] /*polygon*/,
												nil];
		
		Class	theTool = [sTools objectAtIndex: idx];
		[mCardPictureView setCurrentTool: [theTool paintToolWithPaintView: mCardPictureView]];
		[mBackgroundPictureView setCurrentTool: [theTool paintToolWithPaintView: mBackgroundPictureView]];
	}
	else
	{
		[mCardPictureView setCurrentTool: nil];
		[mBackgroundPictureView setCurrentTool: nil];
	}
}


-(void)	keyDown: (NSEvent *)event
{
	if( [[event characters] length] == 0 )
		return;
	unichar		firstChar = [[event characters] characterAtIndex: 0];
	
	// if the user pressed delete and the delegate supports deleteKeyPressed
	if( firstChar == NSDeleteFunctionKey
		|| firstChar == NSDeleteCharFunctionKey
		|| firstChar == NSDeleteCharacter )
	{
		[self delete: self];
	}
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


-(IBAction)	delete: (id)sender
{
	NSSet	*	theSet = [[WILDTools sharedTools] clients];
	
	for( WILDPartView	*	currPartView in theSet )
	{
		WILDPart	*	thePart = [currPartView part];
		[[thePart partOwner] deletePart: thePart];
	}
}


-(void)	setTransitionType: (NSString*)inType subtype: (NSString*)inSubtype
{
	[(WILDCardView*)[self view] setTransitionType: inType];
	[(WILDCardView*)[self view] setTransitionSubtype: inSubtype];
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


-(void)	paintViewWillBecomeCurrent: (ULIPaintView*)sender
{
	[mBackgroundPictureView setLineColor: [[WILDToolsPalette sharedToolsPalette] lineColor]];
	[mBackgroundPictureView setFillColor: [[WILDToolsPalette sharedToolsPalette] fillColor]];
	[mCardPictureView setLineColor: [[WILDToolsPalette sharedToolsPalette] lineColor]];
	[mCardPictureView setFillColor: [[WILDToolsPalette sharedToolsPalette] fillColor]];
}

-(void)	paintViewImageDidChange: (ULIPaintView*)sender
{
	if( mBackgroundEditMode && sender == mBackgroundPictureView )
	{
		[[mCurrentCard owningBackground] setPicture: [sender image]];
	}
	else if( !mBackgroundEditMode && sender == mCardPictureView )
	{
		[mCurrentCard setPicture: [sender image]];
	}
}

@end
