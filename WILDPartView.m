//
//  WILDSelectionView.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDPartView.h"
#import "WILDNotifications.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDPart.h"
#import "WILDPartContents.h"
#import "WILDPartInfoViewController.h"
#import "WILDButtonInfoViewController.h"
#import "WILDFieldInfoViewController.h"
#import "WILDMoviePlayerInfoViewController.h"
#import "WILDCardView.h"
#import "WILDClickablePopUpButtonLabel.h"
#import "WILDButtonCell.h"
#import "WILDTextView.h"
#import "UKIsDragStart.h"
#import "WILDPresentationConstants.h"
#import "WILDButtonView.h"
#import "WILDScrollView.h"
#import "WILDMovieView.h"
#import "NSColor+ULICGColor.h"
#import "LEOHandlerID.h"
#import "LEOContextGroup.h"
#import "LEOScript.h"
#import "WILDPushbuttonPresenter.h"
#import "WILDPopUpButtonPresenter.h"
#import "WILDTextFieldPresenter.h"
#import <QuartzCore/QuartzCore.h>
#import <QTKit/QTKit.h>


@class WILDCardView;


@implementation WILDPartView

@synthesize mainView = mMainView;
@synthesize helperView = mHelperView;
@synthesize isBackgroundEditing = mIsBackgroundEditing;

-(id)	initWithFrame: (NSRect)frameRect
{
	if(( self = [super initWithFrame: frameRect] ))
	{
		
	}
	
	return self;
}


-(void)	dealloc
{
	[mCurrentPopover close];
	DESTROY(mCurrentPopover);
	if( mMouseEventTrackingArea )
	{
		[self removeTrackingArea: mMouseEventTrackingArea];
		DESTROY(mMouseEventTrackingArea);
	}
	
	[[WILDTools sharedTools] removeClient: self];
	[self unsubscribeNotifications];
	[mPartPresenter removeSubviews];
	DESTROY(mPartPresenter);
	
	[super dealloc];
}


-(void)	unsubscribeNotifications
{
	if( !mPart )
		return;
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPartWillChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPartDidChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDCurrentToolDidChangeNotification
											object: nil];
}


-(void)	subscribeNotifications
{
	if( !mPart )
		return;
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
											name: WILDPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partWillChange:)
											name: WILDPartWillChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partDidChange:)
											name: WILDPartDidChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
											name: WILDCurrentToolDidChangeNotification
											object: nil];
}


-(void)	highlightSearchResultInRange: (NSRange)theRange
{
	[(NSTextView*)mMainView setSelectedRange: theRange];
	[(NSTextView*)mMainView scrollRangeToVisible: theRange];
	[(NSTextView*)mMainView showFindIndicatorForRange: theRange];
}


-(void)	animate: (id)sender
{
	WILDGuidelineView*	guidelineView = [[self enclosingCardView] guidelineView];
	[guidelineView setNeedsDisplay: YES];
}


-(BOOL)	myToolIsCurrent
{
	BOOL	isMyTool = ([[WILDTools sharedTools] currentTool] == WILDButtonTool && [[mPart partType] isEqualToString: @"button"])
						|| ([[WILDTools sharedTools] currentTool] == WILDFieldTool && [[mPart partType] isEqualToString: @"field"])
						|| ([[WILDTools sharedTools] currentTool] == WILDMoviePlayerTool && [[mPart partType] isEqualToString: @"moviePlayer"])
						|| ([[WILDTools sharedTools] currentTool] == WILDPointerTool);
	return isMyTool;
}


-(void)	setSelected: (BOOL)inState
{
	if( mSelected != inState )
	{
		mSelected = inState;
		WILDGuidelineView*	guidelineView = [[self enclosingCardView] guidelineView];
		
		if( mSelected )
		{
			[[WILDTools sharedTools] addClient: self];
			[guidelineView addSelectedPartView: self];
		}
		else
		{
			[[WILDTools sharedTools] removeClient: self];
			[guidelineView removeSelectedPartView: self];
		}
	}
}


-(BOOL)	isSelected
{
	return mSelected;
}


-(void)	drawSelectionHighlightInView: (NSView*)overlayView
{
	NSRect	subviewFrame = [self selectionRect];
	
	[[NSColor keyboardFocusIndicatorColor] set];
	NSRect	clampedBounds = subviewFrame;
	clampedBounds.origin.x = truncf(clampedBounds.origin.x) + 0.5;
	clampedBounds.origin.y = truncf(clampedBounds.origin.y) + 0.5;
	clampedBounds.size.width -= 1;
	clampedBounds.size.height -= 1;
	NSBezierPath*	selPath = [NSBezierPath bezierPathWithRect: clampedBounds];
	CGFloat			pattern[2] = { 4, 4 };
	[[NSColor whiteColor] set];
	[selPath stroke];
	[selPath setLineDash: pattern count: 2 phase: [[WILDTools sharedTools] animationPhase]];
	[[NSColor keyboardFocusIndicatorColor] set];
	[selPath stroke];
}


-(void)	drawPartFrameInView: (NSView*)overlayView
{
	NSRect	subviewFrame = [self selectionRect];
	BOOL	isMyTool = [self myToolIsCurrent];
	
	if( isMyTool && ![self isSelected] )
	{
		if( [[mPart style] isEqualToString: @"opaque"] )
			[[[WILDTools sharedTools] peekPattern] set];
		else
			[[NSColor grayColor] set];
		NSRect	peekBox = NSInsetRect( subviewFrame, 0.5, 0.5 );
		[NSBezierPath setDefaultLineWidth: 1];
		[NSBezierPath strokeRect: peekBox];
		[[NSColor blackColor] set];
	}
    if( mPeeking && ([self myToolIsCurrent]
		|| ([[WILDTools sharedTools] currentTool] == WILDBrowseTool && [[mPart partType] isEqualToString: @"button"])) )
	{
		NSRect	peekBox = NSInsetRect( subviewFrame, 1, 1 );
		[NSBezierPath setDefaultLineWidth: 2];
		[[NSColor lightGrayColor] set];
		[[NSColor blueColor] set];
		[NSBezierPath strokeRect: peekBox];
		[[[WILDTools sharedTools] peekPattern] set];
		[NSBezierPath strokeRect: peekBox];
		[NSBezierPath setDefaultLineWidth: 1];
	}
}


-(NSView *)	hitTest: (NSPoint)aPoint	// Equivalent to Carbon kEventControlInterceptSubviewClick.
{
	BOOL	isMyTool = [self myToolIsCurrent];
	NSView*	hitView = [super hitTest: aPoint];
	if( hitView != nil )	// Was in our view or a sub view, not outside us?
	{
		if( mPeeking || isMyTool )
			hitView = self;		// Redirect to us.
		else if( [[WILDTools sharedTools] currentTool] != WILDBrowseTool )	// Another tool than the ones we support?
			hitView = nil;	// Pretend we (or our subviews) weren't hit at all.
		else if( [[WILDTools sharedTools] currentTool] == WILDBrowseTool && hitView == self )	// Browse tool but not in our subviews?
			hitView = nil;	// Pretend we weren't hit at all. Maybe a view under us does better.
	}
	
	return hitView;
}


-(NSSize)	grabHandleSize
{
	NSRect					myRect = self.bounds;
	CGSize					handleSize = { 8, 8 };
	
	if( (myRect.size.width /3) < handleSize.width )
		handleSize.width = handleSize.height = truncf(myRect.size.width /3);
	if( (myRect.size.height /3) < handleSize.height )
		handleSize.width = handleSize.height = truncf(myRect.size.height /3);
	
	return handleSize;
}


-(WILDPartGrabHandle)	grabHandleAtPoint: (NSPoint)localPoint
{
	WILDPartGrabHandle		clickedHandle = 0;
	NSRect					myRect = self.bounds;
	CGSize					handleSize = [self grabHandleSize];
	
	if( NSPointInRect(localPoint, myRect ) )
	{
		if( NSMinX(myRect) <= localPoint.x && (NSMinX(myRect) +handleSize.width) >= localPoint.x )
			clickedHandle |= WILDPartGrabHandleLeft;
		if( NSMaxX(myRect) >= localPoint.x && (NSMaxX(myRect) -handleSize.width) <= localPoint.x )
			clickedHandle |= WILDPartGrabHandleRight;
		if( NSMinY(myRect) <= localPoint.y && (NSMinY(myRect) +handleSize.height) >= localPoint.y )
			clickedHandle |= WILDPartGrabHandleBottom;
		if( NSMaxY(myRect) >= localPoint.y && (NSMaxY(myRect) -handleSize.height) <= localPoint.y )
			clickedHandle |= WILDPartGrabHandleTop;
		// If we're not in one of the corners, user may be trying to drag separator, even when at the left edge:
		if( ((clickedHandle & WILDPartGrabHandleLeft) == 0 || ((clickedHandle & WILDPartGrabHandleTop) == 0 && (clickedHandle & WILDPartGrabHandleBottom) == 0))
			&& (NSMinX(myRect) +[mPart titleWidth]) <= localPoint.x && (NSMinX(myRect) +[mPart titleWidth] +handleSize.width) >= localPoint.x )
			clickedHandle |= WILDPartGrabHandleSeparator;
	}
	
	return clickedHandle;
}


