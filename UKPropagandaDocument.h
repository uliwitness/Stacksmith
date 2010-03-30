//
//  UKPropagandaDocument.h
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class UKPropagandaStack;
@class UKPropagandaCardViewController;
@class UKPropagandaWindowBodyView;


@interface UKPropagandaDocument : NSDocument
{
	UKPropagandaStack					*	mStack;
	IBOutlet UKPropagandaWindowBodyView	*	mView;	
	UKPropagandaCardViewController		*	mCardViewController;
	NSMutableArray						*	mErrorsAndWarnings;
}

@end
