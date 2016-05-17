//
//  WILDInspectorWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 15/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#import "WILDInspectorWindowController.h"
#import <QuartzCore/QuartzCore.h>
#include "CInspectorRow.h"


@interface WILDGradientView : NSView

@end


@interface WILDGradientView ()

@property (retain) CAGradientLayer*	gradientLayer;

@end


@implementation WILDGradientView

-(id)	initWithFrame: (NSRect)inBox
{
	self = [super initWithFrame: inBox];
	if( self )
	{
		self.wantsLayer = YES;
		self.gradientLayer = [CAGradientLayer layer];
		self.gradientLayer.backgroundColor = [NSColor redColor].CGColor;
		self.gradientLayer.colors = @[ (id)[NSColor windowBackgroundColor].CGColor, (id)[NSColor whiteColor].CGColor ];
		self.gradientLayer.startPoint = NSMakePoint(0,0.5);
		self.gradientLayer.endPoint = NSMakePoint(1.0,0.5);
		self.layer = self.gradientLayer;
	}
	return self;
}


-(id)	initWithCoder: (NSCoder*)unarchiver
{
	self = [super initWithCoder: unarchiver];
	if( self )
	{
		self.wantsLayer = YES;
		self.gradientLayer = [CAGradientLayer layer];
		self.gradientLayer.backgroundColor = [NSColor redColor].CGColor;
		self.gradientLayer.colors = @[ (id)[NSColor windowBackgroundColor].CGColor, (id)[NSColor whiteColor].CGColor ];
		self.gradientLayer.startPoint = NSMakePoint(0,0.5);
		self.gradientLayer.endPoint = NSMakePoint(1.0,0.5);
		self.layer = self.gradientLayer;
	}
	return self;
}


-(void)	dealloc
{
	self.layer = nil;
	
	[super dealloc];
}

@end


@interface WILDInspectorWindowController ()

@property (assign) IBOutlet NSView *propertyListView;

@end

@implementation WILDInspectorWindowController

static WILDInspectorWindowController*	sSharedInspectorWindowController = nil;

+(WILDInspectorWindowController*)	sharedInspectorWindowController
{
	if( !sSharedInspectorWindowController )
	{
		sSharedInspectorWindowController = [[[self class] alloc] initWithWindow: nil];
	}
	return sSharedInspectorWindowController;
}


-(id)	init
{
	if( sSharedInspectorWindowController )
	{
		[self release];
		return [sSharedInspectorWindowController retain];
	}
	
	self = [super initWithWindow: nil];
	if( self )
	{
		
	}
	
	return self;
}


-(void)	dealloc
{
	self.propertyListView = nil;
	
	[super dealloc];
}


-(NSString*)	windowNibName
{
	return @"WILDInspectorWindowController";
}


