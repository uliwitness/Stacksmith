//
//  WILDTemplateProjectPickerController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-01-25.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class IKImageBrowserView;


@interface WILDTemplateProjectPickerController : NSWindowController
{
	NSMutableArray	*	groups;
	NSMutableArray	*	items;
}

@property (assign,nonatomic) IBOutlet IKImageBrowserView*	iconListView;
@property (copy,nonatomic) void	(^callbackHandler)( NSString* inPickedFilePath );

-(IBAction)	doOK: (id)sender;
-(IBAction)	doCancel: (id)sender;

@end
