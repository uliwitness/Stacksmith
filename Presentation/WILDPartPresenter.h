//
//  WILDPartPresenter.h
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <AppKit/AppKit.h>


@class WILDPart;
@class WILDPartView;


@interface WILDPartPresenter : NSObject
{
	WILDPartView	*	mPartView;
}

-(id)	initWithPartView: (WILDPartView*)inPartView;

-(void)	createSubviews;
-(void)	refreshProperties;
-(void)	removeSubviews;

-(void)	partWillChange: (NSNotification*)inPart;
-(void)	partDidChange: (NSNotification*)inPart;

@end