-(NSRect)	rectForGrabHandle: (WILDPartGrabHandle)inHandle
{
	NSRect	handleRect = [self bounds];
	CGSize	handleSize = [self grabHandleSize];
	
	if( inHandle == 0 )	// Rect for everything *but* the handles, as much as possible. (The separator is usually ignored because it may cause a non-rectangular area)
		handleRect = NSInsetRect( handleRect, handleSize.width, handleSize.height );
	else if( inHandle & WILDPartGrabHandleSeparator )
	{
		handleRect.size.width = handleSize.width;
		handleRect.origin.x = [mPart titleWidth];
	}
	else
	{
		if( inHandle & WILDPartGrabHandleLeft )
			handleRect.size.width = handleSize.width;
		else if( inHandle & WILDPartGrabHandleRight )
		{
			handleRect.origin.x = NSMaxX(handleRect) -handleSize.width;
			handleRect.size.width = handleSize.width;
		}
		else	// Don't overlap the resize corners.
		{
			handleRect.origin.x += handleSize.width;
			handleRect.size.width -= handleSize.width * 2.0;
		}
		
		if( inHandle & WILDPartGrabHandleBottom )
			handleRect.size.height = handleSize.height;
		else if( inHandle & WILDPartGrabHandleTop )
		{
			handleRect.origin.y = NSMaxY(handleRect) -handleSize.height;
			handleRect.size.height = handleSize.height;
		}
		else	// Don't overlap the resize corners.
		{
			handleRect.origin.y += handleSize.height;
			handleRect.size.height -= handleSize.height * 2.0;
		}
	}
		
	return handleRect;
}


-(NSRect)	layoutRectForRect: (NSRect)newBox
{
	NSRect	layoutBox = NSInsetRect( newBox, 2, 2 );
	
	NSString*	theStyle = [mPart style];
	if( [[mPart partType] isEqualToString: @"moviePlayer"] )
		;	// No special behaviours for movie players.
	else if( [[mPart partType] isEqualToString: @"field"] )
		;	// No special behaviours for movie players.
	else if( [[mPart partType] isEqualToString: @"button"] )
	{
		if( [theStyle isEqualToString: @"default"] || [theStyle isEqualToString: @"standard"] )
		{
			#if 0
			layoutBox.origin.x += 6;
			layoutBox.origin.y += 5;
			layoutBox.size.width -= 12;
			layoutBox.size.height -= 7;
			#else
			NSEdgeInsets	insets = [mMainView alignmentRectInsets];
			layoutBox.origin.x += insets.left;
			layoutBox.origin.y += 3;
			layoutBox.size.height -= 3;
			layoutBox.size.width -= insets.left +insets.right;
			#endif
		}
		else if( [theStyle isEqualToString: @"popup"] )
		{
			#if 0
			layoutBox.origin.x += 3 +[mPart titleWidth];
			layoutBox.origin.y += 3;
			layoutBox.size.width -= 6 +[mPart titleWidth];
			layoutBox.size.height -= 6;
			#else
			NSEdgeInsets	insets = [mMainView alignmentRectInsets];
			layoutBox.origin.x += [mPart titleWidth] +insets.left;
			layoutBox.origin.y += 3;
			layoutBox.size.height -= 3;
			layoutBox.size.width -= insets.left +insets.right +[mPart titleWidth];
			#endif
		}
	}
	
	return layoutBox;
}


-(NSRect)	selectionRect
{
	NSRect	mainFrame = [mMainView convertRect: [mMainView bounds] toView: [self superview]];
	NSRect	helperFrame = NSZeroRect;
	
	if( mHelperView )
		helperFrame = [self convertRect: [mHelperView frame] toView: [self superview]];
	
	if( [[mPart partType] isEqualToString: @"field"] )
		return helperFrame;	// For fields, this is the scroll view around them.
	else if( mHelperView )
	{
		helperFrame = [mHelperView convertRect: [mHelperView bounds] toView: [self superview]];
	
		return NSUnionRect( mainFrame, helperFrame );
	}
	else
		return mainFrame;
}


