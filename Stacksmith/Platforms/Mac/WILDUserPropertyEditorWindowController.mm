//
//  WILDUserPropertyEditorWindowController.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDUserPropertyEditorWindowController.h"
#import "CConcreteObject.h"
#import "NSWindow+ULIZoomEffect.h"
#import "UKHelperMacros.h"
#import "CMacPartBase.h"


using namespace Carlson;


@implementation WILDUserPropertyEditorWindowController

-(id)	initWithPropertyContainer: (CConcreteObject*)inContainer
{
	if(( self = [super initWithWindowNibName: NSStringFromClass( [self class] )] ))
	{
		mContainer = inContainer;
	}
	
	return self;
}


-(void)	dealloc
{
	mContainer = NULL;
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	[mTableView reloadData];
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
	
	CMacPartBase*	macPart = dynamic_cast<CMacPartBase*>( mContainer );
	if( macPart )
	{
		NSButton*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
		[btn setImage: macPart->GetDisplayIcon()];
	}
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%1$@’s User Properties", [NSString stringWithUTF8String: mContainer->GetDisplayName().c_str()]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@’s User Properties", [NSString stringWithUTF8String: mContainer->GetDisplayName().c_str()]]
											action: nil keyEquivalent: @"" atIndex: 0];
	CMacPartBase*	macPart = dynamic_cast<CMacPartBase*>( mContainer );
	if( macPart )
		[newItem setImage: macPart->GetDisplayIcon()];
	
	return YES;
}


-(void)		setGlobalStartRect: (NSRect)theBox
{
	mGlobalStartRect = theBox;
}


-(IBAction)	doAddNewProperty: (id)sender
{
	mContainer->AddUserPropertyNamed( "" );
	[mTableView reloadData];
	[mTableView editColumn: 0 row: mContainer->GetNumUserProperties() -1 withEvent: nil select: YES];
}


-(id)	tableView: (NSTableView *)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	if( [tableColumn.identifier isEqualToString: @"WILDUserPropertyNameKey"] )
	{
		std::string	upName = mContainer->GetUserPropertyNameAtIndex( row );
		return [[[NSString alloc] initWithBytes: upName.c_str() length: upName.length() encoding: NSUTF8StringEncoding] autorelease];
	}
	else if( [tableColumn.identifier isEqualToString: @"WILDUserPropertyValueKey"] )
	{
		std::string	upValue;
		mContainer->GetUserPropertyValueForName( mContainer->GetUserPropertyNameAtIndex( row ).c_str(), upValue );
		return [[[NSString alloc] initWithBytes: upValue.c_str() length: upValue.length() encoding: NSUTF8StringEncoding] autorelease];
	}
	return [[mUserProperties objectAtIndex: row] objectForKey: tableColumn.identifier];
}


-(NSInteger)	numberOfRowsInTableView: (NSTableView *)tableView
{
	return mContainer->GetNumUserProperties();
}


-(void)	tableView: (NSTableView *)tableView setObjectValue: (id)object forTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	if( [tableColumn.identifier isEqualToString: @"WILDUserPropertyNameKey"] )
	{
		if( [object length] == 0 )
			return;
		
		NSString*	newNameObjC = [object lowercaseString];
		mContainer->SetUserPropertyNameAtIndex( newNameObjC.UTF8String, row );
	}
	else
	{
		std::string	newValue( [object UTF8String], [object lengthOfBytesUsingEncoding: NSUTF8StringEncoding] );
		std::string	upName = mContainer->GetUserPropertyNameAtIndex( row );
		mContainer->SetUserPropertyValueForName( newValue, upName.c_str() );
	}
}

@end
