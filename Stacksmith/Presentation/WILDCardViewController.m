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
#import "WILDDocument.h"
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
#import "WILDPresentationConstants.h"
#import "WILDCardInfoViewController.h"
#import "WILDBackgroundInfoViewController.h"
#import "WILDRecentCardsList.h"
#import "WILDRecentCardPickerWindowController.h"
#import "WILDStackInfoViewController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDGuidelineView.h"

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
#import "WILDBackgroundModeIndicator.h"

#import "UKHelperMacros.h"


NSString*	WILDStackToolbarItemIdentifier = @"WILDStackToolbarItemIdentifier";
NSString*	WILDCardToolbarItemIdentifier = @"WILDCardToolbarItemIdentifier";
NSString*	WILDBackgroundToolbarItemIdentifier = @"WILDBackgroundToolbarItemIdentifier";
NSString*	WILDEditBackgroundToolbarItemIdentifier = @"WILDEditBackgroundToolbarItemIdentifier";

NSString*	WILDPrevCardToolbarItemIdentifier = @"WILDPrevCardToolbarItemIdentifier";
NSString*	WILDNextCardToolbarItemIdentifier = @"WILDNextCardToolbarItemIdentifier";


@interface WILDCardViewController () <ULIPaintViewDelegate,NSPopoverDelegate,NSToolbarDelegate>
{
	NSPopover	*	mCurrentPopover;
}

@end

@implementation WILDCardViewController

-(id)	init
{
	if(( self = [super init] ))
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
												name: WILDPeekingStateChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
												name: WILDCurrentToolDidChangeNotification
												object: nil];
	}
	
	return self;
}


-(void)	dealloc
{
	[mCurrentPopover close];
	DESTROY_DEALLOC(mCurrentPopover);
	
	if( mCurrentCard )
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerDidAddPartNotification object: mCurrentCard];
		[[NSNotificationCenter defaultCenter] removeObserver: self name: WILDCardWillGoAwayNotification object: mCurrentCard];
		[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerWillRemovePartNotification object: mCurrentCard];
		[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerDidAddPartNotification object: [mCurrentCard owningBackground]];
		[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerWillRemovePartNotification object: [mCurrentCard owningBackground]];
	}
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDCurrentToolDidChangeNotification
											object: nil];
	
	DESTROY_DEALLOC(mPartViews);
	DESTROY_DEALLOC(mGuidelineView);
	DESTROY_DEALLOC(mAddColorOverlay);
	DESTROY_DEALLOC(mSearchContext);
	DESTROY_DEALLOC(mCurrentSearchString);
	[mBackgroundPictureView setDelegate: nil];
	DESTROY_DEALLOC(mBackgroundPictureView);
	[mCardPictureView setDelegate: nil];
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
	else if( [menuItem action] == @selector(showInfoPanel:) )
	{
		return( [[WILDTools sharedTools] numberOfSelectedClients] > 0 );
	}
	else if( [menuItem action] == @selector(bringObjectCloser:)
				|| [menuItem action] == @selector(sendObjectFarther:)
				|| [menuItem action] == @selector(delete:)
				|| [menuItem action] == @selector(copy:)
				|| [menuItem action] == @selector(cut:) )
	{
		return( [[WILDTools sharedTools] numberOfSelectedClients] > 0
			&& ([[WILDTools sharedTools] currentTool] == WILDButtonTool
				|| [[WILDTools sharedTools] currentTool] == WILDFieldTool
				|| [[WILDTools sharedTools] currentTool] == WILDPointerTool
				|| [[WILDTools sharedTools] currentTool] == WILDMoviePlayerTool) );
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
//	else if( [menuItem action] == @selector(deleteCard:)
//		|| [menuItem action] == @selector(cutCard:) )
//	{
//		return ( [[[mCurrentCard stack] cards] count] > 1 );
//	}
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
			[[currPart iconImage] drawInRect: [currPart quartzRectangle] fromRect: NSZeroRect
						operation: NSCompositeCopy fraction: 1.0];
		}
		else if( [[currPart partType] isEqualToString: @"rectangle"] )
		{
			WILDDrawAddColorBezel( [NSBezierPath bezierPathWithRect: [currPart quartzRectangle]],
												[currPart fillColor],
												[currPart bevel],
								  				-45.0,
												nil, nil );
		}
		else
		{
			NSBezierPath*	partPath = nil;
			
			if( [[currPart partStyle] isEqualToString: @"oval"] )
				partPath = [NSBezierPath bezierPathWithOvalInRect: [currPart quartzRectangle]];
			else if( [[currPart partStyle] isEqualToString: @"roundrect"]
						|| [[currPart partStyle] isEqualToString: @"standard"]
						|| [[currPart partStyle] isEqualToString: @"default"] )
				partPath = [NSBezierPath bezierPathWithRoundedRect: [currPart quartzRectangle] xRadius: 8 yRadius: 8];
			else
				partPath = [NSBezierPath bezierPathWithRect: [currPart quartzRectangle]];
			
			WILDDrawAddColorBezel( partPath,
									[currPart fillColor],
									[currPart bevel],
									-45.0,
									nil, nil );
		}
	}
}


