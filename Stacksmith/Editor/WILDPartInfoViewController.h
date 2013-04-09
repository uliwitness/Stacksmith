//
//  WILDPartInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WILDPart;
@class WILDCardView;


@interface WILDPartInfoViewController : NSViewController
{
	WILDPart*				part;				// The card/bg part we're editing.
	WILDCardView*			cardView;			// BG parts can have different values/contents on each card, so we need to know which one. NOT RETAINED, IT'S OUR OWNER.
	NSButton		*		scriptEditorButton;
	NSTextField		*		nameField;
	NSButton		*		enabledSwitch;
	NSButton		*		visibleSwitch;
	NSTextField		*		numberField;
	NSTextField		*		idField;
	NSTextField		*		partNumberField;
	NSTextField		*		partNumberLabel;
	NSTextView		*		contentsTextField;
	NSColorWell		*		fillColorWell;
	NSColorWell		*		lineColorWell;
	NSColorWell		*		shadowColorWell;
	NSSlider		*		shadowBlurRadiusSlider;
	NSSlider		*		shadowOffsetSlider;
	NSButton		*		contentsEditorButton;
	NSSlider		*		lineWidthSlider;
}

@property(retain)	IBOutlet NSButton			*		scriptEditorButton;
@property(retain)	IBOutlet NSTextField		*		nameField;
@property(retain)	IBOutlet NSButton			*		enabledSwitch;
@property(retain)	IBOutlet NSButton			*		visibleSwitch;
@property(retain)	IBOutlet NSTextField		*		numberField;
@property(retain)	IBOutlet NSTextField		*		idField;
@property(retain)	IBOutlet NSTextField		*		partNumberField;
@property(retain)	IBOutlet NSTextField		*		partNumberLabel;
@property(retain)	IBOutlet NSTextView			*		contentsTextField;
@property(retain)	IBOutlet NSColorWell		*		fillColorWell;
@property(retain)	IBOutlet NSColorWell		*		lineColorWell;
@property(retain)	IBOutlet NSColorWell		*		shadowColorWell;
@property(retain)	IBOutlet NSSlider			*		shadowBlurRadiusSlider;
@property(retain)	IBOutlet NSSlider			*		shadowOffsetSlider;
@property(retain)	IBOutlet NSButton			*		contentsEditorButton;
@property(retain)	IBOutlet NSSlider			*		lineWidthSlider;

-(id)		initWithPart: (WILDPart*)inPart ofCardView: (WILDCardView*)owningView;

-(IBAction)	doScriptEditorButton: (id)sender;
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
