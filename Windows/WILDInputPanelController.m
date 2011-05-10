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
@synthesize answerField;

+(id)	inputPanelWithPrompt: (NSString*)inPrompt answer: (NSString*)inAnswer
{
	return [[[[self class] alloc] initWithPrompt: inPrompt answer: inAnswer] autorelease];
}

-(id)	initWithPrompt: (NSString*)inPrompt answer: (NSString*)inAnswer
{
    self = [super init];
    if (self)
	{
		window = [[NSPanel alloc] initWithContentRect: NSMakeRect(0,0, 422,4000) styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
		[window setReleasedWhenClosed: NO];
		
        NSView		*	contentView = [window contentView];
		NSRect			availableBox = NSInsetRect( [contentView bounds], 12, 12 );
		
		// OK button:
		NSButton	*	okButton = [[[NSButton alloc] initWithFrame: availableBox] autorelease];
		[okButton setBezelStyle: NSRoundedBezelStyle];
		[okButton setTitle: @"OK"];
		[okButton setKeyEquivalent: @"\r"];
		[okButton setFont: [NSFont systemFontOfSize: [NSFont systemFontSizeForControlSize: NSRegularControlSize]]];
		[okButton setTag: NSAlertDefaultReturn];
		[okButton setTarget: self];
		[okButton setAction: @selector(doOKButton:)];
		[contentView addSubview: okButton];
		[okButton sizeToFit];
		NSRect		okButtonBox = [okButton frame];
		okButtonBox.size.width += 22;

		// Cancel button to its left:
		NSButton	*	cancelButton = [[[NSButton alloc] initWithFrame: availableBox] autorelease];
		[cancelButton setBezelStyle: NSRoundedBezelStyle];
		[cancelButton setTitle: @"Cancel"];
		[cancelButton setKeyEquivalent: @"\033"];
		[cancelButton setFont: [NSFont systemFontOfSize: [NSFont systemFontSizeForControlSize: NSRegularControlSize]]];
		[cancelButton setTag: NSAlertAlternateReturn];
		[cancelButton setTarget: self];
		[cancelButton setAction: @selector(doCancelButton:)];
		[contentView addSubview: cancelButton];
		[cancelButton sizeToFit];
		NSRect		cancelButtonBox = [cancelButton frame];
		cancelButtonBox.size.width += 22;
		
		// Now that we know both rects, make both buttons the same size:
		if( cancelButtonBox.size.width > okButtonBox.size.width )
			okButtonBox.size.width = cancelButtonBox.size.width;
		else if( cancelButtonBox.size.width < okButtonBox.size.width )
			cancelButtonBox.size.width = okButtonBox.size.width;
		okButtonBox.origin.x = NSMaxX(availableBox) -okButtonBox.size.width;
		cancelButtonBox.origin.x = NSMinX(okButtonBox) -2 -cancelButtonBox.size.width;
		
		[cancelButton setFrame: cancelButtonBox];
		[okButton setFrame: okButtonBox];

		availableBox.size.height -= okButtonBox.size.height +12;
		availableBox.origin.y += okButtonBox.size.height +12;
		
		// Edit field above the two:
		answerField = [[NSTextField alloc] initWithFrame: availableBox];
		[answerField setStringValue: inAnswer];
		[[answerField cell] setWraps: YES];
		[[answerField cell] setLineBreakMode: NSLineBreakByWordWrapping];
		[contentView addSubview: answerField];
		NSRect	bestRect = availableBox;
		bestRect.size.height = [[answerField attributedStringValue] sizeWithRect: NSInsetRect(availableBox,4,4)].height + 8;
		[answerField setFrame: bestRect];
		
		availableBox.size.height -= bestRect.size.height +12;
		availableBox.origin.y += bestRect.size.height +12;
		
		// Prompt field above that:
		NSTextField	*	messageField = [[[NSTextField alloc] initWithFrame: availableBox] autorelease];
		[messageField setStringValue: inPrompt];
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
		
		// Resize window to fit:
		NSRect		wdFrame = [window contentRectForFrameRect: [window frame]];
		wdFrame.size.height = NSMinY(availableBox);
		[window setFrame: [window frameRectForContentRect: wdFrame] display: NO];
    }
    
    return self;
}


- (void)dealloc
{
	[window close];
	
	DESTROY_DEALLOC(window);
	DESTROY_DEALLOC(answerField);
	
    [super dealloc];
}


-(NSInteger)	runModal
{
	[window center];
	[window makeKeyAndOrderFront: self];

	NSInteger	buttonHit = [NSApp runModalForWindow: [self window]];
	
	[[self window] orderOut: self];
	
	return buttonHit;
}


-(NSString*)	answerString
{
	return [answerField stringValue];
}


-(IBAction)		doOKButton: (id)sender
{
	[NSApp stopModalWithCode: NSAlertDefaultReturn];
}


-(IBAction)		doCancelButton: (id)sender
{
	[NSApp stopModalWithCode: NSAlertAlternateReturn];
}

@end