-(void)	reloadCard
{
	WILDGuidelineView	*	guidelineView = self.guidelineView;
	[guidelineView removeAllPartViews];
	NSArray*	subviews = [mPartViews allValues];
	for( WILDPartView* currSubview in subviews )
	{
		[currSubview partDidChange: nil];
		[currSubview savePart];
		[currSubview addToGuidelineView: mGuidelineView];
	}
}


-(void)	createPartViewForPart: (WILDPart*)currPart
{
	WILDPartView*	selView = [[[WILDPartView alloc] initWithFrame: NSMakeRect(0,0,100,100)] autorelease];
	[selView setWantsLayer: YES];
	[[self view] addSubview: selView];
	BOOL	isCardButton = [currPart.partLayer isEqualToString: @"card"];
	if( mBackgroundEditMode || isCardButton )
		[selView addToGuidelineView: mGuidelineView];
	[mPartViews setObject: selView forKey: [NSString stringWithFormat: @"%p", currPart]];
	[selView loadPart: currPart forBackgroundEditing: mBackgroundEditMode && !isCardButton];
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
			[[WILDRecentCardsList sharedRecentCardsList] addCard: mCurrentCard inCardView: (WILDCardView*)self.view];
		
		uiDict = [NSMutableDictionary dictionary];
		if( prevCard )
			[uiDict setObject: prevCard forKey: WILDSourceCardKey];
		if( theCard )
			[uiDict setObject: theCard forKey: WILDDestinationCardKey];
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDCurrentCardWillChangeNotification
							object: self userInfo: uiDict];
		
		if( prevCard )
		{
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDCardWillGoAwayNotification object: prevCard];
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerDidAddPartNotification object: prevCard];
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerWillRemovePartNotification object: prevCard];
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerDidAddPartNotification object: [prevCard owningBackground]];
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDLayerWillRemovePartNotification object: [prevCard owningBackground]];
			[[NSNotificationCenter defaultCenter] removeObserver: self name:WILDStackDidChangeNotification object: [prevCard stack]];
		}
	}
	
	// Save & get rid of previous card's views:
	for( WILDPartView * currPartView in [mPartViews allValues] )
		[currPartView savePart];
	NSArray*	subviews = [[[[self view] subviews] copy] autorelease];
	for( NSView* currSubview in subviews )
		[currSubview removeFromSuperview];
	
	DESTROY(mPartViews);
	DESTROY(mGuidelineView);
	
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
		
		[mBackgroundPictureView setDelegate: nil];
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
			[self createPartViewForPart: currPart];
		}
		
		// Load the actual card parts:
		if( !mBackgroundEditMode )
		{
			[mCardPictureView setDelegate: nil];
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
				[self createPartViewForPart: currPart];
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
		
		// Add a view to draw guidelines on top of everything:
		mGuidelineView = [[WILDGuidelineView alloc] initWithFrame: [[self view] bounds]];
		[[self view] addSubview: mGuidelineView];
		for( WILDPartView* currPartView in [mPartViews allValues] )
			[currPartView addToGuidelineView: mGuidelineView];
		
		if( prevCard != theCard )
		{
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(layerDidAddPart:) name: WILDLayerDidAddPartNotification object: theCard];
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(layerWillRemovePart:) name: WILDLayerWillRemovePartNotification object: theCard];
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(layerDidAddPart:) name: WILDLayerDidAddPartNotification object: [theCard owningBackground]];
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(layerWillRemovePart:) name: WILDLayerWillRemovePartNotification object: [theCard owningBackground]];
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(stackDidChange:) name: WILDStackDidChangeNotification object: [theCard stack]];
			[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cardWillGoAway:) name: WILDCardWillGoAwayNotification object: theCard ];
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
	WILDStack*			theStack = [mCurrentCard stack];
	NSUInteger			currCdIdx = [[theStack cards] indexOfObject: mCurrentCard];
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
			[thePart setHammerRectangle: NSOffsetRect( [thePart hammerRectangle], 1, 0)];
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
			[thePart setHammerRectangle: NSOffsetRect( [thePart hammerRectangle], -1, 0)];
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
			[thePart setHammerRectangle: NSOffsetRect( [thePart hammerRectangle], 0, -1)];
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
			[thePart setHammerRectangle: NSOffsetRect( [thePart hammerRectangle], 0, 1)];
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
	[[self guidelineView] setNeedsDisplay: YES];
}


