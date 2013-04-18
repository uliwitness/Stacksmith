//
//  WILDPartInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartInfoViewController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDContentsEditorWindowController.h"
#import "WILDUserPropertyEditorWindowController.h"
#import "WILDPart.h"
#import "WILDLayer.h"
#import "WILDNotifications.h"
#import "UKHelperMacros.h"


@implementation WILDPartInfoViewController

@synthesize scriptEditorButton;
@synthesize nameField;
@synthesize enabledSwitch;
@synthesize visibleSwitch;
@synthesize numberField;
@synthesize idField;
@synthesize partNumberField;
@synthesize partNumberLabel;
@synthesize fillColorWell;
@synthesize lineColorWell;
@synthesize shadowColorWell;
@synthesize shadowBlurRadiusSlider;
@synthesize shadowOffsetSlider;
@synthesize contentsEditorButton;
@synthesize lineWidthSlider;
@synthesize userPropertyEditorButton;


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
	DESTROY(fillColorWell);
	DESTROY(lineColorWell);
	DESTROY(shadowColorWell);
	DESTROY(contentsEditorButton);
	
	[super dealloc];
}



-(void)	loadView
{
	[super loadView];
	
	[nameField setStringValue: [part name]];
	
	NSString*	layerName = [[part partLayer] capitalizedString];
	[numberField setIntegerValue: [[part partOwner] indexOfPart: part asType: [part partType]] +1];
	[partNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Part Number:", layerName]];
	[partNumberField setIntegerValue: [part partNumber] +1];
	[idField setIntegerValue: [part partID]];
	
	[enabledSwitch setState: [part isEnabled]];
	[visibleSwitch setState: [part visible]];
	
	[fillColorWell setColor: [part fillColor]];
	[lineColorWell setColor: [part lineColor]];
	[shadowColorWell setColor: [part shadowColor]];
	[shadowBlurRadiusSlider setDoubleValue: [part shadowBlurRadius]];
	[shadowOffsetSlider setDoubleValue: [part shadowOffset].width];
	[lineWidthSlider setDoubleValue: [part lineWidth]];
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


-(IBAction)	doContentsEditorButton: (id)sender
{
	NSRect		box = [contentsEditorButton convertRect: [contentsEditorButton bounds] toView: nil];
	NSRect		wFrame = [[[self view] window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDContentsEditorWindowController*	se = [[[WILDContentsEditorWindowController alloc] initWithPart: part] autorelease];
	[se setGlobalStartRect: box];
	[se setCardView: cardView];
	[[[[[[self view] window] parentWindow] windowController] document] addWindowController: se];
	[se showWindow: self];
}


-(IBAction)	doUserPropertyEditorButton: (id)sender
{
	NSRect		box = [userPropertyEditorButton convertRect: [userPropertyEditorButton bounds] toView: nil];
	NSRect		wFrame = [[[self view] window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDUserPropertyEditorWindowController*	se = [[[WILDUserPropertyEditorWindowController alloc] initWithPropertyContainer: part] autorelease];
	[se setGlobalStartRect: box];
	[se setCardView: cardView];
	[[[[[[self view] window] parentWindow] windowController] document] addWindowController: se];
	[se showWindow: self];
}


-(IBAction)	doVisibleSwitchToggled:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(visible), WILDAffectedPropertyKey,
										nil]];

	[part setVisible: [visibleSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(visible), WILDAffectedPropertyKey,
										nil]];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doEnabledSwitchToggled:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(isEnabled), WILDAffectedPropertyKey,
										nil]];

	[part setEnabled: [enabledSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(isEnabled), WILDAffectedPropertyKey,
										nil]];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doFillColorChanged:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(fillColor), WILDAffectedPropertyKey,
										nil]];

	[part setFillColor: [fillColorWell color]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(fillColor), WILDAffectedPropertyKey,
										nil]];
	[part updateChangeCount: NSChangeDone];
}

-(IBAction)	doLineColorChanged:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(lineColor), WILDAffectedPropertyKey,
										nil]];

	[part setLineColor: [lineColorWell color]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(lineColor), WILDAffectedPropertyKey,
										nil]];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doShadowColorChanged:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(shadowColor), WILDAffectedPropertyKey,
										nil]];

	[part setShadowColor: [shadowColorWell color]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(shadowColor), WILDAffectedPropertyKey,
										nil]];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doShadowOffsetChanged:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(shadowOffset), WILDAffectedPropertyKey,
										nil]];

	[part setShadowOffset: NSMakeSize([shadowOffsetSlider doubleValue],[shadowOffsetSlider doubleValue])];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(shadowOffset), WILDAffectedPropertyKey,
										nil]];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doShadowBlurRadiusChanged:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(shadowBlurRadius), WILDAffectedPropertyKey,
										nil]];

	[part setShadowBlurRadius: [shadowBlurRadiusSlider doubleValue]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(shadowBlurRadius), WILDAffectedPropertyKey,
										nil]];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doLineWidthChanged:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(lineWidth), WILDAffectedPropertyKey,
										nil]];

	[part setLineWidth: [lineWidthSlider doubleValue]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(lineWidth), WILDAffectedPropertyKey,
										nil]];
	[part updateChangeCount: NSChangeDone];
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == nameField )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(name), WILDAffectedPropertyKey,
										nil]];

		[part setName: [nameField stringValue]];
			
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(name), WILDAffectedPropertyKey,
										nil]];
		[part updateChangeCount: NSChangeDone];
	}
}

@end
