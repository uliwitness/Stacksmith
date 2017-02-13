//
//  WILDPartInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDConcreteObjectInfoViewController.h"


namespace Carlson
{
	class CPart;
}


@interface WILDPartInfoViewController : WILDConcreteObjectInfoViewController
{
	Carlson::CPart	*		part;				// The card/bg part we're editing.
	NSButton		*		enabledSwitch;
	NSButton		*		visibleSwitch;
	NSTextField		*		numberField;
	NSTextField		*		partNumberField;
	NSTextField		*		partNumberLabel;
	NSColorWell		*		fillColorWell;
	NSColorWell		*		lineColorWell;
	NSColorWell		*		shadowColorWell;
	NSSlider		*		shadowBlurRadiusSlider;
	NSSlider		*		shadowOffsetSlider;
	NSButton		*		contentsEditorButton;
	NSSlider		*		lineWidthSlider;
}

@property(retain)	IBOutlet NSButton			*		enabledSwitch;
@property(retain)	IBOutlet NSButton			*		visibleSwitch;
@property(retain)	IBOutlet NSTextField		*		numberField;
@property(retain)	IBOutlet NSTextField		*		partNumberField;
@property(retain)	IBOutlet NSTextField		*		partNumberLabel;
@property(retain)	IBOutlet NSColorWell		*		fillColorWell;
@property(retain)	IBOutlet NSColorWell		*		lineColorWell;
@property(retain)	IBOutlet NSColorWell		*		shadowColorWell;
@property(retain)	IBOutlet NSSlider			*		shadowBlurRadiusSlider;
@property(retain)	IBOutlet NSSlider			*		shadowOffsetSlider;
@property(retain)	IBOutlet NSButton			*		contentsEditorButton;
@property(retain)	IBOutlet NSSlider			*		lineWidthSlider;
@property(retain)	IBOutlet NSTextField		*		toolTipField;
@property(assign)	IBOutlet NSPopUpButton		*		horizontalPinningPopUp;
@property(assign)	IBOutlet NSPopUpButton		*		verticalPinningPopUp;
@property(assign)	IBOutlet NSTextField		*		leftCoordinateField;
@property(assign)	IBOutlet NSTextField		*		rightCoordinateField;
@property(assign)	IBOutlet NSTextField		*		bottomCoordinateField;
@property(assign)	IBOutlet NSTextField		*		topCoordinateField;

-(id)		initWithPart: (Carlson::CPart*)inPart;

-(IBAction) doEnabledSwitchToggled:(id)sender;
-(IBAction) doVisibleSwitchToggled:(id)sender;
-(IBAction)	doContentsEditorButton: (id)sender;

-(IBAction)	doShadowBlurRadiusChanged:(id)sender;
-(IBAction)	doShadowOffsetChanged:(id)sender;
-(IBAction)	doShadowColorChanged:(id)sender;
-(IBAction)	doLineColorChanged:(id)sender;
-(IBAction)	doFillColorChanged:(id)sender;
-(IBAction)	doLineWidthChanged:(id)sender;

@end
