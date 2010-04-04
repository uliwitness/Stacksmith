//
//  UKPropagandaButtonInfoWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 03.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaButtonInfoWindowController.h"
#import "UKPropagandaPart.h"
#import "UKPropagandaPartContents.h"
#import "UKPropagandaCard.h"
#import "UKPropagandaStack.h"
#import "UKPropagandaWindowBodyView.h"
#import <Quartz/Quartz.h>


@interface UKPropagandaSimpleImageBrowserItem : NSObject // IKImageBrowserItem
{
	NSImage*		mImage;
}

@property (retain) NSImage*	image;

-(id)	initWithNSImage: (NSImage*)theImg;

@end


@implementation UKPropagandaSimpleImageBrowserItem

@synthesize image = mImage;

-(id)	initWithNSImage: (NSImage*)theImg
{
	if(( self = [super init] ))
	{
		mImage = [theImg retain];
	}
	
	return self;
}


-(void)	dealloc
{
	[mImage release];
	mImage = nil;
	
	[super dealloc];
}


-(NSString *)  imageUID
{
	return [NSString stringWithFormat: @"%p", mImage];	// +++ Should really be icon ID for correct animations after icon editing.
}

-(NSString *) imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;
}

-(id) imageRepresentation
{
	return mImage;
}

-(NSString *) imageTitle
{
	return [mImage name];
}

@end


@implementation UKPropagandaButtonInfoWindowController

-(id)	initWithPart: (UKPropagandaPart*)inPart ofCardView: (UKPropagandaWindowBodyView*)owningView
{
	if(( self = [super initWithWindowNibName: NSStringFromClass([self class])] ))
	{
		mPart = inPart;
		mCardView = owningView;
		
		[self setShouldCascadeWindows: NO];
	}
	
	return self;
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	[mNameField setStringValue: [mPart name]];
	
	NSString*	layerName = [[mPart partLayer] capitalizedString];
	[mButtonNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Button Number:", layerName]];
	[mButtonNumberField setIntegerValue: [mPart partNumberAmongPartsOfType: @"button"] +1];
	[mPartNumberLabel setStringValue: [NSString stringWithFormat: @"%@ Part Number:", layerName]];
	[mPartNumberField setIntegerValue: [mPart partNumber] +1];
	[mIDLabel setStringValue: [NSString stringWithFormat: @"%@ Button ID:", layerName]];
	[mIDField setIntegerValue: [mPart partID]];
	
	[mShowNameSwitch setState: [mPart showName]];
	[mAutoHighlightSwitch setState: [mPart autoHighlight]];
	[mEnabledSwitch setState: [mPart isEnabled]];
	
	NSArray*	stylesInMenuOrder = [NSArray arrayWithObjects:
													@"transparent",
													@"opaque",
													@"rectangle",
													@"roundrect",
													@"shadow",
													@"checkbox",
													@"radiobutton",
													@"standard",
													@"default",
													@"oval",
													@"popup",
													nil];
	
	[mStylePopUp selectItemAtIndex: [stylesInMenuOrder indexOfObject: [mPart style]]];
	[mFamilyPopUp selectItemAtIndex: [mPart family]];
	
	UKPropagandaPartContents*	theContents = nil;
	if( [mPart sharedText] )
		theContents = [[[mCardView card] owningBackground] contentsForPart: mPart];
	else
		theContents = [[mCardView card] contentsForPart: mPart];
	NSString*					contentsStr = [theContents text];
	[mContentsTextField setString: contentsStr ? contentsStr : @""];
	
	[mIconListView reloadData];
}


-(IBAction)	showWindow: (id)sender
{
	NSWindow*	theWindow = [self window];
	NSRect		buttonRect = [mPart rectangle];
	buttonRect = [mCardView convertRectToBase: buttonRect];
	buttonRect.origin = [[mCardView window] convertBaseToScreen: buttonRect.origin];
	NSRect		desiredFrame = [theWindow contentRectForFrameRect: [theWindow frame]];
	[theWindow setFrame: buttonRect display: NO];
	[theWindow makeKeyAndOrderFront: self];
	desiredFrame = [theWindow frameRectForContentRect: desiredFrame];
	[theWindow setFrame: desiredFrame display: YES animate: YES];
}


-(IBAction)	doOKButton: (id)sender
{
	[self close];
}


-(IBAction)	doCancelButton: (id)sender
{
	[self close];
}


-(NSUInteger) numberOfItemsInImageBrowser: (IKImageBrowserView *)aBrowser
{
	return [[mPart stack] numberOfPictures];
}


-(id /*IKImageBrowserItem*/) imageBrowser: (IKImageBrowserView *) aBrowser itemAtIndex: (NSUInteger)idx
{
	NSImage*	img = [[mPart stack] pictureAtIndex: idx];
	
	return [[[UKPropagandaSimpleImageBrowserItem alloc] initWithNSImage: img] autorelease];
}

@end
