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

@synthesize enabledSwitch;
@synthesize visibleSwitch;
@synthesize numberField;
@synthesize partNumberField;
@synthesize partNumberLabel;
@synthesize fillColorWell;
@synthesize lineColorWell;
@synthesize shadowColorWell;
@synthesize shadowBlurRadiusSlider;
@synthesize shadowOffsetSlider;
@synthesize contentsEditorButton;
@synthesize lineWidthSlider;
@synthesize toolTipField;
@synthesize horizontalPinningPopUp;
@synthesize verticalPinningPopUp;
@synthesize leftCoordinateField;
@synthesize rightCoordinateField;
@synthesize bottomCoordinateField;
@synthesize topCoordinateField;


-(id)	initWithPart: (CPart*)inPart
{
    self = [super initWithConcreteObject: inPart];
    if( self )
	{
        part = inPart;
    }
    
    return self;
}


-(void)	dealloc
{
	part = NULL;
	DESTROY(enabledSwitch);
	DESTROY(visibleSwitch);
	DESTROY(numberField);
	DESTROY(partNumberField);
	DESTROY(partNumberLabel);
	DESTROY(fillColorWell);
	DESTROY(lineColorWell);
	DESTROY(shadowColorWell);
	DESTROY(shadowBlurRadiusSlider);
	DESTROY(shadowOffsetSlider);
	DESTROY(contentsEditorButton);
	DESTROY(lineWidthSlider);
	DESTROY(toolTipField);
	
	[super dealloc];
}


