//
//  CVariableWatcherMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-17.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CVariableWatcherMac.h"
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


using namespace Carlson;


@interface WILDVariableWatcherWindowController : NSWindowController

@property (assign,nonatomic) IBOutlet NSTableView		*	variablesList;
@property (assign,nonatomic) CVariableWatcherMac		*	variableWatcher;

@end


@implementation WILDVariableWatcherWindowController

-(void)	windowDidLoad
{
	//[self.window setLevel: NSNormalWindowLevel];
	double fontSize = [[NSUserDefaults standardUserDefaults] doubleForKey: @"WILDVariableWatcherFontSize"];
	NSFont * theFont = [NSFont systemFontOfSize: fontSize];
	NSCell * dataCell = _variablesList.tableColumns.firstObject.dataCell;
	[dataCell setFont: theFont];
	[_variablesList setRowHeight: dataCell.cellSize.height];
}


-(void)	windowWillClose: (NSNotification *)notification
{
	self.variableWatcher->SetVisible(false);
}


-(NSInteger)	numberOfRowsInTableView: (NSTableView *)tableView;
{
	return self.variableWatcher->GetNumVariables();
}


-(id)	tableView: (NSTableView *)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	std::string	theName, theValue;
	self.variableWatcher->GetVariableAtIndex(row,theName,theValue);
	
	if( [tableColumn.identifier isEqualToString: @"name"] )
		return [NSString stringWithUTF8String: theName.c_str()];
	else
		return [NSString stringWithUTF8String: theValue.c_str()];
}

@end


CVariableWatcherMac::CVariableWatcherMac()
: mVisible(false)
{
	mMacWindowController = [[WILDVariableWatcherWindowController alloc] initWithWindowNibName: @"WILDVariableWatcherWindowController"];
	mMacWindowController.variableWatcher = this;
	
	[mMacWindowController.window setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.3 alpha: 0.7]];
}


CVariableWatcherMac::~CVariableWatcherMac()
{
	[mMacWindowController close];
	[mMacWindowController release];
	mMacWindowController = nil;
}


bool	CVariableWatcherMac::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		const char*	msgName = [mMacWindowController.window.title UTF8String];
		LEOInitStringValue( outValue, msgName, strlen(msgName), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("rectangle", inPropertyName) == 0 || strcasecmp("rect", inPropertyName) == 0 )
	{
		NSRect	box = [mMacWindowController.window contentRectForFrameRect: [mMacWindowController.window frame]];
		NSRect	mainScreenBox = [[NSScreen.screens objectAtIndex: 0] frame];
		box.origin.y = mainScreenBox.size.height -box.origin.y;
		LEOInitRectValue( outValue, NSMinX(box), NSMinY(box), NSMaxX(box), NSMaxY(box), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("visible", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mVisible, kLEOInvalidateReferences, inContext );
	}
	else
		return CVariableWatcher::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CVariableWatcherMac::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		char		nameBuf[1024];
		const char*	nameStr = LEOGetValueAsString( inValue, nameBuf, sizeof(nameBuf), inContext );
		[mMacWindowController.window setTitle: [NSString stringWithUTF8String: nameStr]];
	}
	else if( strcasecmp("rectangle", inPropertyName) == 0 || strcasecmp("rect", inPropertyName) == 0 )
	{
		LEOInteger	l, t, r, b;
		LEOGetValueAsRect( inValue, &l, &t, &r, &b, inContext);
		NSRect		box = { { (CGFloat)l, (CGFloat)t }, { (CGFloat)r - l, (CGFloat)b - t } };
		NSRect		mainScreenBox = [[NSScreen.screens objectAtIndex: 0] frame];
		box.origin.y = mainScreenBox.size.height -box.origin.y;
		
		[mMacWindowController.window setFrame: box display: YES];
	}
	else if( strcasecmp("visible", inPropertyName) == 0 )
	{
		bool	isVisible = LEOGetValueAsBoolean( inValue, inContext );
		if( isVisible )
			[mMacWindowController.window makeKeyAndOrderFront: nil];
		else
			[mMacWindowController.window orderOut: nil];
		mVisible = isVisible;
	}
	else
		return CVariableWatcher::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


void	CVariableWatcherMac::SetVisible( bool n )
{
	CVariableWatcher::SetVisible( n );
	if( n )
		[mMacWindowController.window makeKeyAndOrderFront: nil];
	else
		[mMacWindowController.window orderOut: nil];
	mVisible = n;
}


void	CVariableWatcherMac::UpdateVariables()
{
	CVariableWatcher::UpdateVariables();
	
	[mMacWindowController.variablesList reloadData];
}