-(void) setUpGuidelinesForMovingAndSnapRect: (NSRect*)inBigBox
{
	NSRect						inBox = [self layoutRectForRect: *inBigBox];
	WILDGuidelineView*			guidelineView = [[self enclosingCardView] guidelineView];
	
	[guidelineView removeAllGuidelines];
	
	CGFloat					left = [guidelineView bounds].origin.x +20,
							bottom = [guidelineView bounds].origin.y +20;
	CGFloat					top = [guidelineView bounds].origin.y +[guidelineView bounds].size.height -20,
							right = [guidelineView bounds].origin.x +[guidelineView bounds].size.width -20; 
	// Find parallels to other parts:
	CGFloat					xMovement = CGFLOAT_MAX,
							yMovement = CGFLOAT_MAX;
	CGFloat					horzGuidelinePos = -1,	// -1 is a nonsense position for a guideline (wouldn't be visible), so we use that to indicate "ignore".
							vertGuidelinePos = -1;
	
	// Show guidelines at 12px distance from edges & snap to them:
	//	(Aqua standard distance to window edge)
	if( ((left -6) < NSMinX(inBox)) && ((left +6) > NSMinX(inBox)) )
	{
		CGFloat		horzDiff = NSMinX(inBox) -left;
		if( fabs(horzDiff) < fabs(xMovement) )
		{
			xMovement = horzDiff;
			horzGuidelinePos = left;
		}
	}
	if( ((right -6) < NSMaxX(inBox)) && ((right +6) > NSMaxX(inBox)) )
	{
		CGFloat		horzDiff = NSMaxX(inBox) -right;
		if( fabs(horzDiff) < fabs(xMovement) )
		{
			xMovement = horzDiff;
			horzGuidelinePos = right;
		}
	}
	if( ((top -6) < NSMaxY(inBox)) && ((top +6) > NSMaxY(inBox)) )
	{
		CGFloat		vertDiff = NSMaxY(inBox) -top;
		if( fabs(vertDiff) < fabs(yMovement) )
		{
			yMovement = vertDiff;
			vertGuidelinePos = top;
		}
	}
	if( ((bottom -6) < NSMinY(inBox)) && ((bottom +6) > NSMinY(inBox)) )
	{
		CGFloat		vertDiff = NSMinY(inBox) -bottom;
		if( fabs(vertDiff) < fabs(yMovement) )
		{
			yMovement = vertDiff;
			vertGuidelinePos = bottom;
		}
	}
	
	// Guidelines at card center (horz & vert):
	CGFloat	hCenter = NSMidX([guidelineView bounds]);
	CGFloat	vCenter = NSMidY([guidelineView bounds]);
	if( ((hCenter -6) < NSMidX(inBox)) && ((hCenter +6) > NSMidX(inBox)) )
	{
		CGFloat		horzDiff = NSMidX(inBox) -hCenter;
		if( fabs(horzDiff) < fabs(xMovement) )
		{
			xMovement = horzDiff;
			horzGuidelinePos = hCenter;
		}
	}
	if( ((vCenter -6) < NSMidY(inBox)) && ((vCenter +6) > NSMidY(inBox)) )
	{
		CGFloat		vertDiff = NSMidY(inBox) -vCenter;
		if( fabs(vertDiff) < fabs(yMovement) )
		{
			yMovement = vertDiff;
			vertGuidelinePos = vCenter;
		}
	}
	
	// Snap to card edges:
	if( ([guidelineView bounds].origin.x +6) > NSMinX(inBox) && ([guidelineView bounds].origin.x -6) < NSMinX(inBox) )
	{
		CGFloat		horzDiff = NSMinX(inBox) -[guidelineView bounds].origin.x;
		if( fabs(horzDiff) < fabs(xMovement) )
		{
			xMovement = horzDiff;
			horzGuidelinePos = 0;
		}
	}
	if( ([guidelineView bounds].origin.y +6) > NSMinY(inBox) && ([guidelineView bounds].origin.y -6) < NSMinY(inBox) )
	{
		CGFloat		horzDiff = NSMinY(inBox) -[guidelineView bounds].origin.y;
		if( fabs(horzDiff) < fabs(xMovement) )
		{
			xMovement = horzDiff;
			horzGuidelinePos = 0;
		}
	}
	if( (NSMaxX([guidelineView bounds]) -6) < NSMaxX(inBox) && (NSMaxX([guidelineView bounds]) +6) > NSMaxX(inBox) )
	{
		CGFloat		vertDiff = NSMaxX(inBox) -NSMaxX([guidelineView bounds]);
		if( fabs(vertDiff) < fabs(yMovement) )
		{
			yMovement = vertDiff;
			vertGuidelinePos = 0;
		}
	}
	if( (NSMaxY([guidelineView bounds]) -6) < NSMaxY(inBox) && (NSMaxY([guidelineView bounds]) +6) > NSMaxY(inBox) )
	{
		CGFloat		vertDiff = NSMaxY(inBox) -NSMaxY([guidelineView bounds]);
		if( fabs(vertDiff) < fabs(yMovement) )
		{
			yMovement = vertDiff;
			vertGuidelinePos = 0;
		}
	}
	
	// Find other parts that align with this one:
	for( WILDPartView* currPartView in [[self superview] subviews] )
	{
		if( currPartView != self && [currPartView isKindOfClass: [WILDPartView class]] )
		{
			NSRect	currBox = [currPartView layoutRectForRect: [currPartView frame]];
			if( ((NSMinX(currBox) -6) < NSMinX(inBox)) && ((NSMinX(currBox) +6) > NSMinX(inBox)) )
			{
				CGFloat		horzDiff = NSMinX(inBox) -NSMinX(currBox);
				if( fabs(horzDiff) < fabs(xMovement) )
				{
					xMovement = horzDiff;
					horzGuidelinePos = NSMinX(currBox);
				}
			}
			if( ((NSMaxX(currBox) -6) < NSMaxX(inBox)) && ((NSMaxX(currBox) +6) > NSMaxX(inBox)) )
			{
				CGFloat		horzDiff = NSMaxX(inBox) -NSMaxX(currBox);
				if( fabs(horzDiff) < fabs(xMovement) )
				{
					xMovement = horzDiff;
					horzGuidelinePos = NSMaxX(currBox);
				}
			}
			if( ((NSMaxY(currBox) -6) < NSMaxY(inBox)) && ((NSMaxY(currBox) +6) > NSMaxY(inBox)) )
			{
				CGFloat		vertDiff = NSMaxY(inBox) -NSMaxY(currBox);
				if( fabs(vertDiff) < fabs(yMovement) )
				{
					yMovement = vertDiff;
					vertGuidelinePos = NSMaxY(currBox);
				}
			}
			if( ((NSMinY(currBox) -6) < NSMinY(inBox)) && ((NSMinY(currBox) +6) > NSMinY(inBox)) )
			{
				CGFloat		vertDiff = NSMinY(inBox) -NSMinY(currBox);
				if( fabs(vertDiff) < fabs(yMovement) )
				{
					yMovement = vertDiff;
					vertGuidelinePos = NSMinY(currBox);
				}
				break;
			}
			
			// Also try to find out if we're at a standard distance next to another part:
			NSRect	currMarginsBox = NSInsetRect( currBox, -6, -6 );
			if( ((NSMinX(currMarginsBox) -6) < NSMaxX(inBox)) && ((NSMinX(currMarginsBox) +6) > NSMaxX(inBox)) )
			{
				CGFloat		horzDiff = NSMaxX(inBox) -NSMinX(currMarginsBox);
				if( fabs(horzDiff) < fabs(xMovement) )
				{
					xMovement = horzDiff;
					horzGuidelinePos = NSMinX(currMarginsBox);
				}
			}
			if( ((NSMaxX(currMarginsBox) -6) < NSMinX(inBox)) && ((NSMaxX(currMarginsBox) +6) > NSMinX(inBox)) )
			{
				CGFloat		horzDiff = NSMinX(inBox) -NSMaxX(currMarginsBox);
				if( fabs(horzDiff) < fabs(xMovement) )
				{
					xMovement = horzDiff;
					horzGuidelinePos = NSMaxX(currMarginsBox);
				}
			}
			if( ((NSMaxY(currMarginsBox) -6) < NSMinY(inBox)) && ((NSMaxY(currMarginsBox) +6) > NSMinY(inBox)) )
			{
				CGFloat		vertDiff = NSMinY(inBox) -NSMaxY(currMarginsBox);
				if( fabs(vertDiff) < fabs(yMovement) )
				{
					yMovement = vertDiff;
					vertGuidelinePos = NSMaxY(currMarginsBox);
				}
			}
			if( ((NSMinY(currMarginsBox) -6) < NSMaxY(inBox)) && ((NSMinY(currMarginsBox) +6) > NSMaxY(inBox)) )
			{
				CGFloat		vertDiff = NSMaxY(inBox) -NSMinY(currMarginsBox);
				if( fabs(vertDiff) < fabs(yMovement) )
				{
					yMovement = vertDiff;
					vertGuidelinePos = NSMinY(currMarginsBox);
				}
				break;
			}
		}
	}
	
	// Now that we've found the closest two guidelines, show them:
	if( horzGuidelinePos != -1 )
	{
		if( horzGuidelinePos > 0 )
			[guidelineView addGuidelineAt: horzGuidelinePos horizontal: NO color: [NSColor blueColor]];
		inBigBox->origin.x -= xMovement;
	}
	if( vertGuidelinePos != -1 )
	{
		if( vertGuidelinePos > 0 )
			[guidelineView addGuidelineAt: vertGuidelinePos horizontal: YES color: [NSColor blueColor]];
		inBigBox->origin.y -= yMovement;
	}
	
	[guidelineView setNeedsDisplay: YES];
}


-(void) setUpGuidelinesForResizingWithHandle: (WILDPartGrabHandle)inHandle andSnapRect: (NSRect*)inBigBox
{
	NSRect						inBox = [self layoutRectForRect: *inBigBox];
	WILDGuidelineView*			guidelineView = [[self enclosingCardView] guidelineView];
	
	[guidelineView removeAllGuidelines];
	
	CGFloat					left = [guidelineView bounds].origin.x +20,
							bottom = [guidelineView bounds].origin.y +20;
	CGFloat					top = [guidelineView bounds].origin.y +[guidelineView bounds].size.height -20,
							right = [guidelineView bounds].origin.x +[guidelineView bounds].size.width -20; 
	
	// Show guidelines at 12px distance from edges & snap to them:
	//	(Aqua standard distance to window edge)
	if( (inHandle & WILDPartGrabHandleLeft) && ((left -6) < NSMinX(inBox)) && ((left +6) > NSMinX(inBox)) )
	{
		[guidelineView addGuidelineAt: left horizontal: NO color: [NSColor blueColor]];
		inBigBox->origin.x -= NSMinX(inBox) -left;
	}
	if( (inHandle & WILDPartGrabHandleRight) && ((right -6) < NSMaxX(inBox)) && ((right +6) > NSMaxX(inBox)) )
	{
		[guidelineView addGuidelineAt: right horizontal: NO color: [NSColor blueColor]];
		inBigBox->size.width += NSMaxX(inBox) -right;
	}
	if( (inHandle & WILDPartGrabHandleTop) && ((top -6) < NSMaxY(inBox)) && ((top +6) > NSMaxY(inBox)) )
	{
		[guidelineView addGuidelineAt: top horizontal: YES color: [NSColor blueColor]];
		inBigBox->origin.y -= NSMaxY(inBox) -top;
	}
	if( (inHandle & WILDPartGrabHandleBottom) && ((bottom -6) < NSMinY(inBox)) && ((bottom +6) > NSMinY(inBox)) )
	{
		[guidelineView addGuidelineAt: bottom horizontal: YES color: [NSColor blueColor]];
		inBigBox->size.height += NSMinY(inBox) -bottom;
	}
	
	// Guidelines at card center (horz & vert):
	CGFloat	hCenter = NSMidX([guidelineView bounds]);
	CGFloat	vCenter = NSMidY([guidelineView bounds]);
	if( ((hCenter -6) < NSMidX(inBox)) && ((hCenter +6) > NSMidX(inBox)) )
	{
		[guidelineView addGuidelineAt: hCenter horizontal: NO color: [NSColor blueColor]];
	}
	if( vCenter == NSMidY(inBox) )
	{
		[guidelineView addGuidelineAt: vCenter horizontal: YES color: [NSColor blueColor]];
	}
	
	// Snap to card edges:
	if( (inHandle & WILDPartGrabHandleLeft) && ([guidelineView bounds].origin.x +6) > NSMinX(inBox) && ([guidelineView bounds].origin.x -6) < NSMinX(inBox) )
		inBigBox->origin.x -= NSMinX(inBox) -[guidelineView bounds].origin.x;
	if( (inHandle & WILDPartGrabHandleRight) && ([guidelineView bounds].origin.y +6) > NSMinY(inBox) && ([guidelineView bounds].origin.y -6) < NSMinY(inBox) )
		inBigBox->origin.y -= NSMinY(inBox) -[guidelineView bounds].origin.y;
	if( (inHandle & WILDPartGrabHandleTop) && (NSMaxX([guidelineView bounds]) -6) < NSMaxX(inBox) && (NSMaxX([guidelineView bounds]) +6) > NSMaxX(inBox) )
		inBigBox->origin.x -= NSMaxX(inBox) -NSMaxX([guidelineView bounds]);
	if( (inHandle & WILDPartGrabHandleBottom) && (NSMaxY([guidelineView bounds]) -6) < NSMaxY(inBox) && (NSMaxY([guidelineView bounds]) +6) > NSMaxY(inBox) )
		inBigBox->origin.y -= NSMaxY(inBox) -NSMaxY([guidelineView bounds]);
	
	[guidelineView setNeedsDisplay: YES];
}


