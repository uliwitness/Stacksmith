//
//  UKPropagandaIconListDataSource.h
//  Stacksmith
//
//  Created by Uli Kusterer on 05.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class IKImageBrowserView;
@class WILDDocument;


@interface UKPropagandaIconListDataSource : NSObject
{
	WILDDocument*			mDocument;			// This is who we get the icons from.
	NSMutableArray*					mIcons;				// Cached lists of icon names/IDs.
	IBOutlet IKImageBrowserView*	mIconListView;		// View in which we show the icons.
	IBOutlet NSTextField*			mImagePathField;	// Field where we show where the icon comes from.
}

@property (assign) WILDDocument*		document;

-(id)			initWithDocument: (WILDDocument*)inDocument;

-(void)			setSelectedIconID: (NSInteger)theID;
-(NSInteger)	selectedIconID;

-(void)			ensureIconListExists;

@end
