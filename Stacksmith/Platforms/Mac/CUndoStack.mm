//
//  CUndoStack.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-03-19.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#include "CUndoStack.h"
#import <Cocoa/Cocoa.h>


@interface WILDLambdaRunner : NSObject
{
	std::function<void()>	mBlock;
}

+(instancetype) lambdaRunnerWithLambda: (std::function<void()>)inLambda;
-(void)			run;

@end


@implementation WILDLambdaRunner

+(instancetype) lambdaRunnerWithLambda: (std::function<void()>)inLambda
{
	WILDLambdaRunner *	lr = [[[[self class] alloc] init] autorelease];
	lr->mBlock = inLambda;
	return lr;
}

-(void)	run
{
	mBlock();
}

@end

using namespace Carlson;


CUndoStack::CUndoStack( NSUndoManager* undoManager )
{
	mUndoManager = [undoManager retain];
}


CUndoStack::~CUndoStack()
{
	[mUndoManager release];
}


void	CUndoStack::AddUndoAction(std::string inActionName, std::function<void()> inAction )
{
	WILDLambdaRunner	*	bo = [WILDLambdaRunner lambdaRunnerWithLambda: inAction];
	[mUndoManager setActionName: [NSString stringWithUTF8String: inActionName.c_str()]];
	[mUndoManager registerUndoWithTarget: bo selector: @selector(run) object: bo];	// We pass bo as the object so it is retained.
}

