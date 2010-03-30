//
//  UKPropagandaScriptContainer.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol UKPropagandaScriptContainer

-(NSString*)	script;								// Script to be used by script editors etc.
-(void)			setScript: (NSString*)inScript;		// How script editors etc. provide changed scripts.

-(NSString*)	displayName;	// Name of this item to display in window titles etc.
-(NSImage*)		displayIcon;	// Small icon to display for this item in popups etc.

@end


enum
{
	UKPropagandaSymbolTypeUnknown = 0,
	UKPropagandaSymbolTypeHandler,
	UKPropagandaSymbolTypeFunction
};
typedef NSInteger	UKPropagandaSymbolType;


@interface UKPropagandaSymbol : NSObject
{
	NSInteger				lineIndex;
	NSString*				symbolName;
	UKPropagandaSymbolType	symbolType;
}

@property (assign) NSInteger 				lineIndex;
@property (retain) NSString*				symbolName;
@property (assign) UKPropagandaSymbolType	symbolType;

@end



NSString*	UKPropagandaFormatScript( NSString* scriptString, NSArray* *outSymbols );