-(void)	moveView
{
	NSAutoreleasePool	*	pool = [[NSAutoreleasePool alloc] init];
	BOOL					keepDragging = YES;
	NSRect					newBox = [self frame];
	
	while( keepDragging )
	{
		NSEvent		*	theEvent = [NSApp nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask untilDate: [NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( theEvent )
		{
			switch( [theEvent type] )
			{
				case NSLeftMouseUp:
					keepDragging = NO;
					break;
				
				case NSLeftMouseDragged:
				{
					CGFloat	deltaX = [theEvent deltaX];
					CGFloat	deltaY = -[theEvent deltaY];
					
					newBox.origin.x += deltaX;
					newBox.origin.y += deltaY;
					
					NSRect	correctedBox = newBox;
					[self setUpGuidelinesForMovingAndSnapRect: &correctedBox];
					
					[self setFrame: correctedBox];
					break;
				}
			}
		}
		
		[pool drain];
		pool = [[NSAutoreleasePool alloc] init];
	}

	[pool drain];
	
	WILDGuidelineView*			guidelineView = [[self enclosingCardView] guidelineView];
	[guidelineView removeAllGuidelines];
	[guidelineView setNeedsDisplay: YES];

	[mPart setRectangle: NSInsetRect( self.frame, 2, 2)];
	[mPart updateChangeCount: NSChangeDone];
}


-(void)	resizeViewUsingHandle: (WILDPartGrabHandle)inHandle
{
	NSAutoreleasePool	*	pool = [[NSAutoreleasePool alloc] init];
	BOOL					keepDragging = YES;
	NSRect					frame = [self frame];
	CGFloat					titleWidth = [mPart titleWidth];
	
	while( keepDragging )
	{
		NSEvent		*	theEvent = [NSApp nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask untilDate: [NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( theEvent )
		{
			switch( [theEvent type] )
			{
				case NSLeftMouseUp:
					keepDragging = NO;
					break;
				
				case NSLeftMouseDragged:
				{
					CGFloat	deltaX = [theEvent deltaX];
					CGFloat	deltaY = -[theEvent deltaY];
					
					if( inHandle & WILDPartGrabHandleSeparator && [mPart canHaveTitleWidth] )	// May overlap with left.
					{
						titleWidth += deltaX;
						[mPart setTitleWidth: (titleWidth < 0) ? 0 : titleWidth];
						[self unloadPart];
						[self loadPart: mPart forBackgroundEditing: NO];
					}
					else if( inHandle & WILDPartGrabHandleLeft )
					{
						frame.origin.x += deltaX;
						frame.size.width -= deltaX;
					}
					else if( inHandle & WILDPartGrabHandleRight )
						frame.size.width += deltaX;

					if( inHandle & WILDPartGrabHandleTop )
						frame.size.height += deltaY;
					else if( inHandle & WILDPartGrabHandleBottom )
					{
						frame.origin.y += deltaY;
						frame.size.height -= deltaY;
					}
					
					NSRect	newBox = frame;
					[self setUpGuidelinesForResizingWithHandle: inHandle andSnapRect: &newBox ];
					[self setFrame: newBox];
					break;
				}
			}
		}
		
		[pool drain];
		pool = [[NSAutoreleasePool alloc] init];
	}

	[pool drain];
	
	[mPart setRectangle: NSInsetRect( self.frame, 2, 2)];
	[mPart updateChangeCount: NSChangeDone];
	
	WILDGuidelineView*			guidelineView = [[self enclosingCardView] guidelineView];
	[guidelineView removeAllGuidelines];
	[guidelineView setNeedsDisplay: YES];
}


-(IBAction)	showInfoPanel: (id)sender
{
	[mCurrentPopover close];
	DESTROY(mCurrentPopover);
	
	NSViewController*	infoController = nil;
	if( [[mPart partType] isEqualToString: @"button"] )
		infoController = [[WILDButtonInfoViewController alloc] initWithPart: mPart ofCardView: [self enclosingCardView]];
	else if( [[mPart partType] isEqualToString: @"field"] )
		infoController = [[WILDFieldInfoViewController alloc] initWithPart: mPart ofCardView: [self enclosingCardView]];
	else if( [[mPart partType] isEqualToString: @"moviePlayer"] )
		infoController = [[WILDMoviePlayerInfoViewController alloc] initWithPart: mPart ofCardView: [self enclosingCardView]];
	else
		infoController = [[WILDPartInfoViewController alloc] initWithPart: mPart ofCardView: [self enclosingCardView]];
	[infoController autorelease];

	mCurrentPopover = [[NSPopover alloc] init];
	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
	[mCurrentPopover setDelegate: self];
	[mCurrentPopover setContentViewController: infoController];
	[mCurrentPopover showRelativeToRect: self.bounds ofView: self preferredEdge: NSMinYEdge];
}


-(void)	mouseDown: (NSEvent*)event
{
	BOOL	isMyTool = [self myToolIsCurrent];
	if( mPeeking )
	{
		WILDScriptEditorWindowController*	sewc = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mPart] autorelease];
		[sewc setGlobalStartRect: [self frameInScreenCoordinates]];
		[[[[self window] windowController] document] addWindowController: sewc];
		[sewc showWindow: nil];
	}
	else if( isMyTool )
	{
		WILDPartGrabHandle	hitHandle = [self grabHandleAtPoint: [self convertPoint: [event locationInWindow] fromView: nil]];
		
		if( [event clickCount] == 2 && mSelected )
		{
			[self showInfoPanel: self];
		}
		else
		{
			BOOL		justSelected = NO;
			if( !mSelected )
			{
				[self selectionClick: event];
				justSelected = YES;
			}
			
			if( UKIsDragStart( event, 0.0 ) )
			{
				if( hitHandle == 0 )
				{
				#if 0
					NSPasteboard*   		pb = [NSPasteboard pasteboardWithName: NSDragPboard];
					[pb clearContents];
					NSPoint					dragStartImagePos = NSZeroPoint;
					NSArray*				selectedObjects = [[[WILDTools sharedTools] clients] allObjects];
					NSImage*				theDragImg = [[self class] imageForPeers: selectedObjects
															ofView: self
															dragStartImagePos: &dragStartImagePos];
					WILDCard*		currCard = [[self enclosingCardView] card];
					WILDBackground*	currBg = [currCard owningBackground];
					
					NSMutableString*		xmlString = [[@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE parts PUBLIC \"-//Apple, Inc.//DTD stack V 2.0//EN\" \"\" >\n<parts>\n" mutableCopy] autorelease];
					for( WILDPartView* selView in selectedObjects )
					{
						WILDPart*	thePart = [selView part];
						[xmlString appendString: [thePart xmlString]];
						NSString*	cdXmlStr = [[currCard contentsForPart: thePart] xmlString];
						if( cdXmlStr )
							[xmlString appendString: cdXmlStr];
						NSString*	bgXmlStr = [[currBg contentsForPart: thePart] xmlString];
						if( bgXmlStr )
							[xmlString appendString: bgXmlStr];
					}
					[xmlString appendString: @"</parts>"];
	//				NSLog(@"xmlString = %@",xmlString);
					
					[pb addTypes: [NSArray arrayWithObject: WILDPartPboardType] owner: [self enclosingCardView]];
					[pb setString: xmlString forType: WILDPartPboardType];
					
					// Actually commence the drag:
					[self dragImage: theDragImg at: dragStartImagePos offset: NSMakeSize(0,0)
								event: event pasteboard: pb source: [self enclosingCardView] slideBack: YES];
					#else
					[self moveView];
					#endif
				}
				else
				{
					[self resizeViewUsingHandle: hitHandle];
				}
			}
			else if( !justSelected )
			{
				[self selectionClick: event];
			}
		}
	}
	else
	{
		[[self window] makeFirstResponder: [self superview]];
		[super mouseDown: event];
	}
}


-(void)	selectionClick: (NSEvent*)event
{
	if( [event modifierFlags] & NSShiftKeyMask
		|| [event modifierFlags] & NSCommandKeyMask )
		[self setSelected: !mSelected];
	else
	{
		[[WILDTools sharedTools] deselectAllClients];
		WILDGuidelineView*	guidelineView = [[self enclosingCardView] guidelineView];
		[guidelineView removeAllSelectedPartViews];
		[self setSelected: YES];
	}
	[self setNeedsDisplay: YES];
	[mMainView setNeedsDisplay: YES];
	[mHelperView setNeedsDisplay: YES];
}


+(NSImage*)	imageForPeers: (NSArray*)views ofView: (NSView*)inView dragStartImagePos: (NSPoint*)dragStartImagePos
{
	CGFloat		minX = LONG_MAX, maxX = LONG_MIN, minY = LONG_MAX, maxY = LONG_MIN;
	NSPoint		viewOrigin = inView ? [inView frame].origin : NSZeroPoint;
	
	for( NSView* theView in views )
	{
		NSRect		box = [theView frame];
		if( minX > NSMinX(box) )
			minX = NSMinX(box);
		if( maxX < NSMaxX(box) )
			maxX = NSMaxX(box);
		if( minY > NSMinY(box) )
			minY = NSMinY(box);
		if( maxY < NSMaxY(box) )
			maxY = NSMaxY(box);
	}
	
	NSImage*		theImage = [[[NSImage alloc] initWithSize: NSMakeSize( maxX -minX, maxY -minY)] autorelease];
	
	[theImage lockFocus];
	CGContextRef		currContext = [[NSGraphicsContext currentContext] graphicsPort];

	[[NSColor redColor] set];
	
	for( WILDPartView* theView in views )
	{
		[NSGraphicsContext saveGraphicsState];
		
		CALayer*	theLayer = [theView layer];
		NSRect		layerFrame = [theLayer frame];
		
		layerFrame.origin.x -= minX;
		layerFrame.origin.y -= minY;
		
		NSAffineTransform*	transform = [NSAffineTransform transform];
		[transform translateXBy: layerFrame.origin.x yBy: layerFrame.origin.y];
		[transform concat];
		
		BOOL	wasSelected = theView->mSelected;
		theView->mSelected = NO;
		[theView display];
		[[theView mainView] display];
		[[theView helperView] display];
		[theLayer renderInContext: currContext];
		theView->mSelected = wasSelected;
		
		[NSGraphicsContext restoreGraphicsState];
	}
	[theImage unlockFocus];
	
	dragStartImagePos->x = -viewOrigin.x +minX;
	dragStartImagePos->y = -viewOrigin.y +minY;
	
	return theImage;
}


+(NSRect)	rectForPeers: (NSArray*)parts dragStartImagePos: (NSPoint*)dragStartImagePos
{
	CGFloat		minX = LONG_MAX, maxX = LONG_MIN, minY = LONG_MAX, maxY = LONG_MIN;
	NSPoint		viewOrigin = NSZeroPoint;
	
	for( WILDPart* thePart in parts )
	{
		NSRect		box = [thePart flippedRectangle];
		if( minX > NSMinX(box) )
			minX = NSMinX(box);
		if( maxX < NSMaxX(box) )
			maxX = NSMaxX(box);
		if( minY > NSMinY(box) )
			minY = NSMinY(box);
		if( maxY < NSMaxY(box) )
			maxY = NSMaxY(box);
	}
		
	dragStartImagePos->x = -viewOrigin.x +minX;
	dragStartImagePos->y = -viewOrigin.y +minY;
	
	return NSMakeRect(minX, minY, maxX -minX, maxY -minY);
}


-(void)	peekingStateChanged: (NSNotification*)notification
{
	mPeeking = [[[notification userInfo] objectForKey: WILDPeekingStateKey] boolValue];
}


-(void)	textDidChange: (NSNotification *)notification
{
	WILDPartContents	*	contents = [self currentPartContentsAndBackgroundContents: nil create: YES];
	
	[contents setStyledText: [mMainView textStorage]];
	
	[mPart updateChangeCount: NSChangeDone];
}


-(void)	refreshPartPresenter
{
	[mPartPresenter removeSubviews];
	DESTROY(mPartPresenter);
	if( [[mPart partType] isEqualToString: @"button"] )
	{
		if( [[mPart style] isEqualToString: @"popup"] )
			mPartPresenter = [[WILDPopUpButtonPresenter alloc] initWithPartView: self];
		else
			mPartPresenter = [[WILDPushbuttonPresenter alloc] initWithPartView: self];
	}
	else if( [[mPart partType] isEqualToString: @"field"] )
		mPartPresenter = [[WILDTextFieldPresenter alloc] initWithPartView: self];
	[mPartPresenter createSubviews];
}


-(void)	setPart: (WILDPart*)inPart
{
	if( inPart == nil )
		[self unsubscribeNotifications];
	
	mPart = inPart;
	[self refreshPartPresenter];
	
	if( mPart != nil )
		[self subscribeNotifications];
}


-(WILDPart*)	part
{
	return mPart;
}


-(WILDCardView*)	enclosingCardView
{
	WILDCardView*		mySuper = (WILDCardView*) [self superview];
	if( mySuper && [mySuper isKindOfClass: [WILDCardView class]] )
		return mySuper;
	else
		return nil;
}

-(void)	partWillChange: (NSNotification*)notif
{
	WILDPart	*	thePart = [notif object];
	NSString	*	propName = [[notif userInfo] objectForKey: WILDAffectedPropertyKey];
	SEL				theAction = NSSelectorFromString( [propName stringByAppendingString: @"PropertyWillChangeOfPart:"] );
	if( [self respondsToSelector: theAction] )
		[self performSelector: theAction withObject: thePart];
	[mPartPresenter partWillChange: notif];
}


-(void)	partDidChange: (NSNotification*)notif
{
	WILDPart	*	thePart = [notif object];
	NSString	*	propName = [[notif userInfo] objectForKey: WILDAffectedPropertyKey];
	SEL				theAction = NSSelectorFromString( [propName stringByAppendingString: @"PropertyDidChangeOfPart:"] );
	if( [self respondsToSelector: theAction] )
		[self performSelector: theAction withObject: thePart];
	if( mPartPresenter )
		[mPartPresenter partDidChange: notif];
	else	// Unknown property. Reload the whole thing.
	{
		[self setFrame: NSInsetRect([mPart rectangle], -2, -2)];
		[self unloadPart];
		[self loadPart: mPart forBackgroundEditing: NO];
	}
}


-(void)	highlightedPropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( [mMainView respondsToSelector: @selector(setState:)] )
		[(NSButton*)mMainView setState: [mPart highlighted] ? NSOnState : NSOffState];
}


-(void)	visiblePropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( [mMainView respondsToSelector: @selector(setHidden:)] )
		[self setHidden: ![mPart visible]];
}


