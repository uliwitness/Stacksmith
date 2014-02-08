//
//  WILDIconListDataSource.h
//  Stacksmith
//
//  Created by Uli Kusterer on 05.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CObjectID.h"


namespace Carlson
{
	class CDocument;
};


@class IKImageBrowserView;
@class WILDIconListDataSource;


@protocol WILDIconListDataSourceDelegate <NSObject>

@optional
-(void)	iconListDataSourceSelectionDidChange: (WILDIconListDataSource*)inSender;

@end


@interface WILDIconListDataSource : NSObject
{
	Carlson::CDocument*		mDocument;			// This is who we get the icons from.
	NSMutableArray*			mIcons;				// Cached lists of icon names/IDs.
	IKImageBrowserView*		mIconListView;		// View in which we show the icons.
	NSTextField*			mImagePathField;	// Field where we show where the icon comes from.
	id<WILDIconListDataSourceDelegate>	mDelegate;
}

@property (assign,nonatomic) Carlson::CDocument*				document;
@property (retain,nonatomic) IBOutlet IKImageBrowserView*		iconListView;
@property (retain,nonatomic) IBOutlet NSTextField*				imagePathField;
@property (assign,nonatomic) id<WILDIconListDataSourceDelegate>	delegate;

-(id)			initWithDocument: (Carlson::CDocument*)inDocument;

-(void)					setSelectedIconID: (Carlson::ObjectID)theID;
-(Carlson::ObjectID)	selectedIconID;

-(void)			ensureIconListExists;

@end