-(IBAction)	toggleBackgroundEditMode: (id)sender
{
	mBackgroundEditMode = !mBackgroundEditMode;
	[(WILDCardView*)self.view setBackgroundEditMode: mBackgroundEditMode];
	[self loadCard: mCurrentCard];
	
	if( mBackgroundEditMode )
		[WILDBackgroundModeIndicator showOnWindow: self.view.window];
	else
		[WILDBackgroundModeIndicator hide];
}


-(void)	currentToolDidChange: (NSNotification*)notification
{
	[[self view] setNeedsDisplay: YES];
}


-(void)	layerDidAddPart: (NSNotification*)notif
{
	WILDPart	*	thePart = [notif.userInfo objectForKey: WILDAffectedPartKey];
	[self createPartViewForPart: thePart];
}


-(void)	layerWillRemovePart: (NSNotification*)notif
{
	WILDPart	*	thePart = [notif.userInfo objectForKey: WILDAffectedPartKey];
	WILDPartView*	theView = (WILDPartView*) [self visibleObjectForWILDObject: thePart];
	[theView unloadPart];
	[theView removeFromSuperview];
}


-(void)	cardWillGoAway: (NSNotification*)notif
{
	if( mCurrentCard == notif.object )
		[self goNextCard: self];
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


-(IBAction)	showInfoPanel: (id)sender
{
	WILDPartView*		currView = [[[WILDTools sharedTools] clients] anyObject];
	[currView showInfoPanel: sender];
}


-(IBAction)	showCardInfoPanel: (id)sender
{
	if( mCurrentPopover )
		[mCurrentPopover close];
	
	WILDCardInfoViewController*	cardInfo = [[[WILDCardInfoViewController alloc] initWithCard: mCurrentCard ofCardView: (WILDCardView*) [self view]] autorelease];
	mCurrentPopover = [[NSPopover alloc] init];
	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
	[mCurrentPopover setDelegate: self];
	[mCurrentPopover setContentViewController: cardInfo];
	[mCurrentPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinYEdge];
}

-(IBAction)	showBackgroundInfoPanel: (id)sender
{
	if( mCurrentPopover )
		[mCurrentPopover close];
	
	WILDBackgroundInfoViewController*	backgroundInfo = [[[WILDBackgroundInfoViewController alloc] initWithBackground: [mCurrentCard owningBackground] ofCardView: (WILDCardView*) [self view]] autorelease];
	mCurrentPopover = [[NSPopover alloc] init];
	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
	[mCurrentPopover setDelegate: self];
	[mCurrentPopover setContentViewController: backgroundInfo];
	[mCurrentPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinYEdge];
}

-(IBAction)	showStackInfoPanel: (id)sender
{
	if( mCurrentPopover )
		[mCurrentPopover close];
	
	WILDStackInfoViewController*	stackInfo = [[[WILDStackInfoViewController alloc] initWithStack: [mCurrentCard stack] ofCardView: (WILDCardView*) [self view]] autorelease];
	mCurrentPopover = [[NSPopover alloc] init];
	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
	[mCurrentPopover setDelegate: self];
	[mCurrentPopover setContentViewController: stackInfo];
	[mCurrentPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinYEdge];
}


-(void)	popoverDidClose: (NSNotification *)notification
{
	DESTROY(mCurrentPopover);
}


-(IBAction)	editBackgroundScript: (id)sender
{
	WILDScriptEditorWindowController*	sewc = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: [mCurrentCard owningBackground]] autorelease];
	NSRect	wFrame = [[[self view] window] contentRectForFrameRect: [[[self view] window] frame]];
	NSRect	theBox = { {0,0}, {32,32} };
	
	theBox.origin.x += wFrame.origin.x -16;
	theBox.origin.y += wFrame.origin.y -16;
	[sewc setGlobalStartRect: theBox];
	[[[[[self view] window] windowController] document] addWindowController: sewc];
	[sewc showWindow: nil];
}


