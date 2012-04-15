//
//  WILDIconListDataSource.h
//  Stacksmith
//
//  Created by Uli Kusterer on 05.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class IKImageBrowserView;
@class WILDDocument;
@class WILDIconListDataSource;


@protocol WILDIconListDataSourceDelegate <NSObject>

@optional
-(void)	iconListDataSourceSelectionDidChange: (WILDIconListDataSource*)inSender;

@end


@interface WILDIconListDataSource : NSObject
{
	WILDDocument*			mDocument;			// This is who we get the icons from.
	NSMutableArray*			mIcons;				// Cached lists of icon names/IDs.
	IKImageBrowserView*		mIconListView;		// View in which we show the icons.
	NSTextField*			mImagePathField;	// Field where we show where the icon comes from.
	id<WILDIconListDataSourceDelegate>	mDelegate;
}

@property (assign) WILDDocument*						document;
@property (retain) IBOutlet IKImageBrowserView*			iconListView;
@property (retain) IBOutlet NSTextField*				imagePathField;
@property (assign) id<WILDIconListDataSourceDelegate>	delegate;

-(id)			initWithDocument: (WILDDocument*)inDocument;

-(void)			setSelectedIconID: (NSInteger)theID;
-(NSInteger)	selectedIconID;

-(void)			ensureIconListExists;

@end