-(void)	enabledPropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( [mMainView respondsToSelector: @selector(setEnabled:)] )
		[(NSButton*)mMainView setEnabled: [mPart isEnabled]];
}


-(void)	iconPropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( [mMainView respondsToSelector: @selector(setImage:)] )
		[(NSButton*)mMainView setImage: [mPart iconImage]];
}


-(void)	scriptPropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self updateTrackingAreas];
}


-(void)	currentToolDidChange: (NSNotification*)notification
{
	[self setSelected: NO];
	[self setNeedsDisplay: YES];
	[mMainView setNeedsDisplay: YES];
	[mHelperView setNeedsDisplay: YES];
}


-(void)	savePart
{
	if( [[mPart partType] isEqualToString: @"moviePlayer"] )
		[mPart setCurrentTime: [(QTMovie*)[mMainView movie] currentTime]];
}


-(void)	unloadPart
{
	[self savePart];
	
	NSArray*	subviews = [[[self subviews] copy] autorelease];
	for( NSView* currView in subviews )
		[currView removeFromSuperview];
	[self setMainView: nil];
	[self setHelperView: nil];
	[self unsubscribeNotifications];
}


-(void)	updateOnClick: (NSButton*)sender
{
	WILDCardView*		winView = [self enclosingCardView];
	WILDCard*			theCd = [winView card];
	WILDBackground*		theBg = [theCd owningBackground];

	[mPart updateViewOnClick: sender withCard: theCd background: theBg];
}