-(IBAction)	editCardScript: (id)sender
{
	WILDScriptEditorWindowController*	sewc = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mCurrentCard] autorelease];
	NSRect	wFrame = [[[self view] window] contentRectForFrameRect: [[[self view] window] frame]];
	NSRect	theBox = { {0,0}, {32,32} };
	
	theBox.origin.x += wFrame.origin.x -16;
	theBox.origin.y += wFrame.origin.y -16;
	[sewc setGlobalStartRect: theBox];
	[[[[[self view] window] windowController] document] addWindowController: sewc];
	[sewc showWindow: nil];
}


-(IBAction)	editStackScript: (id)sender
{
	WILDScriptEditorWindowController*	sewc = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: [mCurrentCard stack]] autorelease];
	NSRect	wFrame = [[[self view] window] contentRectForFrameRect: [[[self view] window] frame]];
	NSRect	theBox = { {0,0}, {32,32} };
	
	theBox.origin.x += wFrame.origin.x -16;
	theBox.origin.y += wFrame.origin.y -16;
	[sewc setGlobalStartRect: theBox];
	[[[[[self view] window] windowController] document] addWindowController: sewc];
	[sewc showWindow: nil];
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
	
	[self loadCard: mCurrentCard];	// +++ slow
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
	
	[self loadCard: mCurrentCard];	// +++ slow
	[self selectParts: allParts];
}


-(void)	createNewPartFromTemplateAtPathInRepresentedObject: (NSMenuItem*)templateItem
{
	WILDLayer	*	layer = mBackgroundEditMode ? [mCurrentCard owningBackground] : mCurrentCard;
	[layer addNewPartFromXMLTemplate: [NSURL fileURLWithPath: templateItem.representedObject]];
	if( [[WILDTools sharedTools] currentTool] != WILDPointerTool )
		[self toggleEditBrowseTool: self];
	
	[self reloadCard];
}


-(IBAction)	createNewButton: (id)sender
{
	WILDLayer	*	layer = mBackgroundEditMode ? [mCurrentCard owningBackground] : mCurrentCard;
	[layer createNewButton: sender];
	if( [[WILDTools sharedTools] currentTool] != WILDPointerTool )
		[self toggleEditBrowseTool: self];
	
	[self reloadCard];
}


-(IBAction)	createNewField: (id)sender
{
	WILDLayer	*	layer = mBackgroundEditMode ? [mCurrentCard owningBackground] : mCurrentCard;
	[layer createNewField: sender];	
	if( [[WILDTools sharedTools] currentTool] != WILDPointerTool )
		[self toggleEditBrowseTool: self];
}


