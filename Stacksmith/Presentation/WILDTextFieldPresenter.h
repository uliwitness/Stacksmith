//
//  WILDTextFieldPresenter.h
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartPresenter.h"
#import "WILDButtonView.h"


@class WILDTextView;
@class WILDScrollView;


@interface WILDTextFieldPresenter : WILDPartPresenter
{
	WILDTextView	*	mTextView;
	WILDScrollView	*	mScrollView;
}



@end
