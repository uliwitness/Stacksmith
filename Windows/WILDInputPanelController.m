//
//  WILDInputPanelController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 04.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDInputPanelController.h"
#import "NSStringDrawing+SizeWithRect.h"


@implementation WILDInputPanelController

@synthesize window;

-(id)	init
{
    self = [super init];
    if (self)
	{
		window = [[NSPanel alloc] initWithContentRect: NSMakeRect(0,0, 500,600) styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
		
        NSView		*	contentView = [window contentView];
		NSRect			availableBox = NSInsetRect( [contentView bounds], 12, 12 );
		
		NSButton	*	okButton = [[NSButton alloc] initWithFrame: availableBox];
		[okButton setBezelStyle: NSRoundedBezelStyle];
		[okButton setTitle: @"OK"];
		[okButton setKeyEquivalent: @"\r"];
		[okButton setFont: [NSFont systemFontOfSize: [NSFont systemFontSizeForControlSize: NSRegularControlSize]]];
		[contentView addSubview: okButton];
		[okButton sizeToFit];
		NSRect		okButtonBox = [okButton frame];
		okButtonBox.size.width += 22;
		okButtonBox.origin.x = NSMaxX(availableBox) -okButtonBox.size.width;
		[okButton setFrame: okButtonBox];

		NSButton	*	cancelButton = [[NSButton alloc] initWithFrame: availableBox];
		[cancelButton setBezelStyle: NSRoundedBezelStyle];
		[cancelButton setTitle: @"Cancel"];
		[cancelButton setKeyEquivalent: @"."];
		[cancelButton setFont: [NSFont systemFontOfSize: [NSFont systemFontSizeForControlSize: NSRegularControlSize]]];
		[contentView addSubview: cancelButton];
		[cancelButton sizeToFit];
		NSRect		cancelButtonBox = [cancelButton frame];
		cancelButtonBox.size.width += 22;
		cancelButtonBox.origin.x = NSMinX(okButtonBox) -4 -cancelButtonBox.size.width;
		[cancelButton setFrame: cancelButtonBox];
		
		availableBox.size.height -= okButtonBox.size.height +12;
		availableBox.origin.y += okButtonBox.size.height +12;
		
		NSTextField	*	editField = [[[NSTextField alloc] initWithFrame: availableBox] autorelease];
		[editField setStringValue: @"This message could become really long and even longer if we added a few dozen additional words."];
		[[editField cell] setWraps: YES];
		[[editField cell] setLineBreakMode: NSLineBreakByWordWrapping];
		[contentView addSubview: editField];
		NSRect	bestRect = availableBox;
		bestRect.size.height = [[editField attributedStringValue] sizeWithRect: NSInsetRect(availableBox,4,4)].height + 8;
		[editField setFrame: bestRect];
		
		availableBox.size.height -= bestRect.size.height +12;
		availableBox.origin.y += bestRect.size.height +12;
		
		NSTextField	*	messageField = [[[NSTextField alloc] initWithFrame: availableBox] autorelease];
		[messageField setStringValue: @"This message could become really long and even longer if we added a few dozen additional words."];
		[[messageField cell] setWraps: YES];
		[messageField setBezeled: NO];
		[messageField setEditable: NO];
		[messageField setSelectable: YES];
		[messageField setDrawsBackground: NO];
		[[messageField cell] setLineBreakMode: NSLineBreakByWordWrapping];
		[contentView addSubview: messageField];
		bestRect = availableBox;
		bestRect.size.height = [[messageField attributedStringValue] sizeWithRect: availableBox].height;
		[messageField setFrame: bestRect];
		
		availableBox.size.height -= bestRect.size.height +12;
		availableBox.origin.y += bestRect.size.height +12;
		
		NSRect		wdFrame = [window contentRectForFrameRect: [window frame]];
		wdFrame.size.height = NSMinY(availableBox);
		[window setFrame: [window frameRectForContentRect: wdFrame] display: NO];
		
		[window center];
		[window makeKeyAndOrderFront: self];
    }
    
    return self;
}

- (void)dealloc
{
	DESTROY_DEALLOC(window);
	
    [super dealloc];
}

@end