-(IBAction)	createNewMoviePlayer: (id)sender
{
	WILDLayer	*	layer = mBackgroundEditMode ? [mCurrentCard owningBackground] : mCurrentCard;
	[layer createNewMoviePlayer: sender];
	if( [[WILDTools sharedTools] currentTool] != WILDPointerTool )
		[self toggleEditBrowseTool: self];
}


-(IBAction)	createNewBrowser: (id)sender
{
	WILDLayer	*	layer = mBackgroundEditMode ? [mCurrentCard owningBackground] : mCurrentCard;
	[layer createNewBrowser: sender];
	if( [[WILDTools sharedTools] currentTool] != WILDPointerTool )
		[self toggleEditBrowseTool: self];
}


-(IBAction)	createNewCard: (id)sender
{
	WILDStack		*	theStack = [mCurrentCard stack];
	WILDBackground	*	owningBackground = [mCurrentCard owningBackground];
	WILDCard		*	theNewCard = [[[WILDCard alloc] initForStack: theStack] autorelease];
	[theNewCard setOwningBackground: owningBackground];
	if( mCurrentCard )
		[theStack insertCard: theNewCard atIndex: [theStack.cards indexOfObject: mCurrentCard] +1];
	else
		[theStack addCard: theNewCard];
	[owningBackground addCard: theNewCard];
	
	[self loadCard: theNewCard];
	
	[theStack updateChangeCount: NSChangeDone];
	[theNewCard updateChangeCount: NSChangeDone];
	[owningBackground updateChangeCount: NSChangeDone];
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
	
	if( cardToDelete.cantDelete )
	{
		NSRunAlertPanel( @"Can't delete card", @"%@ has the cantDelete property set to true and can't be deleted.", @"OK", nil, nil, [mCurrentCard displayName] );
		return;
	}
	
	if( owningBackground.cards.count == 1 && owningBackground.cantDelete )
	{
		NSRunAlertPanel( @"Can't delete last card in background", @"%2$@ is the last card in %1$@, which has the cantDelete property set to true and can't be deleted.", @"OK", nil, nil, [owningBackground displayName], [mCurrentCard displayName] );
		return;
	}
	
	if( [[theStack cards] count] <= 1 )
	{
		NSRunAlertPanel( @"Can't delete last card in stack", @"%@ is the last card in %@ and can't be deleted.", @"OK", nil, nil, [mCurrentCard displayName], theStack.displayName );
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDCardWillGoAwayNotification object: cardToDelete];

	[[WILDRecentCardsList sharedRecentCardsList] removeCard: cardToDelete];
	[cardToDelete setOwningBackground: nil];
	[owningBackground removeCard: cardToDelete];
	[theStack removeCard: cardToDelete];
	
	if( ![owningBackground hasCards] )
		[theStack removeBackground: owningBackground];
	else
		[owningBackground updateChangeCount: NSChangeDone];

	[theStack updateChangeCount: NSChangeDone];
}


-(IBAction)	createNewBackground: (id)sender
{
	WILDStack		*	theStack = [mCurrentCard stack];
	WILDBackground	*	theNewBackground = [[[WILDBackground alloc] initForStack: theStack] autorelease];
	[theStack addBackground: theNewBackground];
	WILDCard		*	theNewCard = [[[WILDCard alloc] initForStack: theStack] autorelease];
	[theNewCard setOwningBackground: theNewBackground];
	[theNewBackground addCard: theNewCard];
	[theStack insertCard: theNewCard atIndex: [theStack.cards indexOfObject: mCurrentCard] +1];
	
	[self loadCard: theNewCard];

	[theStack updateChangeCount: NSChangeDone];
	[theNewCard updateChangeCount: NSChangeDone];
	[theNewBackground updateChangeCount: NSChangeDone];
}


