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
NSString*	WILDScriptContainerResultFromSendingMessage( id<WILDScriptContainer> container, NSString* fmt, ... );

struct LEOContext;
void		WILDCallNonexistentHandler( struct LEOContext* inContext, LEOHandlerID inHandler );