-(void)	loadPopupButton: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	NSRect			partRect = [currPart rectangle];
	NSTextField*	label = nil;
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	NSRect		popupBox = partRect;
	if( [currPart titleWidth] > 0 )
	{
		NSRect	titleBox = popupBox;
		titleBox.size.width = 10000;
		popupBox.origin.x += [currPart titleWidth];
		popupBox.size.width -= [currPart titleWidth];
		
		label = [[WILDClickablePopUpButtonLabel alloc] initWithFrame: titleBox];
		[label setWantsLayer: YES];
		[label setEditable: NO];
		[label setSelectable: NO];
		[label setDrawsBackground: NO];
		[label setBezeled: NO];
		[label setBordered: NO];
		[label setAlignment: NSRightTextAlignment];
		[[label cell] setWraps: NO];
		if( [currPart showName] )
			[label setStringValue: [currPart name]];
		[label setEnabled: [currPart isEnabled]];
		[label setFont: [currPart textFont]];
		[label setFrame: titleBox];
		[label sizeToFit];
		titleBox = [label frame];
		titleBox.size.width = [currPart titleWidth];
		titleBox.origin.y = truncf((partRect.size.height -titleBox.size.height) /2) +2;	// account for shadow
		titleBox.origin.x = partRect.origin.x;
		[label setFrame: titleBox];
		
		[self addSubview: label];
		[label setAutoresizingMask: NSViewMinYMargin | NSViewMaxYMargin];
		
		[self setHelperView: label];
	}
	
	NSPopUpButton	*	bt = [[NSPopUpButton alloc] initWithFrame: popupBox];
	[bt setWantsLayer: YES];
	[bt setFont: [currPart textFont]];
	[bt setTarget: self];
	[bt setAction: @selector(updateOnClick:)];
	[bt setEnabled: [currPart isEnabled]];
	
	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[self layer] setShadowColor: theColor];
		[[self layer] setShadowOpacity: 1.0];
		[[self layer] setShadowOffset: [currPart shadowOffset]];
		[[self layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[self layer] setShadowOpacity: 0.0];
	
	NSArray*	popupItems = ([contents text] != nil) ? [contents listItems] : [bgContents listItems];
	for( NSString* itemName in popupItems )
	{
		if( [itemName hasPrefix: @"-"] )
			[[bt menu] addItem: [NSMenuItem separatorItem]];
		else
			[bt addItemWithTitle: itemName];
	}
	NSUInteger selIndex = [[currPart selectedListItemIndexes] firstIndex];
	if( selIndex == NSNotFound )
		selIndex = 0;
	[bt selectItemAtIndex: selIndex];
	[bt setState: [currPart highlighted] ? NSOnState : NSOffState];
	
	if( [self helperView] )
		[(WILDClickablePopUpButtonLabel*)[self helperView] setPopUpButton: bt];
	
	[self addSubview: bt];
	[bt setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
	[self setMainView: bt];
	
	if( label )
	{
		[[bt cell] accessibilitySetOverrideValue: [label cell] forAttribute: NSAccessibilityTitleUIElementAttribute];
	}
	
	[bt release];
}


-(void)	loadPushButton: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	[mPartPresenter createSubviews];
	[mPartPresenter refreshProperties];
	
//	BOOL		isHighlighted = [currPart highlighted];
//	if( ![currPart sharedHighlight] && [[currPart partLayer] isEqualToString: @"background"] )
//		isHighlighted = [contents highlighted];
//	
//	BOOL			canHaveIcon = YES;
//	NSButton	*	bt = [[WILDButtonView alloc] initWithFrame: partRect];
//	[bt setEnabled: [currPart isEnabled]];
//	
//	if( [[currPart style] isEqualToString: @"transparent"] )
//	{
//		[bt setCell: [[[WILDButtonCell alloc] initTextCell: @""] autorelease]];
//		[bt setBordered: NO];
//
//		[bt setAlignment: [currPart textAlignment]];	
//		[bt setButtonType: NSMomentaryPushInButton];
//		
//#if TRANSPARENT_BUTTONS_INVERT
//		if( isHighlighted )
//		{
//			CALayer*	theLayer = [self layer];
//			[theLayer setOpaque: NO];
//			CIFilter*	theFilter = [CIFilter filterWithName: @"CIDifferenceBlendMode"];
//			[theFilter setDefaults];
//			//[theLayer setSize: [self bounds].size];
//			[theLayer setCompositingFilter: theFilter];
//		}
//#endif
//	}
//	else if( [[currPart style] isEqualToString: @"opaque"] )
//	{
//		[bt setCell: [[[WILDButtonCell alloc] initTextCell: @""] autorelease]];
//		[bt setBordered: NO];
//		[[bt cell] setBackgroundColor: [NSColor whiteColor]];
//		[bt setAlignment: [currPart textAlignment]];	
//		[bt setButtonType: NSMomentaryPushInButton];
//	}
//	else if( [[currPart style] isEqualToString: @"rectangle"]
//			|| [[currPart style] isEqualToString: @"roundrect"]
//			|| [[currPart style] isEqualToString: @"oval"] )
//	{
//		WILDButtonCell*	ourCell = [[[WILDButtonCell alloc] initTextCell: @""] autorelease];
//		[ourCell setBackgroundColor: [currPart fillColor]];
//		[ourCell setLineColor: [currPart lineColor]];
//		[bt setCell: ourCell];
//		[bt setBordered: YES];
//				
//		if( [[currPart style] isEqualToString: @"roundrect"]
//			|| [[currPart style] isEqualToString: @"standard"]
//			|| [[currPart style] isEqualToString: @"default"] )
//			[bt setBezelStyle: NSRoundedBezelStyle];
//		else if( [[currPart style] isEqualToString: @"oval"] )
//			[bt setBezelStyle: NSCircularBezelStyle];
//
//		if( [[currPart style] isEqualToString: @"default"] )
//		{
//			[bt setKeyEquivalent: @"\r"];
//			[ourCell setDrawAsDefault: YES];
//		}
//		[bt setAlignment: [currPart textAlignment]];	
//		[bt setButtonType: NSMomentaryPushInButton];
//	}
//	else if( [[currPart style] isEqualToString: @"standard"]
//			|| [[currPart style] isEqualToString: @"default"] )
//	{
//		[bt setBordered: YES];
//		[bt setBezelStyle: NSRoundedBezelStyle];
//		
//		if( [[currPart style] isEqualToString: @"default"] )
//			[bt setKeyEquivalent: @"\r"];
//		[bt setAlignment: [currPart textAlignment]];	
//		[bt setButtonType: NSMomentaryPushInButton];
//	}
//	else if( [[currPart style] isEqualToString: @"checkbox"] )
//	{
//		[bt setButtonType: NSSwitchButton];
//		canHaveIcon = NO;
//	}
//	else if( [[currPart style] isEqualToString: @"radiobutton"] )
//	{
//		[bt setButtonType: NSRadioButton];
//		canHaveIcon = NO;
//	}

	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[self layer] setShadowColor: theColor];
		[[self layer] setShadowOpacity: 1.0];
		[[self layer] setShadowOffset: [currPart shadowOffset]];
		[[self layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[self layer] setShadowOpacity: 0.0];
	
//	[bt setFont: [currPart textFont]];
//	if( [currPart showName] )
//		[bt setTitle: [currPart name]];
//	[bt setTarget: self];
//	[bt setAction: @selector(updateOnClick:)];
//	[bt setState: isHighlighted ? NSOnState : NSOffState];
//	
//	if( canHaveIcon && [currPart iconID] != 0 )
//	{
//		[bt setImage: [currPart iconImage]];
//		
//		if( [currPart iconID] == -1 || [[currPart name] length] == 0
//			|| ![currPart showName] )
//			[bt setImagePosition: NSImageOnly];
//		else
//			[bt setImagePosition: NSImageAbove];
//		if( [currPart iconID] != -1 && [currPart iconID] != 0 )
//			[bt setFont: [NSFont fontWithName: @"Geneva" size: 9.0]];
//		[[bt cell] setImageScaling: NSImageScaleNone];
//	}
//	
//	[self addSubview: bt];
//	[bt setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
//	[self setMainView: bt];
//	
//	[bt release];
}