-(IBAction)	toggleEditBrowseTool: (id)sender
{
	if( [[WILDTools sharedTools] currentTool] == WILDBrowseTool )
		[[WILDTools sharedTools] setCurrentTool: WILDPointerTool];
	else
		[[WILDTools sharedTools] setCurrentTool: WILDBrowseTool];
	
	[mCardPictureView setCurrentTool: nil];
	[mBackgroundPictureView setCurrentTool: nil];
	
	[[self guidelineView] setNeedsDisplay: YES];
	
	if( [[WILDTools sharedTools] currentTool] != WILDBrowseTool )
	{
		NSToolbar	*editToolbar = [[[NSToolbar alloc] initWithIdentifier: @"WILDEditToolbar"] autorelease];
		[editToolbar setDelegate: self];
		[editToolbar setAllowsUserCustomization: NO];
		[editToolbar setVisible: NO];
		[self.view.window setToolbar: editToolbar];
		[self.view.window toggleToolbarShown: self];
	}
	else
	{
		[self.view.window toggleToolbarShown: self];
		[self.view.window setToolbar: nil];
		if( mBackgroundEditMode )
			[self toggleBackgroundEditMode: sender];	// Switch back to foreground.
	}
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
	
	[[self guidelineView] setNeedsDisplay: YES];
}


-(BOOL)	isPopoverShowing
{
	return mCurrentPopover != nil;
}


-(void)	keyDown: (NSEvent *)event
{
	if( [[event characters] length] == 0 )
	{
		[self.view.window keyDown: event];
		return;
	}
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
	WILDDocument*	theDoc = self.currentCard.stack.document;
	WILDLayer*		currLayer = mBackgroundEditMode ? self.currentCard.owningBackground : self.currentCard;
	
	NSString	*	partsXML = [pb stringForType: WILDPartPboardType];
	if( partsXML )
	{
		NSError			*	err = nil;
		NSXMLDocument	*	xmlDoc = [[[NSXMLDocument alloc] initWithXMLString: partsXML options: 0 error: &err] autorelease];
		if( !xmlDoc )
		{
			UKLog( @"Couldn't read part from pasteboard: %@", err );
			return;
		}
		
		NSArray			*	elems = [[xmlDoc rootElement] children];
		if( !elems )
		{
			UKLog( @"Empty part list on pasteboard." );
			return;
		}
		
		WILDPart		*	newPart = nil;
		BOOL				wasBgPart = NO;
		
		for( NSXMLElement* elem in elems )
		{
			if( [elem.name isEqualToString: @"part"] )
			{
				newPart = [[WILDPart alloc] initWithXMLElement: elem forStack: mCurrentCard.stack];
				wasBgPart = [newPart.partLayer isEqualToString: @"background"];
				
				[currLayer addPart: newPart];
				[newPart release];
			}
			else if( newPart && [elem.name isEqualToString: @"contents"] )
			{
				WILDPartContents	*	newContents = [[WILDPartContents alloc] initWithXMLElement: elem forStack: mCurrentCard.stack];
				[newContents setPartID: newPart.partID];	// ID may have changed to avoid collisions.
				if( [newContents.partLayer isEqualToString: @"card"] )
				{
					if( !wasBgPart && currLayer == mCurrentCard )	// Copy from card to card
						[currLayer addContents: newContents];
					else if( !wasBgPart && currLayer != mCurrentCard )	// Move from cd to bg.
					{
						[currLayer addContents: newContents];
						[newPart setSharedText: YES];
					}
					else if( wasBgPart && currLayer != mCurrentCard )	// Copy from bg to bg.
						[mCurrentCard addContents: newContents];
				}
				else if( [newContents.partLayer isEqualToString: @"background"] )
				{
					[currLayer addContents: newContents];
				}
				[newContents release];
			}
		}
		
		[currLayer updateChangeCount: NSChangeDone];
	}
	else
	{
		NSArray*		imgs = [pb readObjectsForClasses: @[[NSImage class]] options: @{}];
		for( NSImage * img in imgs )
		{
			NSString*		pictureName = @"";
			WILDObjectID	pictureID = [theDoc uniqueIDForMedia];
			[theDoc addMediaFile: nil withType: @"icon" name: pictureName
				andID: pictureID
				hotSpot: NSZeroPoint 
				imageOrCursor: img
				isBuiltIn: NO];
			
			WILDPart*	thePart = [currLayer createNewButtonNamed: pictureName];
			[thePart setIconID: pictureID];
		}
	}
}


