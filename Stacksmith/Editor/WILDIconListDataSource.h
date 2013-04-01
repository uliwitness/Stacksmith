//
//  WILDIconListDataSource.h
//  Stacksmith
//
//  Created by Uli Kusterer on 05.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDObjectID.h"


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

@property (assign,nonatomic) WILDDocument*						document;
@property (retain,nonatomic) IBOutlet IKImageBrowserView*		iconListView;
@property (retain,nonatomic) IBOutlet NSTextField*				imagePathField;
@property (assign,nonatomic) id<WILDIconListDataSourceDelegate>	delegate;

-(id)			initWithDocument: (WILDDocument*)inDocument;

-(void)			setSelectedIconID: (WILDObjectID)theID;
-(WILDObjectID)	selectedIconID;

-(void)			ensureIconListExists;

@end