-(void)	loadButton: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	if( [[currPart style] isEqualToString: @"popup"] )
	{
		[self loadPopupButton: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
	else
	{
		[self loadPushButton: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
}


-(void)	loadEditField: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	WILDTextView	*	tv = [[WILDTextView alloc] initWithFrame: partRect];
	[tv setFont: [currPart textFont]];
	[tv setWantsLayer: YES];
	[tv setDrawsBackground: NO];
	[tv setUsesFindPanel: NO];
	[tv setDelegate: self];
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
	
	// A field can be edited if:
	//	It is a card field and its lockText is FALSE.
	//	It is a bg field, its lockText is FALSE its sharedText is TRUE and we're editing the background.
	//	It is a bg field, its lockText is FALSE and its sharedText is FALSE.
	BOOL		shouldBeEditable = ![currPart lockText] && (![currPart sharedText] || backgroundEditMode);
	if( ![currPart isEnabled] )
		shouldBeEditable = NO;
	[tv setEditable: shouldBeEditable];
	[tv setSelectable: shouldBeEditable];
	
	WILDScrollView*	sv = [[WILDScrollView alloc] initWithFrame: partRect];
	[sv setDocumentCursor: [[[currPart stack] document] cursorWithID: 128]];
	[sv setWantsLayer: YES];
	NSRect			txBox = partRect;
	txBox.origin = NSZeroPoint;
	if( [[currPart style] isEqualToString: @"transparent"] )
	{
		[sv setBorderType: NSNoBorder];
		[sv setDrawsBackground: NO];
		[tv setDrawsBackground: NO];
	}
	else if( [[currPart style] isEqualToString: @"opaque"] )
	{
		[sv setBorderType: NSNoBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
	}
	else if( [[currPart style] isEqualToString: @"standard"] )
	{
		[sv setBorderType: NSBezelBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
	}
	else if( [[currPart style] isEqualToString: @"roundrect"] )
	{
		[sv setBorderType: NSBezelBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
	}
	else if( [[currPart style] isEqualToString: @"scrolling"] )
	{
		txBox.size.width -= 15;
		[sv setBorderType: NSLineBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
	}
	else
	{
		[sv setBorderType: NSLineBorder];
		[sv setBackgroundColor: [currPart fillColor]];
		[sv setLineColor: [currPart lineColor]];
	}
	[sv setVerticalScrollElasticity: [currPart hasVerticalScroller] ? NSScrollElasticityAutomatic : NSScrollElasticityNone];
	[sv setHasVerticalScroller: [currPart hasVerticalScroller]];
	[sv setHorizontalScrollElasticity: [currPart hasHorizontalScroller] ? NSScrollElasticityAutomatic : NSScrollElasticityNone];
	[sv setHasHorizontalScroller: [currPart hasHorizontalScroller]];

	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[sv layer] setShadowColor: theColor];
		[[sv layer] setShadowOpacity: 1.0];
		[[sv layer] setShadowOffset: [currPart shadowOffset]];
		[[sv layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[sv layer] setShadowOpacity: 0.0];

	[tv setFrame: txBox];
	[sv setDocumentView: tv];
	[sv setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self addSubview: sv];
	[self setHelperView: sv];
	[self setMainView: tv];
	
	[tv release];
}


-(void)	loadListField: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
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
	NSTextFieldCell*	dc = [[NSTextFieldCell alloc] initTextCell: @"Are you my mummy?"];
	[tc setDataCell: dc];
	[dc release];
	[tv addTableColumn: tc];
	[tc release];
	[tv setDataSource: self];
	[tv setDelegate: self];
	
	// Build surrounding scroll view:
	NSScrollView*	sv = [[WILDScrollView alloc] initWithFrame: partRect];
	[sv setDocumentCursor: [[[currPart stack] document] cursorWithID: 128]];
	[sv setWantsLayer: YES];
	NSRect			txBox = [currPart rectangle];
	txBox.origin = NSZeroPoint;
	if( [[currPart style] isEqualToString: @"transparent"] )
	{
		[sv setBorderType: NSNoBorder];
		[sv setDrawsBackground: NO];
		[tv setBackgroundColor: [NSColor clearColor]];
	}
	else if( [[currPart style] isEqualToString: @"opaque"] )
	{
		[sv setBorderType: NSNoBorder];
		[tv setBackgroundColor: [NSColor whiteColor]];
	}
	else if( [[currPart style] isEqualToString: @"standard"] )
	{
		[sv setBorderType: NSBezelBorder];
		[tv setBackgroundColor: [NSColor whiteColor]];
	}
	else
	{
		[sv setBorderType: NSLineBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
	}
	[sv setVerticalScrollElasticity: [currPart hasVerticalScroller] ? NSScrollElasticityAutomatic : NSScrollElasticityNone];
	[sv setHasVerticalScroller: [currPart hasVerticalScroller]];
	[sv setHorizontalScrollElasticity: [currPart hasHorizontalScroller] ? NSScrollElasticityAutomatic : NSScrollElasticityNone];
	[sv setHasHorizontalScroller: [currPart hasHorizontalScroller]];

	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[sv layer] setShadowColor: theColor];
		[[sv layer] setShadowOpacity: 1.0];
		[[sv layer] setShadowOffset: [currPart shadowOffset]];
		[[sv layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[sv layer] setShadowOpacity: 0.0];

	[tv setFrame: txBox];
	[tc setWidth: txBox.size.width];
	[tc setMaxWidth: 1000000.0];
	[tc setMinWidth: 10.0];
	[sv setDocumentView: tv];
	[sv setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self addSubview: sv];
	[self setHelperView: sv];
	[self setMainView: tv];

	NSIndexSet*	idxes = [currPart selectedListItemIndexes];
	if( idxes )
		[tv selectRowIndexes: idxes byExtendingSelection: NO];
	
	[tv release];
}


-(void)	loadField: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	if( [currPart autoSelect] && [currPart lockText] )
	{
		[self loadListField: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
	else if( [[currPart style] isEqualToString: @"transparent"] || [[currPart style] isEqualToString: @"opaque"]
		|| [[currPart style] isEqualToString: @"rectangle"]
		|| [[currPart style] isEqualToString: @"standard"]
		|| [[currPart style] isEqualToString: @"roundrect"] )
	{
		[self loadEditField: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
	else
	{
		[self loadEditField: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
}


-(void)	loadMoviePlayer: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	QTMovieView		* mpv = [[[WILDMovieView alloc] initWithFrame: partRect] autorelease];
	NSError			* outError = nil;
	NSString		* movPath = [[NSBundle mainBundle] pathForResource: [currPart mediaPath] ofType: @""];
	if( !movPath )
		movPath = [currPart mediaPath];
	QTMovie			* mov = [QTMovie movieWithFile: movPath error: &outError];
	[mov setCurrentTime: [currPart currentTime]];
	[mpv setMovie: mov];

	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[self layer] setShadowColor: theColor];
		[[self layer] setShadowOpacity: 1.0];
		[[self layer] setShadowOffset: [currPart shadowOffset]];
		[[self layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[self layer] setShadowOpacity: 0.0];

	[mpv setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[mpv setPreservesAspectRatio: YES];
	[mpv setControllerVisible: [currPart controllerVisible]];
	[self addSubview: mpv];
	
	[self setHelperView: nil];
	[self setMainView: mpv];
}


-(void)	loadPart: (WILDPart*)currPart forBackgroundEditing: (BOOL)backgroundEditMode
{
	WILDPartContents*	contents = nil;
	WILDPartContents*	bgContents = nil;
	
	mIsBackgroundEditing = backgroundEditMode;
	mPart = currPart;
	
	contents = [self currentPartContentsAndBackgroundContents: &bgContents create: NO];
	
	/*if( [[currPart partType] isEqualToString: @"button"] )
		[self loadButton: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	else if( [[currPart partType] isEqualToString: @"field"] )
		[self loadField: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	else*/ if( [[currPart partType] isEqualToString: @"moviePlayer"] )
		[self loadMoviePlayer: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	else
		[self setPart: mPart];
}


-(WILDPartContents*)	currentPartContentsAndBackgroundContents: (WILDPartContents**)outBgContents create: (BOOL)inDoCreate
{
	WILDCardView*		winView = [self enclosingCardView];
	WILDCard*			theCd = [winView card];
	
	return [mPart currentPartContentsAndBackgroundContents: outBgContents create: inDoCreate onCard: theCd forBackgroundEditing: mIsBackgroundEditing];
}


-(NSRect)	frameInScreenCoordinates
{
	NSRect				buttonRect = [mPart rectangle];
	WILDCardView	*	cardView = [self enclosingCardView];
	buttonRect = [cardView convertRectToBase: buttonRect];
	buttonRect.origin = [[cardView window] convertBaseToScreen: buttonRect.origin];
	return buttonRect;
}


//-(void)	drawRect:(NSRect)dirtyRect
//{
//	[[NSColor blueColor] set];
//	[NSBezierPath strokeRect: [self bounds]];
//}


-(void)	tableViewSelectionDidChange:(NSNotification *)notification
{
	[mPart setSelectedListItemIndexes: [(NSTableView*)mMainView selectedRowIndexes]];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	WILDPartContents*	contents = nil;
	WILDPartContents*	bgContents = nil;
	contents = [self currentPartContentsAndBackgroundContents: &bgContents create: NO];
	
	return [[contents listItems] count];
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	WILDPartContents*	contents = nil;
	WILDPartContents*	bgContents = nil;
	contents = [self currentPartContentsAndBackgroundContents: &bgContents create: NO];
	
	return [[contents listItems] objectAtIndex: row];
}


-(void)	updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if( mMouseEventTrackingArea )
	{
		[self removeTrackingArea: mMouseEventTrackingArea];
		DESTROY(mMouseEventTrackingArea);
	}
	
	bool				haveMoveHandlers = false;
	bool				haveEnterExitHandlers = false;
	LEOHandlerID		theEnterHandler = LEOContextGroupHandlerIDForHandlerName( [mPart scriptContextGroupObject], "mouseEnter" );
	LEOHandlerID		theLeaveHandler = LEOContextGroupHandlerIDForHandlerName( [mPart scriptContextGroupObject], "mouseLeave" );
	LEOHandlerID		theMoveHandler = LEOContextGroupHandlerIDForHandlerName( [mPart scriptContextGroupObject], "mouseMove" );
	struct LEOScript* 	theScript = [mPart scriptObjectShowingErrorMessage: NO];
	if( theScript )
	{
		if( LEOScriptFindCommandHandlerWithID( theScript, theEnterHandler ) != NULL )
			haveEnterExitHandlers |= true;
		if( LEOScriptFindCommandHandlerWithID( theScript, theLeaveHandler ) != NULL )
			haveEnterExitHandlers |= true;
		if( LEOScriptFindCommandHandlerWithID( theScript, theMoveHandler ) != NULL )
			haveMoveHandlers |= true;
		
		if( haveMoveHandlers || haveEnterExitHandlers )
		{
			NSTrackingAreaOptions	theOptions = NSTrackingActiveInActiveApp | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited;
			if( haveMoveHandlers )
				theOptions |= NSTrackingMouseMoved;
			mMouseEventTrackingArea = [[NSTrackingArea alloc] initWithRect: NSZeroRect options: theOptions owner: self userInfo: nil];
			[self addTrackingArea: mMouseEventTrackingArea];
		}
	}
}


-(void)	resetCursorRects
{
	[super resetCursorRects];
	
	NSCursor	*	currentCursor = [WILDTools cursorForTool: [[WILDTools sharedTools] currentTool]];
	if( !currentCursor )
	{
		currentCursor = [[[mPart stack] document] cursorWithID: 128];
	}
	[self addCursorRect: [self visibleRect] cursor: currentCursor];
	if( [self myToolIsCurrent] )
	{
		[self addCursorRect: [self rectForGrabHandle: 0] cursor: currentCursor];
		if( [[mPart partType] isEqualToString: @"button"]
			&& [[mPart style] isEqualToString: @"popup"] )
		{
			NSRect	splitterRect = [self rectForGrabHandle: WILDPartGrabHandleSeparator];
			NSCursor* bestCursor = [NSCursor resizeLeftRightCursor];
			if( [mPart titleWidth] <= 0 )	// Already at minimum.
				bestCursor = [NSCursor resizeRightCursor];
			else if( [mPart titleWidth] >= [self bounds].size.width )	// Already at maximum.
				bestCursor = [NSCursor resizeLeftCursor];
			[self addCursorRect: splitterRect cursor: bestCursor];
		}
		
		NSRect	leftEdgeRect = [self rectForGrabHandle: WILDPartGrabHandleLeft];
		[self addCursorRect: leftEdgeRect cursor: [NSCursor resizeLeftRightCursor]];
		NSRect	rightEdgeRect = [self rectForGrabHandle: WILDPartGrabHandleRight];
		[self addCursorRect: rightEdgeRect cursor: [NSCursor resizeLeftRightCursor]];

		NSRect	topEdgeRect = [self rectForGrabHandle: WILDPartGrabHandleTop];
		[self addCursorRect: topEdgeRect cursor: [NSCursor resizeUpDownCursor]];
		NSRect	bottomEdgeRect = [self rectForGrabHandle: WILDPartGrabHandleBottom];
		[self addCursorRect: bottomEdgeRect cursor: [NSCursor resizeUpDownCursor]];
		
		NSImage		*	nwSeImage = [NSImage imageNamed: @"NW_SE_ResizeCursor"];
		[nwSeImage setSize: NSMakeSize(16, 16)];
		NSImage		*	neSwImage = [NSImage imageNamed: @"NE_SW_ResizeCursor"];
		[neSwImage setSize: NSMakeSize(16, 16)];
		NSCursor	*	nwSeResizeCursor = [[[NSCursor alloc] initWithImage: nwSeImage hotSpot:NSMakePoint(8, 8)] autorelease];
		NSCursor	*	neSwResizeCursor = [[[NSCursor alloc] initWithImage: neSwImage hotSpot:NSMakePoint(8, 8)] autorelease];
		NSRect	topLeftRect = [self rectForGrabHandle: WILDPartGrabHandleLeft | WILDPartGrabHandleTop];
		[self addCursorRect: topLeftRect cursor: nwSeResizeCursor];
		NSRect	bottomLeftRect = [self rectForGrabHandle: WILDPartGrabHandleLeft | WILDPartGrabHandleBottom];
		[self addCursorRect: bottomLeftRect cursor: neSwResizeCursor];
		NSRect	topRightRect = [self rectForGrabHandle: WILDPartGrabHandleRight | WILDPartGrabHandleTop];
		[self addCursorRect: topRightRect cursor: neSwResizeCursor];
		NSRect	bottomRightRect = [self rectForGrabHandle: WILDPartGrabHandleRight | WILDPartGrabHandleBottom];
		[self addCursorRect: bottomRightRect cursor: nwSeResizeCursor];
	}
	else
		[self addCursorRect: [self visibleRect] cursor: currentCursor];
}


-(void)	mouseEntered:(NSEvent *)theEvent
{
	if( [[WILDTools sharedTools] currentTool] == WILDBrowseTool && !mPeeking )
		WILDScriptContainerResultFromSendingMessage( mPart, @"mouseEnter" );
}


-(void)	mouseExited:(NSEvent *)theEvent
{
	if( [[WILDTools sharedTools] currentTool] == WILDBrowseTool && !mPeeking )
		WILDScriptContainerResultFromSendingMessage( mPart, @"mouseLeave" );
}


-(void)	mouseMoved:(NSEvent *)theEvent
{
	if( [[WILDTools sharedTools] currentTool] == WILDBrowseTool && !mPeeking )
		WILDScriptContainerResultFromSendingMessage( mPart, @"mouseMove" );
}


-(void)	popoverDidClose: (NSNotification *)notification
{
	DESTROY(mCurrentPopover);
}


-(void)	removeFromSuperview
{
	[mPartPresenter removeSubviews];
}

@end