-(IBAction)	delete: (id)sender
{
	NSSet	*	theSet = [[WILDTools sharedTools] clients];
	
	for( WILDPartView	*	currPartView in theSet )
	{
		[[self guidelineView] removePartView: currPartView];
		WILDPart	*	thePart = [currPartView part];
		[[thePart partOwner] deletePart: thePart];
	}
}


-(IBAction)	copy: (id)sender
{
	WILDBackground*	currBg = [mCurrentCard owningBackground];
	NSSet			*	theSet = [[WILDTools sharedTools] clients];
	NSMutableString	*	xmlString = [NSMutableString stringWithString: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE parts PUBLIC \"-//Apple, Inc.//DTD stack V 2.0//EN\" \"\" >\n<parts>\n"];

	for( WILDPartView	*	currPartView in theSet )
	{
		WILDPart	*	thePart = [currPartView part];
		[xmlString appendString: [thePart xmlString]];
		NSString*	cdXmlStr = [[mCurrentCard contentsForPart: thePart] xmlString];
		if( cdXmlStr )
			[xmlString appendString: cdXmlStr];
		NSString*	bgXmlStr = [[currBg contentsForPart: thePart] xmlString];
		if( bgXmlStr )
			[xmlString appendString: bgXmlStr];
	}
	[xmlString appendString: @"</parts>"];

	[[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] setString: xmlString forType: WILDPartPboardType];
}


-(IBAction)	cut: (id)sender
{
	[self copy: sender];
	[self delete: sender];
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


-(WILDGuidelineView*)	guidelineView
{
	return mGuidelineView;
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem	*	theItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
	
	// +++ Add final icons
	
	if( [itemIdentifier isEqualToString: WILDCardToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[NSButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"Stack"]];
		[theButton setAction: @selector(showCardInfoPanel:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Card Info"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDBackgroundToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[NSButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"ICON_128"]];
		[theButton setAction: @selector(showBackgroundInfoPanel:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Background Info"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDEditBackgroundToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[NSButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"ICON_129"]];
		[theButton setAction: @selector(toggleBackgroundEditMode:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Edit Background"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDStackToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[NSButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"ICON_1000"]];
		[theButton setAction: @selector(showStackInfoPanel:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Stack Info"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDPrevCardToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[NSButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"ICON_902"]];
		[theButton setAction: @selector(goPrevCard:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Previous Card"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDNextCardToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[NSButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"ICON_26425"]];
		[theButton setAction: @selector(goNextCard:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Next Card"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theItem setView: theButton];
	}
	
	return theItem;
}
    
/* Returns the ordered list of items to be shown in the toolbar by default.   If during initialization, no overriding values are found in the user defaults, or if the user chooses to revert to the default items this set will be used. */
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return @[ WILDStackToolbarItemIdentifier, WILDBackgroundToolbarItemIdentifier, WILDCardToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, WILDEditBackgroundToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, WILDPrevCardToolbarItemIdentifier, WILDNextCardToolbarItemIdentifier ];
}

/* Returns the list of all allowed items by identifier.  By default, the toolbar does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed.  The set of allowed items is used to construct the customization palette.  The order of items does not necessarily guarantee the order of appearance in the palette.  At minimum, you should return the default item list.*/
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return @[ WILDStackToolbarItemIdentifier, WILDBackgroundToolbarItemIdentifier, WILDCardToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, WILDPrevCardToolbarItemIdentifier, WILDNextCardToolbarItemIdentifier ];
}

@end
