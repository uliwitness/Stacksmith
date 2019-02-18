//
//  WILDMediaListDataSource.h
//  Stacksmith
//
//  Created by Uli Kusterer on 05.04.10.
//  Copyright 2010 Uli Kusterer All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CObjectID.h"
#import "CMediaCache.h"


namespace Carlson
{
	class CDocument;
};


@class WILDMediaListDataSource;


@protocol WILDMediaListDataSourceDelegate <NSObject>

@optional
-(void)	iconListDataSourceSelectionDidChange: (WILDMediaListDataSource*)inSender;

@end


@interface WILDMediaListDataSource : NSObject <NSCollectionViewDataSource, NSCollectionViewDelegate>
{
	Carlson::CDocument*		mDocument;			// This is who we get the icons from.
	NSMutableArray*			mIcons;				// Cached lists of icon names/IDs.
	NSCollectionView*		mIconListView;		// View in which we show the icons.
	NSTextField*			mImagePathField;	// Field where we show where the icon comes from.
	id<WILDMediaListDataSourceDelegate>	mDelegate;
	Carlson::TMediaType		mMediaType;			// Type of media to display, i.e. icons, cursors etc.
}

@property (assign,nonatomic) Carlson::CDocument*				document;
@property (retain,nonatomic) IBOutlet NSCollectionView*			iconListView;
@property (retain,nonatomic) IBOutlet NSTextField*				imagePathField;
@property (assign,nonatomic) id<WILDMediaListDataSourceDelegate>	delegate;
@property (assign,nonatomic) Carlson::TMediaType				mediaType;

-(void)					setSelectedIconID: (Carlson::ObjectID)theID;
-(Carlson::ObjectID)	selectedIconID;

-(void)			ensureIconListExists;

@end
