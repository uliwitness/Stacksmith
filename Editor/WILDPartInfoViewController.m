//
//  WILDPartInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartInfoViewController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDPart.h"
#import "WILDNotifications.h"


@implementation WILDPartInfoViewController

@synthesize scriptEditorButton;
@synthesize nameField;
@synthesize enabledSwitch;
@synthesize visibleSwitch;
@synthesize numberField;
@synthesize idField;
@synthesize partNumberField;
@synthesize partNumberLabel;

-(id)	initWithPart: (WILDPart*)inPart ofCardView: (WILDCardView*)owningView
{
    self = [super initWithNibName: NSStringFromClass([self class]) bundle: [NSBundle bundleForClass: [self class]]];
    if( self )
	{
        part = [inPart retain];
		cardView = owningView;
    }
    
    return self;
}


-(void)	dealloc
{
	DESTROY(part);
	cardView = nil;	// Nonretained owner.
	DESTROY(scriptEditorButton);
	DESTROY(nameField);
	DESTROY(enabledSwitch);
	DESTROY(visibleSwitch);
	DESTROY(numberField);
	DESTROY(idField);
	DESTROY(partNumberField);
	DESTROY(partNumberLabel);
	DESTROY(contentsTextField);
	
	[super dealloc];
}



-(void)	loadView
{
	[super loadView];
	
	[nameField setStringValue: [part name]];
	
	NSString*	layerName = [[part partLayer] capitalizedString];
	[numberField setIntegerValue: [part partNumberAmongPartsOfType: [part partType]] +1];
	[partNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Part Number:", layerName]];
	[partNumberField setIntegerValue: [part partNumber] +1];
	[idField setIntegerValue: [part partID]];
	
	[enabledSwitch setState: [part isEnabled]];
	[visibleSwitch setState: [part visible]];
	
	if( contentsTextField )
	{
		WILDPartContents*	theContents = nil;
		if( [part sharedText] )
			theContents = [[[cardView card] owningBackground] contentsForPart: part];
		else
			theContents = [[cardView card] contentsForPart: part];
		NSString*					contentsStr = [theContents text];
		[contentsTextField setString: contentsStr ? contentsStr : @""];
	}
}


-(IBAction)	doScriptEditorButton: (id)sender
{
	NSRect		box = [scriptEditorButton convertRect: [scriptEditorButton bounds] toView: nil];
	NSRect		wFrame = [[[self view] window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDScriptEditorWindowController*	se = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: part] autorelease];
	[se setGlobalStartRect: box];
	[[[[[[self view] window] parentWindow] windowController] document] addWindowController: se];
	[se showWindow: self];
}


-(IBAction)	doVisibleSwitchToggled:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setVisible: [visibleSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doEnabledSwitchToggled:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setEnabled: [enabledSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == nameField )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

		[part setName: [nameField stringValue]];
			
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
		[part updateChangeCount: NSChangeDone];
	}
}

@end
