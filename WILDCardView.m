//
//  WILDWindowBodyView.m
//  Propaganda
//
//  Created by Uli Kusterer on 21.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDCardView.h"
#import "WILDStack.h"
#import "WILDCard.h"
#import "WILDNotifications.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDPartView.h"
#import "WILDPresentationConstants.h"
#import "WILDXMLUtils.h"
#import "WILDPart.h"
#import "WILDCardViewController.h"


@implementation WILDCardView

-(id)	initWithFrame: (NSRect)frameRect
{
	if(( self = [super initWithFrame: frameRect] ))
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
												name: WILDPeekingStateChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
												name: WILDCurrentToolDidChangeNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(backgroundEditModeChanged:)
												name: WILDBackgroundEditModeChangedNotification
												object: nil];
		[self registerForDraggedTypes: [NSArray arrayWithObject: WILDPartPboardType]];
	}
	
	return self;
}


-(id)	initWithCoder: (NSCoder *)aDecoder
{
	if(( self = [super initWithCoder: aDecoder] ))
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
												name: WILDPeekingStateChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
												name: WILDCurrentToolDidChangeNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(backgroundEditModeChanged:)
												name: WILDBackgroundEditModeChangedNotification
												object: nil];
		[self registerForDraggedTypes: [NSArray arrayWithObject: WILDPartPboardType]];
	}
	
	return self;
}


-(void)	dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDCurrentToolDidChangeNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDBackgroundEditModeChangedNotification
											object: nil];
	[super dealloc];
}


-(void)	setCard: (WILDCard*)inCard
{
	mCard = inCard;
}


-(WILDCard*)	card;
{
	return mCard;
}


-(void)	resetCursorRects
{
	WILDTool	currTool = [[WILDTools sharedTools] currentTool];
	NSCursor*			currCursor = [WILDTools cursorForTool: currTool];
	if( mPeeking )
		currCursor = [NSCursor arrowCursor];
	if( !currCursor )
		currCursor = [[[mCard stack] document] cursorWithID: 128];
	[self addCursorRect: [self visibleRect] cursor: currCursor];
}


-(void)	mouseDown: (NSEvent*)event
{
	if( mPeeking )
	{
		WILDScriptEditorWindowController*	sewc = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mBackgroundEditMode ? [mCard owningBackground] : mCard] autorelease];
		[[[[self window] windowController] document] addWindowController: sewc];
		[sewc showWindow: nil];
	}
	else if( [[WILDTools sharedTools] currentTool] == WILDButtonTool
				|| [[WILDTools sharedTools] currentTool] == WILDFieldTool )
	{
		[[WILDTools sharedTools] deselectAllClients];
	}
	else
	{
		[[self window] makeFirstResponder: self];
		[super mouseDown: event];
	}
}


-(void)	peekingStateChanged: (NSNotification*)notification
{
	[[self window] invalidateCursorRectsForView: self];
	mPeeking = [[[notification userInfo] objectForKey: WILDPeekingStateKey] boolValue];
}

-(void)	backgroundEditModeChanged: (NSNotification*)notification
{
	mBackgroundEditMode = [[[notification userInfo] objectForKey: WILDBackgroundEditModeKey] boolValue];
}


-(void)	currentToolDidChange: (NSNotification*)notification
{
	[[self window] invalidateCursorRectsForView: self];
}


-(BOOL)	acceptsFirstResponder
{
	return YES;
}


-(NSDragOperation)	draggingEntered: (id <NSDraggingInfo>)sender
{
	return( ([sender draggingSource] == self) ? NSDragOperationMove : NSDragOperationCopy );
}


-(BOOL)	performDragOperation: (id <NSDraggingInfo>)sender
{
	NSDragOperation	op = [sender draggingSourceOperationMask];
	NSPoint			pos = [self convertPoint: [sender draggedImageLocation] fromView: nil];
	NSPasteboard*	pb = [sender draggingPasteboard];
	NSString*		xmlStr = [pb stringForType: WILDPartPboardType];
	NSError*		err = nil;
	NSXMLDocument*	doc = [[[NSXMLDocument alloc] initWithXMLString: xmlStr options: 0 error: &err] autorelease];
	NSArray*		parts = [[doc rootElement] elementsForName: @"part"];
	
	if( [sender draggingSource] == self )	// Internal drag.
	{
		NSMutableArray*		draggedParts = [NSMutableArray arrayWithCapacity: [parts count]];
		
		for( NSXMLElement* currPartXml in parts )
		{
			NSInteger	theID = WILDIntegerFromSubElementInElement( @"id", currPartXml );
			NSString*	theLayer = WILDStringFromSubElementInElement( @"layer", currPartXml );
			WILDPart*	thePart = nil;
			if( [theLayer isEqualToString: @"card"] )
				thePart = [mCard partWithID: theID];
			else if( [theLayer isEqualToString: @"background"] )
				thePart = [[mCard owningBackground] partWithID: theID];
			[draggedParts addObject: thePart];
		}
		
		NSPoint		dragStartImagePos = NSZeroPoint;
		NSRect		box = [WILDPartView rectForPeers: draggedParts dragStartImagePos: &dragStartImagePos];
		
		NSPoint		diff = pos;
		diff.x -= box.origin.x;
		diff.y = [self bounds].size.height -diff.y;
		diff.y -= box.origin.y +box.size.height;
		NSLog( @"diff = %@ (src = %@ dst = %@)", NSStringFromPoint(diff), NSStringFromPoint(box.origin), NSStringFromPoint(pos) );
		
		for( WILDPart* currPart in draggedParts )
		{
			NSRect		currPartBox;
			currPartBox = [currPart flippedRectangle];
			currPartBox = NSOffsetRect( currPartBox, diff.x, diff.y );
			[currPart setFlippedRectangle: currPartBox];
		}
		
		[mOwner reloadCard];
	}
	else
		NSLog( @"external" );
	
	return YES;
}


-(void)		setOwner: (WILDCardViewController*)inOwner
{
	mOwner = inOwner;
}

@end
