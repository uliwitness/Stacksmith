//
//  WILDUserPropertyEditorController.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDUserPropertyEditorController.h"
#import "CConcreteObject.h"
#import "NSWindow+ULIZoomEffect.h"
#import "UKHelperMacros.h"
#import "CMacPartBase.h"


using namespace Carlson;


@implementation WILDUserPropertyEditorController

@synthesize propertyContainer = mContainer;

-(id)	initWithPropertyContainer: (CConcreteObject*)inContainer
{
	if(( self = [super init] ))
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


-(void)	setPropertyContainer: (CConcreteObject*)inPC
{
	mContainer = inPC;
	[mTableView reloadData];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	[mTableView reloadData];
}

-(IBAction)	doAddNewProperty: (id)sender
{
	if( !mContainer )
		return;
	mContainer->AddUserPropertyNamed( "" );
	[mTableView reloadData];
	[mTableView editColumn: 0 row: mContainer->GetNumUserProperties() -1 withEvent: nil select: YES];
}


-(id)	tableView: (NSTableView *)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	if( !mContainer )
		return nil;
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
	return @"Hallo Daniel!";
}


-(NSInteger)	numberOfRowsInTableView: (NSTableView *)tableView
{
	if( !mContainer )
		return 0;
	return mContainer->GetNumUserProperties();
}


-(void)	tableView: (NSTableView *)tableView setObjectValue: (id)object forTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	if( !mContainer )
		return;
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