-(void)	loadView
{
	[super loadView];
	
	[self.userPropertyEditor setPropertyContainer: part];
	
	CLayer*		parent = dynamic_cast<CLayer*>(part->GetParentObject( nullptr, nullptr ));
	NSString*	layerName = [[NSString stringWithUTF8String: parent->GetIdentityForDump()] capitalizedString];
	[numberField setIntegerValue: parent->GetIndexOfPart( part, part->GetPartType() ) +1];
	[partNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Part Number:", layerName]];
	[partNumberField setIntegerValue: parent->GetIndexOfPart( part, NULL ) +1];
	
	CVisiblePart*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
	{
		[enabledSwitch setState: visPart->GetEnabled()];
		[visibleSwitch setState: visPart->GetVisible()];
		
		[fillColorWell setColor: [NSColor colorWithCalibratedRed: visPart->GetFillColorRed() / 65535.0 green: visPart->GetFillColorGreen() / 65535.0 blue: visPart->GetFillColorBlue() / 65535.0 alpha: visPart->GetFillColorAlpha() / 65535.0]];
		[lineColorWell setColor: [NSColor colorWithCalibratedRed: visPart->GetLineColorRed() / 65535.0 green: visPart->GetLineColorGreen() / 65535.0 blue: visPart->GetLineColorBlue() / 65535.0 alpha: visPart->GetLineColorAlpha() / 65535.0]];
		[shadowColorWell setColor: [NSColor colorWithCalibratedRed: visPart->GetShadowColorRed() / 65535.0 green: visPart->GetShadowColorGreen() / 65535.0 blue: visPart->GetShadowColorBlue() / 65535.0 alpha: visPart->GetShadowColorAlpha() / 65535.0]];
		[shadowBlurRadiusSlider setDoubleValue: visPart->GetShadowBlurRadius()];
		[shadowOffsetSlider setDoubleValue: visPart->GetShadowOffsetWidth()];
		[lineWidthSlider setDoubleValue: visPart->GetLineWidth()];
		[toolTipField setStringValue: [NSString stringWithUTF8String: visPart->GetToolTip().c_str()]];
		NSInteger	popupIndex = 0;
		switch( PART_H_LAYOUT_MODE(visPart->GetPartLayoutFlags()) )
		{
			case EPartLayoutAlignLeft:
				popupIndex = 0;
				break;
			case EPartLayoutAlignHCenter:
				popupIndex = 1;
				break;
			case EPartLayoutAlignHBoth:
				popupIndex = 2;
				break;
			case EPartLayoutAlignRight:
				popupIndex = 3;
				break;
		}
		[horizontalPinningPopUp selectItemAtIndex: popupIndex];
		switch( PART_V_LAYOUT_MODE(visPart->GetPartLayoutFlags()) )
		{
			case EPartLayoutAlignTop:
				popupIndex = 0;
				break;
			case EPartLayoutAlignVCenter:
				popupIndex = 1;
				break;
			case EPartLayoutAlignVBoth:
				popupIndex = 2;
				break;
			case EPartLayoutAlignBottom:
				popupIndex = 3;
				break;
		}
		[verticalPinningPopUp selectItemAtIndex: popupIndex];
		[leftCoordinateField setIntegerValue: visPart->GetLeft()];
		[rightCoordinateField setIntegerValue: visPart->GetRight()];
		[bottomCoordinateField setIntegerValue: visPart->GetBottom()];
		[topCoordinateField setIntegerValue: visPart->GetTop()];
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
		[toolTipField setEnabled: NO];
		[horizontalPinningPopUp setEnabled: NO];
		[verticalPinningPopUp setEnabled: NO];
		[leftCoordinateField setEnabled: NO];
		[rightCoordinateField setEnabled: NO];
		[bottomCoordinateField setEnabled: NO];
		[topCoordinateField setEnabled: NO];
	}
}


-(IBAction)	doContentsEditorButton: (id)sender
{
	part->OpenContentsEditor();
}


-(IBAction)	doVisibleSwitchToggled:(id)sender
{
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetVisible( [visibleSwitch state] == NSControlStateValueOn );
}


-(IBAction)	doEnabledSwitchToggled:(id)sender
{
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetEnabled( [enabledSwitch state] == NSControlStateValueOn );
}


-(IBAction)	doFillColorChanged:(id)sender
{
	NSColor			*	fillColor = [fillColorWell.color colorUsingColorSpace: NSColorSpace.genericRGBColorSpace];
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetFillColor( fillColor.redComponent * 65535.0, fillColor.greenComponent * 65535.0, fillColor.blueComponent * 65535.0, fillColor.alphaComponent * 65535.0 );
}

-(IBAction)	doLineColorChanged:(id)sender
{
	NSColor			*	fillColor = [lineColorWell.color colorUsingColorSpace: NSColorSpace.genericRGBColorSpace];
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetLineColor( fillColor.redComponent * 65535.0, fillColor.greenComponent * 65535.0, fillColor.blueComponent * 65535.0, fillColor.alphaComponent * 65535.0 );
}


-(IBAction)	doShadowColorChanged:(id)sender
{
	NSColor			*	fillColor = [shadowColorWell.color colorUsingColorSpace: NSColorSpace.genericRGBColorSpace];
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
		visPart->SetShadowColor( fillColor.redComponent * 65535.0, fillColor.greenComponent * 65535.0, fillColor.blueComponent * 65535.0, fillColor.alphaComponent * 65535.0 );
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


-(IBAction)	doPinningChanged:(id)sender
{
	CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
	if( visPart )
	{
		TPartLayoutFlags layoutFlags = 0;
		switch( horizontalPinningPopUp.indexOfSelectedItem )
		{
			case 0:
				layoutFlags |= EPartLayoutAlignLeft;
				break;
			case 1:
				layoutFlags |= EPartLayoutAlignHCenter;
				break;
			case 2:
				layoutFlags |= EPartLayoutAlignHBoth;
				break;
			case 3:
				layoutFlags |= EPartLayoutAlignRight;
				break;
		}
		switch( verticalPinningPopUp.indexOfSelectedItem )
		{
			case 0:
				layoutFlags |= EPartLayoutAlignTop;
				break;
			case 1:
				layoutFlags |= EPartLayoutAlignVCenter;
				break;
			case 2:
				layoutFlags |= EPartLayoutAlignVBoth;
				break;
			case 3:
				layoutFlags |= EPartLayoutAlignBottom;
				break;
		}
		visPart->SetPartLayoutFlags(layoutFlags);
	}
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == toolTipField )
	{
		CVisiblePart*	visPart = dynamic_cast<CVisiblePart*>(part);
		if( visPart )
		{
			visPart->SetToolTip( std::string( toolTipField.stringValue.UTF8String, [toolTipField.stringValue lengthOfBytesUsingEncoding: NSUTF8StringEncoding] ) );
		}
	}
	else if( [notif object] == leftCoordinateField || [notif object] == topCoordinateField
			|| [notif object] == rightCoordinateField || [notif object] == bottomCoordinateField )
	{
		CVisiblePart	*	visPart = dynamic_cast<CVisiblePart*>(part);
		if( visPart )
		{
			visPart->SetRect( leftCoordinateField.integerValue, topCoordinateField.integerValue, rightCoordinateField.integerValue, bottomCoordinateField.integerValue );
		}
	}
	else
	{
		[super controlTextDidChange: notif];
	}
}

@end
