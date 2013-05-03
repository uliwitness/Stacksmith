//
//  WILDScriptContainer.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LEOHandlerID.h"


struct LEOScript;
@protocol WILDObject;
@class WILDStack;


@protocol WILDScriptContainer <NSObject>

@required
-(NSString*)			script;								// Script to be used by script editors etc.
-(void)					setScript: (NSString*)inScript;		// How script editors etc. provide changed scripts.

-(NSString*)			displayName;	// Name of this item to display in window titles etc.
-(NSImage*)				displayIcon;	// Small icon to display for this item in popups etc.

-(struct LEOScript*)		scriptObjectShowingErrorMessage: (BOOL)showError;
-(id<WILDObject>)			parentObject;
-(struct LEOContextGroup*)	scriptContextGroupObject;

@optional
-(NSString*)			defaultScriptReturningSelectionRange: (NSRange*)outSelection;

@end


enum
{
	WILDSymbolTypeUnknown = 0,
	WILDSymbolTypeHandler,
	WILDSymbolTypeFunction
};
typedef NSInteger	WILDSymbolType;


@interface WILDSymbol : NSObject
{
	NSInteger				lineIndex;
	NSString*				symbolName;
	WILDSymbolType	symbolType;
}

@property (assign) NSInteger 				lineIndex;
@property (retain) NSString*				symbolName;
@property (assign) WILDSymbolType	symbolType;

@end



NSString*	WILDFormatScript( NSString* scriptString, NSArray* *outSymbols );
NSString*	WILDScriptContainerResultFromSendingMessage( id<WILDScriptContainer,WILDObject> container, NSString* fmt, ... );

struct LEOContext;
void		WILDCallNonexistentHandler( struct LEOContext* inContext, LEOHandlerID inHandler );
void		WILDPreInstructionProc( struct LEOContext * inContext );


extern NSString*	WILDScriptExecutionEventLoopMode;


/*! We store this in the LEOContext's userData to keep host-specific info like the
	current window for this script, which isn't necessary the front window nor
	the window containing the current object (e.g. when a timer runs in an inactive
	window, its current window is its owner, but if it then issues a "go" command,
	the new card becomes the current window: */
@interface WILDScriptContextUserData : NSObject

@property (retain) WILDStack	*	currentStack;	// The current stack for this message.
@property (retain) id<WILDObject>	target;			// Target of current system message.

@end

void	WILDScriptContainerUserDataCleanUp( void* inUserData );	//! Callback the LEOContext calls when it is cleaned up that releases our user data object.


