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
#import "WILDUserPropertyEditorController.h"
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
@synthesize userPropertyEditor;


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
	DESTROY(shadowBlurRadiusSlider);
	DESTROY(shadowOffsetSlider);
	DESTROY(contentsEditorButton);
	DESTROY(lineWidthSlider);
	DESTROY(userPropertyEditor);
	
	[super dealloc];
}


-(void)	loadView
{
	[super loadView];
	
	[self.userPropertyEditor setPropertyContainer: part];
	
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
	part->OpenScriptEditorAndShowLine( SIZE_T_MAX );
}


-(IBAction)	doContentsEditorButton: (id)sender
{
	part->OpenContentsEditor();
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