-(NSTextField*)	addLabelViewForRow: (const CInspectorRow&)currRow inView: (NSView*)container withPrevRow: (NSView**)prevRow prevLabel: (NSView**)prevLabel fillRow: (BOOL)inFillRow
{
	NSArray*		constraints = nil;
	NSTextField*	label = [[[NSTextField alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
	label.translatesAutoresizingMaskIntoConstraints = NO;
	label.bordered = NO;
	label.editable = NO;
	label.drawsBackground = NO;
	label.alignment = NSRightTextAlignment;
	label.stringValue = [NSString stringWithUTF8String: currRow.mLabel.c_str()];
	[container addSubview: label];
	if( inFillRow )
	{
		constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"|-16-[label]-(>=8)-|" options: 0 metrics: nil views: @{ @"label": label }];
		[container addConstraints: constraints];
		constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[label]-8-|" options: 0 metrics: nil views: @{ @"label": label }];
		[container addConstraints: constraints];
	}
	else
	{
		if( *prevLabel )
		{
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"|-12-[label(==prevLabel)]" options: 0 metrics: nil views: @{ @"label": label, @"prevLabel": *prevLabel }];
		}
		else
		{
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"|-12-[label]" options: 0 metrics: nil views: @{ @"label": label }];
		}
		[container addConstraints: constraints];
//		if( *prevRow )
//		{
//			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[label]" options: 0 metrics: nil views: @{ @"label": label, @"prevRow": *prevRow }];
//		}
//		else
//		{
//			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[label]" options: 0 metrics: nil views: @{ @"label": label }];
//		}
//		[container addConstraints: constraints];
	}
	
	return label;
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	self.propertyListView.subviews = @[];
	
	CInspectorRow	rows[] =
	{
		{ EInspectorRowTypeSeparator, "Properties", "", {}, "" },
		{ EInspectorRowTypeEditField, "Name:", "Name you can use to reference this part from scripts.", {}, "name" },
		{ EInspectorRowTypeThreeLabelColumns, "", "", { "ID", "2000", "Number", "2", "Part Number", "5" }, "shadowAngle" },
		{ EInspectorRowTypeLabel, "Part Number:", "Number of the position at which this part is, from back to front.", {}, "partNumber" },
		{ EInspectorRowTypeCheckbox, "Auto Highlight", "Should the button highlight when clicked.", {}, "autoHighlight" },
		{ EInspectorRowTypeButton, "Script…", "Edit the behaviours associated with this part.", {}, "script" },
		{ EInspectorRowTypePopup, "Style:", "Appearance and behaviour of this part.", { "foo", "bar" }, "style" },
		{ EInspectorRowTypeColorPicker, "Line Color:", "Color for the outline for this part.", {}, "lineColor" },
		{ EInspectorRowTypeAngleDial, "Shadow Angle:", "Angle at which the shadow falls.", {}, "shadowAngle" },
		
		{ EInspectorRowType_Invalid, "", "", {}, "" }
	};
	
	NSView*		prevRow = nil;
	NSView*		prevLabel = nil;
	NSArray*	constraints = nil;
	
	for( size_t x = 0; rows[x].mType != EInspectorRowType_Invalid; x++ )
	{
		const CInspectorRow& currRow = rows[x];
		
		// Label field:
		NSTextField*	label = nil;
		
		// Actual data field:
		if( currRow.mType == EInspectorRowTypeLabel )
		{
			label = [self addLabelViewForRow: currRow inView: self.propertyListView withPrevRow: &prevRow prevLabel: &prevLabel fillRow: NO];
			
			NSTextField*	value = [[[NSTextField alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			value.translatesAutoresizingMaskIntoConstraints = NO;
			value.bordered = NO;
			value.editable = NO;
			value.selectable = YES;
			value.drawsBackground = NO;
			value.stringValue = @"2000";
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: value];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]-(>=8)-|" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			[self.propertyListView addConstraints: constraints];
			if( prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value, @"prevRow": prevRow }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			}
			[self.propertyListView addConstraints: constraints];
			prevRow = value;
		}
		else if( currRow.mType == EInspectorRowTypeEditField )
		{
			label = [self addLabelViewForRow: currRow inView: self.propertyListView withPrevRow: &prevRow prevLabel: &prevLabel fillRow: NO];
			
			NSTextField*	value = [[[NSTextField alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 22)] autorelease];
			value.translatesAutoresizingMaskIntoConstraints = NO;
			value.bezeled = YES;
			value.editable = YES;
			value.selectable = YES;
			value.stringValue = @"Foo";
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: value];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]-8-|" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			[self.propertyListView addConstraints: constraints];
			if( prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value, @"prevRow": prevRow }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			}
			[self.propertyListView addConstraints: constraints];
			prevRow = value;
		}
		else if( currRow.mType == EInspectorRowTypeCheckbox )
		{
			NSButton*	value = [[[NSButton alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			value.translatesAutoresizingMaskIntoConstraints = NO;
			value.buttonType = NSSwitchButton;
			value.title = [NSString stringWithUTF8String: currRow.mLabel.c_str()];
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: value];
			if( label )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]-(>=8)-|" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			}
			else if( prevLabel )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]-(>=8)-|" options: 0 metrics: nil views: @{ @"label": prevLabel, @"value": value }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"|-(>=8)-[value]-(>=8)-|" options: 0 metrics: nil views: @{ @"value": value }];
			}
			[self.propertyListView addConstraints: constraints];
			if( prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[value]" options: 0 metrics: nil views: @{ @"value": value, @"prevRow": prevRow }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[value]" options: 0 metrics: nil views: @{ @"value": value }];
			}
			[self.propertyListView addConstraints: constraints];
			prevRow = value;
		}
		else if( currRow.mType == EInspectorRowTypeButton )
		{
			NSButton*	value = [[[NSButton alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			value.translatesAutoresizingMaskIntoConstraints = NO;
			value.title = [NSString stringWithUTF8String: currRow.mLabel.c_str()];
			value.bezelStyle = NSRoundedBezelStyle;
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: value];
			if( label )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]-(>=8)-|" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			}
			else if( prevLabel )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]-(>=8)-|" options: 0 metrics: nil views: @{ @"label": prevLabel, @"value": value }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"|-(>=8)-[value]-(>=8)-|" options: 0 metrics: nil views: @{ @"value": value }];
			}
			[self.propertyListView addConstraints: constraints];
			if( prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[value]" options: 0 metrics: nil views: @{ @"value": value, @"prevRow": prevRow }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			}
			[self.propertyListView addConstraints: constraints];
			prevRow = value;
		}
		else if( currRow.mType == EInspectorRowTypePopup )
		{
			label = [self addLabelViewForRow: currRow inView: self.propertyListView withPrevRow: &prevRow prevLabel: &prevLabel fillRow: NO];
			
			NSPopUpButton*	value = [[[NSPopUpButton alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			value.translatesAutoresizingMaskIntoConstraints = NO;
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			for( const std::string& currItem : currRow.mPopupChoices )
			{
				[value addItemWithTitle: [NSString stringWithUTF8String: currItem.c_str()]];
			}
			[self.propertyListView addSubview: value];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]-(>=8)-|" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			[self.propertyListView addConstraints: constraints];
			if( prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value, @"prevRow": prevRow }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			}
			[self.propertyListView addConstraints: constraints];
			prevRow = value;
		}
		else if( currRow.mType == EInspectorRowTypeColorPicker )
		{
			label = [self addLabelViewForRow: currRow inView: self.propertyListView withPrevRow: &prevRow prevLabel: &prevLabel fillRow: NO];
			
			NSColorWell*	value = [[[NSColorWell alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			value.translatesAutoresizingMaskIntoConstraints = NO;
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: value];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value(60)]-(>=8)-|" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			[self.propertyListView addConstraints: constraints];
			if( prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[value(24)]" options: 0 metrics: nil views: @{ @"label": label, @"value": value, @"prevRow": prevRow }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			}
			[self.propertyListView addConstraints: constraints];
			prevRow = value;
		}
		else if( currRow.mType == EInspectorRowTypeAngleDial )
		{
			label = [self addLabelViewForRow: currRow inView: self.propertyListView withPrevRow: &prevRow prevLabel: &prevLabel fillRow: NO];
			
			NSSlider*	value = [[[NSSlider alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			value.sliderType = NSCircularSlider;
			value.translatesAutoresizingMaskIntoConstraints = NO;
//			value.controlSize = NSSmallControlSize;
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: value];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]-(>=8)-|" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			[self.propertyListView addConstraints: constraints];
			if( prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value, @"prevRow": prevRow }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[value]" options: 0 metrics: nil views: @{ @"label": label, @"value": value }];
			}
			[self.propertyListView addConstraints: constraints];
			prevRow = value;
		}
		else if( currRow.mType == EInspectorRowTypeSeparator )
		{
			WILDGradientView*	separator = [[[WILDGradientView alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			separator.translatesAutoresizingMaskIntoConstraints = NO;
			
			[self.propertyListView addSubview: separator];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"|-0-[separator]-0-|" options: 0 metrics: nil views: @{ @"separator": separator }];
			[self.propertyListView addConstraints: constraints];
			if( prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[separator]" options: 0 metrics: nil views: @{ @"prevRow": prevRow, @"separator": separator }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-0-[separator]" options: 0 metrics: nil views: @{ @"separator": separator }];
			}
			[self.propertyListView addConstraints: constraints];
			
			NSView	*pr = nil;
			NSView	*pl = nil;
			(void) [self addLabelViewForRow: currRow inView: separator withPrevRow: &pr prevLabel: &pl fillRow: YES];
			
			prevRow = separator;
		}
		else if( currRow.mType == EInspectorRowTypeThreeLabelColumns )
		{
			// Column one:
			NSBox*			separator = [[[NSBox alloc] initWithFrame: NSMakeRect(0,0,1, 16)] autorelease];
			separator.boxType = NSBoxSeparator;
			separator.translatesAutoresizingMaskIntoConstraints = NO;
			[self.propertyListView addSubview: separator];
		
			NSTextField*	labelAbove = [[[NSTextField alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			labelAbove.translatesAutoresizingMaskIntoConstraints = NO;
			labelAbove.font = [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]];
			labelAbove.bordered = NO;
			labelAbove.editable = NO;
			labelAbove.selectable = YES;
			labelAbove.drawsBackground = NO;
			labelAbove.stringValue = [NSString stringWithUTF8String: currRow.mPopupChoices[0].c_str()];
			labelAbove.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: labelAbove];

			NSTextField*	value = [[[NSTextField alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			value.translatesAutoresizingMaskIntoConstraints = NO;
			value.font = [NSFont systemFontOfSize: [NSFont smallSystemFontSize]];
			value.bordered = NO;
			value.editable = NO;
			value.selectable = YES;
			value.drawsBackground = NO;
			value.stringValue = [NSString stringWithUTF8String: currRow.mPopupChoices[1].c_str()];
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: value];
			
			if( prevLabel )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[prevLabel]-8-[labelAbove]-8-[separator]" options: 0 metrics: nil views: @{ @"prevLabel": prevLabel, @"labelAbove": labelAbove, @"separator": separator }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"|-(>=8)-[labelAbove]-(>=8)-[separator]" options: 0 metrics: nil views: @{ @"prevLabel": prevLabel, @"labelAbove": labelAbove, @"separator": separator }];
			}
			[self.propertyListView addConstraints: constraints];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[value]-(>=8)-[separator]" options: 0 metrics: nil views: @{ @"value": value, @"separator": separator }];
			[self.propertyListView addConstraints: constraints];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[labelAbove]-4-[value]" options: NSLayoutFormatAlignAllLeading metrics: nil views: @{ @"labelAbove": labelAbove, @"value": value }];
			[self.propertyListView addConstraints: constraints];
			if( prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-8-[labelAbove]" options: 0 metrics: nil views: @{ @"labelAbove": labelAbove, @"prevRow": prevRow }];
			}
			else
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-8-[labelAbove]" options: 0 metrics: nil views: @{ @"labelAbove": labelAbove }];
			}
			[self.propertyListView addConstraints: constraints];
			NSLayoutConstraint	*lc = [NSLayoutConstraint constraintWithItem: separator attribute: NSLayoutAttributeTop relatedBy: NSLayoutRelationEqual toItem: labelAbove attribute: NSLayoutAttributeTop multiplier: 1.0 constant: 0.0];
			[self.propertyListView addConstraint: lc];
			lc = [NSLayoutConstraint constraintWithItem: separator attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: value attribute: NSLayoutAttributeBottom multiplier: 1.0 constant: 0.0];
			[self.propertyListView addConstraint: lc];
			
			prevRow = value;
			
			// Column two:
			labelAbove = [[[NSTextField alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			labelAbove.translatesAutoresizingMaskIntoConstraints = NO;
			labelAbove.font = [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]];
			labelAbove.bordered = NO;
			labelAbove.editable = NO;
			labelAbove.selectable = YES;
			labelAbove.drawsBackground = NO;
			labelAbove.stringValue = [NSString stringWithUTF8String: currRow.mPopupChoices[2].c_str()];
			labelAbove.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: labelAbove];
			
			value = [[[NSTextField alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			value.translatesAutoresizingMaskIntoConstraints = NO;
			value.font = [NSFont systemFontOfSize: [NSFont smallSystemFontSize]];
			value.bordered = NO;
			value.editable = NO;
			value.selectable = YES;
			value.drawsBackground = NO;
			value.stringValue = [NSString stringWithUTF8String: currRow.mPopupChoices[3].c_str()];
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: value];
			
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[separator]-8-[labelAbove]" options: 0 metrics: nil views: @{ @"separator": separator, @"labelAbove": labelAbove }];
			[self.propertyListView addConstraints: constraints];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[labelAbove]-4-[value]" options: NSLayoutFormatAlignAllLeading metrics: nil views: @{ @"value": value, @"labelAbove": labelAbove }];
			[self.propertyListView addConstraints: constraints];

			lc = [NSLayoutConstraint constraintWithItem: separator attribute: NSLayoutAttributeTop relatedBy: NSLayoutRelationEqual toItem: labelAbove attribute: NSLayoutAttributeTop multiplier: 1.0 constant: 0.0];
			[self.propertyListView addConstraint: lc];

			separator = [[[NSBox alloc] initWithFrame: NSMakeRect(0,0,1, 16)] autorelease];
			separator.boxType = NSBoxSeparator;
			separator.translatesAutoresizingMaskIntoConstraints = NO;
			[self.propertyListView addSubview: separator];
		
			lc = [NSLayoutConstraint constraintWithItem: separator attribute: NSLayoutAttributeTop relatedBy: NSLayoutRelationEqual toItem: labelAbove attribute: NSLayoutAttributeTop multiplier: 1.0 constant: 0.0];
			[self.propertyListView addConstraint: lc];
			lc = [NSLayoutConstraint constraintWithItem: separator attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: value attribute: NSLayoutAttributeBottom multiplier: 1.0 constant: 0.0];
			[self.propertyListView addConstraint: lc];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[value]-(>=8)-[separator]" options: 0 metrics: nil views: @{ @"value": value, @"separator": separator }];
			[self.propertyListView addConstraints: constraints];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[labelAbove]-(>=8)-[separator]" options: 0 metrics: nil views: @{ @"labelAbove": labelAbove, @"separator": separator }];
			[self.propertyListView addConstraints: constraints];
			
			// Column three:
			labelAbove = [[[NSTextField alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			labelAbove.translatesAutoresizingMaskIntoConstraints = NO;
			labelAbove.font = [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]];
			labelAbove.bordered = NO;
			labelAbove.editable = NO;
			labelAbove.selectable = YES;
			labelAbove.drawsBackground = NO;
			labelAbove.stringValue = [NSString stringWithUTF8String: currRow.mPopupChoices[4].c_str()];
			labelAbove.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: labelAbove];
			
			value = [[[NSTextField alloc] initWithFrame: NSMakeRect(0,0,self.window.contentView.bounds.size.width, 16)] autorelease];
			value.translatesAutoresizingMaskIntoConstraints = NO;
			value.font = [NSFont systemFontOfSize: [NSFont smallSystemFontSize]];
			value.bordered = NO;
			value.editable = NO;
			value.selectable = YES;
			value.drawsBackground = NO;
			value.stringValue = [NSString stringWithUTF8String: currRow.mPopupChoices[5].c_str()];
			value.toolTip = [NSString stringWithUTF8String: currRow.mToolTip.c_str()];
			[self.propertyListView addSubview: value];
			
			lc = [NSLayoutConstraint constraintWithItem: separator attribute: NSLayoutAttributeTop relatedBy: NSLayoutRelationEqual toItem: labelAbove attribute: NSLayoutAttributeTop multiplier: 1.0 constant: 0.0];
			[self.propertyListView addConstraint: lc];

			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[separator]-8-[labelAbove]-(>=8)-|" options: 0 metrics: nil views: @{ @"separator": separator, @"labelAbove": labelAbove }];
			[self.propertyListView addConstraints: constraints];
			constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[labelAbove]-4-[value]-(>=8)-|" options: NSLayoutFormatAlignAllLeading metrics: nil views: @{ @"value": value, @"labelAbove": labelAbove }];
			[self.propertyListView addConstraints: constraints];
		}
		else if( label )
			prevRow = label;
		if( label )
		{
			if( label != prevRow && (currRow.mType == EInspectorRowTypeColorPicker || currRow.mType == EInspectorRowTypeAngleDial) )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]" options: NSLayoutFormatAlignAllCenterY metrics: nil views: @{ @"label": label, @"value": prevRow }];
				[self.propertyListView addConstraints: constraints];
			}
			else if( label != prevRow )
			{
				constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"[label]-8-[value]" options: NSLayoutFormatAlignAllBaseline metrics: nil views: @{ @"label": label, @"value": prevRow }];
				[self.propertyListView addConstraints: constraints];
			}
			prevLabel = label;
		}
	}
	
	if( prevRow )
	{
		constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[prevRow]-(>=16)-|" options: 0 metrics: nil views: @{ @"prevRow": prevRow }];
		[prevRow.superview addConstraints: constraints];
	}
}


-(IBAction)	makeKeyAndOrderFront: (id)sender
{
	[self.window makeKeyAndOrderFront: sender];
}

@end
