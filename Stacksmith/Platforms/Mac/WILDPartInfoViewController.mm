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
#import "CVisiblePart.h"
#import "CLayer.h"
#import "UKHelperMacros.h"


using namespace Carlson;


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


-(id)	initWithPart: (CPart*)inPart
{
    self = [super initWithNibName: NSStringFromClass([self class]) bundle: [NSBundle bundleForClass: [self class]]];
    if( self )
	{
        part = inPart;
    }
    
    return self;
}


-(void)	dealloc
{
	part = NULL;
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
	
	[nameField setStringValue: [NSString stringWithUTF8String: part->GetName().c_str()]];
	
	CLayer*		parent = dynamic_cast<CLayer*>(part->GetParentObject());
	NSString*	layerName = [[NSString stringWithUTF8String: parent->GetIdentityForDump()] capitalizedString];
	[numberField setIntegerValue: parent->GetIndexOfPart( part, part->GetPartType() ) +1];
	[partNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Part Number:", layerName]];
	[partNumberField setIntegerValue: parent->GetIndexOfPart( part, NULL ) +1];
	[idField setIntegerValue: part->GetID()];
	
	CVisiblePart*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
	{
		[enabledSwitch setState: visPart->GetEnabled()];
		[visibleSwitch setState: visPart->GetVisible()];
		
		[fillColorWell setColor: [NSColor colorWithCalibratedRed: visPart->GetFillColorRed() green: visPart->GetFillColorGreen() blue: visPart->GetFillColorBlue() alpha: visPart->GetFillColorAlpha()]];
		[lineColorWell setColor: [NSColor colorWithCalibratedRed: visPart->GetLineColorRed() green: visPart->GetLineColorGreen() blue: visPart->GetLineColorBlue() alpha: visPart->GetLineColorAlpha()]];
		[shadowColorWell setColor: [NSColor colorWithCalibratedRed: visPart->GetShadowColorRed() green: visPart->GetShadowColorGreen() blue: visPart->GetShadowColorBlue() alpha: visPart->GetShadowColorAlpha()]];
		[shadowBlurRadiusSlider setDoubleValue: visPart->GetShadowBlurRadius()];
		[shadowOffsetSlider setDoubleValue: visPart->GetShadowOffsetWidth()];
		[lineWidthSlider setDoubleValue: visPart->GetLineWidth()];
	}
	else
	{
		[enabledSwitch setEnabled: NO];
		[visibleSwitch setEnabled: NO];
		[fillColorWell setEnabled: NO];
		[lineColorWell setEnabled: NO];
		[shadowColorWell setEnabled: NO];
		[shadowBlurRadiusSlider setEnabled: NO];
		[shadowOffsetSlider setEnabled: NO];
		[lineWidthSlider setEnabled: NO];
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


-(IBAction)	doContentsEditorButton: (id)sender
{
	NSRect		box = [contentsEditorButton convertRect: [contentsEditorButton bounds] toView: nil];
	NSRect		wFrame = [[[self view] window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDContentsEditorWindowController*	se = [[[WILDContentsEditorWindowController alloc] initWithPart: part] autorelease];
	[se setGlobalStartRect: box];
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
	[[[[[[self view] window] parentWindow] windowController] document] addWindowController: se];
	[se showWindow: self];
}


-(IBAction)	doVisibleSwitchToggled:(id)sender
{
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetVisible( [visibleSwitch state] == NSOnState );
}


-(IBAction)	doEnabledSwitchToggled:(id)sender
{
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetEnabled( [enabledSwitch state] == NSOnState );
}


-(IBAction)	doFillColorChanged:(id)sender
{
	NSColor			*	fillColor = [fillColorWell.color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetFillColor( fillColor.redComponent, fillColor.greenComponent, fillColor.blueComponent, fillColor.alphaComponent );
}

-(IBAction)	doLineColorChanged:(id)sender
{
	NSColor			*	fillColor = [lineColorWell.color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetLineColor( fillColor.redComponent, fillColor.greenComponent, fillColor.blueComponent, fillColor.alphaComponent );
}


-(IBAction)	doShadowColorChanged:(id)sender
{
	NSColor			*	fillColor = [shadowColorWell.color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetShadowColor( fillColor.redComponent, fillColor.greenComponent, fillColor.blueComponent, fillColor.alphaComponent );
}


-(IBAction)	doShadowOffsetChanged:(id)sender
{
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetShadowOffset( [shadowOffsetSlider doubleValue], [shadowOffsetSlider doubleValue] );
}


-(IBAction)	doShadowBlurRadiusChanged:(id)sender
{
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetShadowBlurRadius( [shadowBlurRadiusSlider doubleValue] );
}


-(IBAction)	doLineWidthChanged:(id)sender
{
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetLineWidth( [lineWidthSlider intValue] );
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == nameField )
		part->SetName( std::string( nameField.stringValue.UTF8String, [nameField.stringValue lengthOfBytesUsingEncoding: NSUTF8StringEncoding] ) );
}

@end
