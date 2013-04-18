//
//  WILDUserPropertyEditorWindowController.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDUserPropertyEditorWindowController.h"
#import "WILDPart.h"
#import "WILDCardView.h"
#import "WILDNotifications.h"
#import "NSWindow+ULIZoomEffect.h"
#import "UKHelperMacros.h"
#import "WILDCard.h"
#import "WILDBackground.h"
#import "WILDBackground.h"
#import "WILDPartContents.h"


@implementation WILDUserPropertyEditorWindowController

-(id)	initWithPropertyContainer: (id<WILDObject,WILDScriptContainer>)inContainer
{
	if(( self = [super initWithWindowNibName: NSStringFromClass( [self class] )] ))
	{
		mContainer = inContainer;
	}
	
	return self;
}


-(void)	dealloc
{
	mContainer = nil;
	DESTROY(mCardView);
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	mUserProperties = [[mContainer allUserProperties] retain];
}


-(void)	showWindow:(id)sender
{
	NSWindow	*	theWindow = [self window];
	
	[theWindow makeKeyAndOrderFrontWithZoomEffectFromRect: mGlobalStartRect];
	[mTableView reloadData];
}


-(BOOL)	windowShouldClose: (id)sender
{
	NSWindow	*	theWindow = [self window];
	
	[theWindow orderOutWithZoomEffectToRect: mGlobalStartRect];
	
	return YES;
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	NSButton*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	[btn setImage: [mContainer displayIcon]];
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%1$@’s User Properties", [mContainer displayName]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@’s User Properties", [mContainer displayName]]
											action: nil keyEquivalent: @"" atIndex: 0];
	[newItem setImage: [mContainer displayIcon]];
	
	return YES;
}


-(void)		setGlobalStartRect: (NSRect)theBox
{
	mGlobalStartRect = theBox;
}


-(void)		setCardView: (WILDCardView*)inView
{
	ASSIGN(mCardView,inView);
}


-(IBAction)	doAddNewProperty: (id)sender
{
	[mUserProperties addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: @"", WILDUserPropertyNameKey, @"", WILDUserPropertyValueKey, nil]];
	[mTableView reloadData];
	[mTableView editColumn: 0 row: mUserProperties.count -1 withEvent: nil select: YES];
}


-(id)	tableView: (NSTableView *)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	return [[mUserProperties objectAtIndex: row] objectForKey: tableColumn.identifier];
}


-(NSInteger)	numberOfRowsInTableView: (NSTableView *)tableView
{
	return mUserProperties.count;
}


-(void)	tableView: (NSTableView *)tableView setObjectValue: (id)object forTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	NSMutableDictionary	*	currRow = [mUserProperties objectAtIndex: row];
	NSString			*	currName = currRow[WILDUserPropertyNameKey];
	NSString			*	currValue = currRow[WILDUserPropertyValueKey];
	NSString			*	oldName = nil;
	if( [tableColumn.identifier isEqualToString: WILDUserPropertyNameKey] )
	{
		if( [object length] == 0 )
			return;
		
		oldName = (currName.length > 0) ? currName : nil;
		currName = object;
		[currRow setObject: object forKey: WILDUserPropertyNameKey];
	}
	else
	{
		currValue = object;
		[currRow setObject: object forKey: WILDUserPropertyValueKey];
	}
	[mContainer setValue: currValue forUserPropertyNamed: currName oldName: oldName];
}

@end
