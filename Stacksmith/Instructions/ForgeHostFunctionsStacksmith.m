//
//  ForgeHostFunctionsStacksmith.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "ForgeHostFunctionsStacksmith.h"
#include "ForgeWILDObjectValue.h"
#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDLayer.h"
#import "WILDCard.h"
#import "WILDPart.h"
#import "LEOScript.h"


void	WILDStackInstruction( LEOContext* inContext );
void	WILDBackgroundInstruction( LEOContext* inContext );
void	WILDCardInstruction( LEOContext* inContext );
void	WILDCardFieldInstruction( LEOContext* inContext );
void	WILDCardButtonInstruction( LEOContext* inContext );
void	WILDCardMoviePlayerInstruction( LEOContext* inContext );
void	WILDCardPartInstruction( LEOContext* inContext );
void	WILDBackgroundFieldInstruction( LEOContext* inContext );
void	WILDBackgroundButtonInstruction( LEOContext* inContext );
void	WILDBackgroundMoviePlayerInstruction( LEOContext* inContext );
void	WILDBackgroundPartInstruction( LEOContext* inContext );
void	WILDNextCardInstruction( LEOContext* inContext );
void	WILDPreviousCardInstruction( LEOContext* inContext );
void	WILDNextBackgroundInstruction( LEOContext* inContext );
void	WILDPreviousBackgroundInstruction( LEOContext* inContext );
void	WILDFirstCardInstruction( LEOContext* inContext );
void	WILDLastCardInstruction( LEOContext* inContext );
void	WILDPushOrdinalBackgroundInstruction( LEOContext* inContext );
void	WILDPushOrdinalPartInstruction( LEOContext* inContext );
void	WILDThisStackInstruction( LEOContext* inContext );
void	WILDThisBackgroundInstruction( LEOContext* inContext );
void	WILDThisCardInstruction( LEOContext* inContext );
void	WILDNumberOfCardButtonsInstruction( LEOContext* inContext );
void	WILDNumberOfCardFieldsInstruction( LEOContext* inContext );
void	WILDNumberOfCardMoviePlayersInstruction( LEOContext* inContext );
void	WILDNumberOfCardPartsInstruction( LEOContext* inContext );
void	WILDNumberOfBackgroundButtonsInstruction( LEOContext* inContext );
void	WILDNumberOfBackgroundFieldsInstruction( LEOContext* inContext );
void	WILDNumberOfBackgroundMoviePlayersInstruction( LEOContext* inContext );
void	WILDNumberOfBackgroundPartsInstruction( LEOContext* inContext );


size_t	kFirstStacksmithHostFunctionInstruction = 0;


void	WILDStackInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	NSString	*	stackNameObj = [NSString stringWithUTF8String: stackName];
	WILDStack	*	theStack = [WILDDocument openStackNamed: stackNameObj];
		
	if( theStack )
	{
		LEOValuePtr	valueToReplace = inContext->stackEndPtr -1;
		LEOCleanUpValue( valueToReplace, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &valueToReplace->object, theStack, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find stack \"%s\".", stackName );
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundInstruction( LEOContext* inContext )
{
	WILDBackground	*	theBackground = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				backgroundName[1024] = { 0 };
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		NSUInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		if( theNumber > 0 && theNumber <= [[frontStack backgrounds] count] )
			theBackground = [[frontStack cards] objectAtIndex: theNumber -1];
		else
			snprintf( backgroundName, sizeof(backgroundName), "%lu", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, backgroundName, sizeof(backgroundName), inContext );
		
		theBackground = [frontStack backgroundNamed: [NSString stringWithUTF8String: backgroundName]];
	}
	
	if( theBackground )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, theBackground, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find background \"%s\".", backgroundName );
	}
	
	inContext->currentInstruction++;
}


void	WILDCardInstruction( LEOContext* inContext )
{
	WILDCard	*	theCard = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			cardName[1024] = { 0 };
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		NSUInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		if( theNumber > 0 && theNumber <= [[frontStack cards] count] )
			theCard = [[frontStack cards] objectAtIndex: theNumber -1];
		else
			snprintf( cardName, sizeof(cardName), "%lu", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, cardName, sizeof(cardName), inContext );
		
		theCard = [frontStack cardNamed: [NSString stringWithUTF8String: cardName]];
	}
	
	if( theCard )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, theCard, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find card \"%s\".", cardName );
	}
	
	inContext->currentInstruction++;
}


void	WILDCardFieldInstruction( LEOContext* inContext )
{
	WILDPart	*	thePart = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			partName[1024] = { 0 };
	WILDCard	*	theCard = [frontStack currentCard];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"field"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"field"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find field \"%s\".", partName );
	}
	
	inContext->currentInstruction++;
}


void	WILDCardButtonInstruction( LEOContext* inContext )
{
	WILDPart	*	thePart = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			partName[1024] = { 0 };
	WILDCard	*	theCard = [frontStack currentCard];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"button"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"button"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find button \"%s\".", partName );
	}
	
	inContext->currentInstruction++;
}


void	WILDCardMoviePlayerInstruction( LEOContext* inContext )
{
	WILDPart	*	thePart = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			partName[1024] = { 0 };
	WILDCard	*	theCard = [frontStack currentCard];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"moviePlayer"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"moviePlayer"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find movie player \"%s\".", partName );
	}
	
	inContext->currentInstruction++;
}


void	WILDCardPartInstruction( LEOContext* inContext )
{
	WILDPart	*	thePart = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			partName[1024] = { 0 };
	WILDCard	*	theCard = [frontStack currentCard];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: nil];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: nil];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find part \"%s\".", partName );
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundFieldInstruction( LEOContext* inContext )
{
	WILDPart		*	thePart = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				partName[1024] = { 0 };
	WILDBackground	*	theCard = [[frontStack currentCard] owningBackground];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"field"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"field"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find field \"%s\".", partName );
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundButtonInstruction( LEOContext* inContext )
{
	WILDPart		*	thePart = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				partName[1024] = { 0 };
	WILDBackground	*	theCard = [[frontStack currentCard] owningBackground];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"button"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"button"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find button \"%s\".", partName );
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundMoviePlayerInstruction( LEOContext* inContext )
{
	WILDPart		*	thePart = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				partName[1024] = { 0 };
	WILDBackground	*	theCard = [[frontStack currentCard] owningBackground];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"moviePlayer"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"moviePlayer"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find movie player \"%s\".", partName );
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundPartInstruction( LEOContext* inContext )
{
	WILDPart		*	thePart = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				partName[1024] = { 0 };
	WILDBackground	*	theCard = [[frontStack currentCard] owningBackground];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: nil];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: nil];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Can't find part \"%s\".", partName );
	}
	
	inContext->currentInstruction++;
}


void	WILDNextCardInstruction( LEOContext* inContext )
{
	WILDStack	*	theStack = [WILDDocument frontStackNamed: nil];
	WILDCard	*	theCard = [[theStack document] currentCard];
	NSUInteger		cardIdx = [[theStack cards] indexOfObject: theCard];
	cardIdx++;
	if( cardIdx >= [[theStack cards] count] )
		cardIdx = 0;
	theCard = [[theStack cards] objectAtIndex: cardIdx];
	
	LEOInitWILDObjectValue( &inContext->stackEndPtr->object, theCard, kLEOInvalidateReferences, inContext );
	inContext->stackEndPtr ++;
	
	inContext->currentInstruction++;
}


void	WILDPreviousCardInstruction( LEOContext* inContext )
{
	WILDStack	*	theStack = [WILDDocument frontStackNamed: nil];
	WILDCard	*	theCard = [[theStack document] currentCard];
	NSUInteger		cardIdx = [[theStack cards] indexOfObject: theCard];
	if( cardIdx == 0 )
		cardIdx = [[theStack cards] count] -1;
	else
		cardIdx--;
	theCard = [[theStack cards] objectAtIndex: cardIdx];
	
	LEOInitWILDObjectValue( &inContext->stackEndPtr->object, theCard, kLEOInvalidateReferences, inContext );
	inContext->stackEndPtr ++;
	
	inContext->currentInstruction++;
}


void	WILDNextBackgroundInstruction( LEOContext* inContext )
{
	WILDStack		*	theStack = [WILDDocument frontStackNamed: nil];
	WILDBackground	*	theBackground = [[theStack document] currentCard].owningBackground;
	NSUInteger			bkgdIndex = [[theStack backgrounds] indexOfObject: theBackground];
	bkgdIndex++;
	if( bkgdIndex >= [[theStack backgrounds] count] )
		bkgdIndex = 0;
	theBackground = [[theStack backgrounds] objectAtIndex: bkgdIndex];
	
	LEOInitWILDObjectValue( &inContext->stackEndPtr->object, theBackground, kLEOInvalidateReferences, inContext );
	inContext->stackEndPtr ++;
	
	inContext->currentInstruction++;
}


void	WILDPreviousBackgroundInstruction( LEOContext* inContext )
{
	WILDStack		*	theStack = [WILDDocument frontStackNamed: nil];
	WILDBackground	*	theBackground = [[theStack document] currentCard].owningBackground;
	NSUInteger			bkgdIndex = [[theStack backgrounds] indexOfObject: theBackground];
	if( bkgdIndex == 0 )
		bkgdIndex = [[theStack backgrounds] count] -1;
	else
		bkgdIndex--;
	theBackground = [[theStack backgrounds] objectAtIndex: bkgdIndex];
	
	LEOInitWILDObjectValue( &inContext->stackEndPtr->object, theBackground, kLEOInvalidateReferences, inContext );
	inContext->stackEndPtr ++;
	
	inContext->currentInstruction++;
}


void	WILDFirstCardInstruction( LEOContext* inContext )
{
	WILDStack	*	theStack = [WILDDocument frontStackNamed: nil];
	WILDCard	*	theCard = [[theStack cards] objectAtIndex: 0];
	
	if( theStack.cards.count == 0 )
		LEOContextStopWithError( inContext, "No such card." );
	
	if( inContext->keepRunning )	// No error?
	{
		LEOInitWILDObjectValue( &inContext->stackEndPtr->object, theCard, kLEOInvalidateReferences, inContext );
		inContext->stackEndPtr ++;
	}
	
	inContext->currentInstruction++;
}


void	WILDLastCardInstruction( LEOContext* inContext )
{
	WILDStack	*	theStack = [WILDDocument frontStackNamed: nil];
	WILDCard	*	theCard = [[theStack cards] lastObject];
	
	if( theStack.cards.count == 0 )
		LEOContextStopWithError( inContext, "No such card." );
	
	if( inContext->keepRunning )	// No error?
	{
		LEOInitWILDObjectValue( &inContext->stackEndPtr->object, theCard, kLEOInvalidateReferences, inContext );
		inContext->stackEndPtr ++;
	}
	
	inContext->currentInstruction++;
}


void	WILDPushOrdinalBackgroundInstruction( LEOContext* inContext )
{
	WILDStack		*	theStack = [WILDDocument frontStackNamed: nil];
	
	if( theStack.backgrounds.count == 0 )
		LEOContextStopWithError( inContext, "No such background." );
	
	if( inContext->keepRunning )
	{
		WILDBackground	*	theBackground = (inContext->currentInstruction->param1 & 32) ? [[theStack backgrounds] lastObject] : [[theStack backgrounds] objectAtIndex: 0];
		
		LEOInitWILDObjectValue( &inContext->stackEndPtr->object, theBackground, kLEOInvalidateReferences, inContext );
		inContext->stackEndPtr ++;
	}
	
	inContext->currentInstruction++;
}


void	WILDPushOrdinalPartInstruction( LEOContext* inContext )
{
	WILDStack		*	theStack = [WILDDocument frontStackNamed: nil];
	WILDCard		*	theCard = [theStack.document currentCard];
	WILDBackground	*	theBackground = [theCard owningBackground];
	WILDLayer		*	theLayer = theCard;
	NSString		*	partType = nil;
		
	if( (inContext->currentInstruction->param1 & 16) != 0 )
		theLayer = theBackground;
	
	uint16_t	partTypeNum = inContext->currentInstruction->param1 & ~(16 | 32);
	
	if( partTypeNum == 1 )
		partType = @"button";
	else if( partTypeNum == 2 )
		partType = @"field";
	else if( partTypeNum == 3 )
		partType = @"moviePlayer";
	else if( partTypeNum != 0 )
		LEOContextStopWithError( inContext, "Can only list parts, buttons, fields and movie players on cards and backgrounds." );
	
	if( inContext->keepRunning )	// No error?
	{
		NSInteger		numParts = [theLayer numberOfPartsOfType: partType];
		if( numParts == 0 )
			LEOContextStopWithError( inContext, "No such %s.", [partType UTF8String] );
		
		NSInteger	desiredIndex = 0;
		if( inContext->currentInstruction->param1 & 32 )
			desiredIndex = numParts -1;
		
		if( inContext->keepRunning )	// Still no error? I.e. we have parts of this type?
		{
			WILDPart	*	thePart = [theLayer partAtIndex: desiredIndex ofType: partType];
			
			LEOInitWILDObjectValue( &inContext->stackEndPtr->object, thePart, kLEOInvalidateReferences, inContext );
			inContext->stackEndPtr ++;
		}
	}
	
	inContext->currentInstruction++;
}


void	WILDThisStackInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
		
	if( frontStack )
	{
		inContext->stackEndPtr++;
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, frontStack, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}


void	WILDThisBackgroundInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDBackground	*	theBackground = [[frontStack currentCard] owningBackground];
	
	if( theBackground )
	{
		inContext->stackEndPtr++;
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, theBackground, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}


void	WILDThisCardInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDCard		*	theCard = [frontStack currentCard];
	
	if( theCard )
	{
		inContext->stackEndPtr++;
		LEOInitWILDObjectValue( &(inContext->stackEndPtr -1)->object, theCard, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}


void	WILDNumberOfCardButtonsInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDCard		*	theCard = [frontStack currentCard];
	
	if( theCard )
		LEOPushIntegerOnStack( inContext, [theCard numberOfPartsOfType: @"button"] );
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}


void	WILDNumberOfCardFieldsInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDCard		*	theCard = [frontStack currentCard];
	
	if( theCard )
		LEOPushIntegerOnStack( inContext, [theCard numberOfPartsOfType: @"field"] );
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}

void	WILDNumberOfCardMoviePlayersInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDCard		*	theCard = [frontStack currentCard];
	
	if( theCard )
		LEOPushIntegerOnStack( inContext, [theCard numberOfPartsOfType: @"moviePlayer"] );
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}



void	WILDNumberOfCardPartsInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDCard		*	theCard = [frontStack currentCard];
	
	if( theCard )
		LEOPushIntegerOnStack( inContext, [theCard numberOfPartsOfType: nil] );
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}


void	WILDNumberOfBackgroundButtonsInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDBackground	*	theBackground = [[frontStack currentCard] owningBackground];
	
	if( theBackground )
		LEOPushIntegerOnStack( inContext, [theBackground numberOfPartsOfType: @"button"] );
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}


void	WILDNumberOfBackgroundFieldsInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDBackground	*	theBackground = [[frontStack currentCard] owningBackground];
	
	if( theBackground )
		LEOPushIntegerOnStack( inContext, [theBackground numberOfPartsOfType: @"field"] );
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}


void	WILDNumberOfBackgroundMoviePlayersInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDBackground	*	theBackground = [[frontStack currentCard] owningBackground];
	
	if( theBackground )
		LEOPushIntegerOnStack( inContext, [theBackground numberOfPartsOfType: @"moviePlayer"] );
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}


void	WILDNumberOfBackgroundPartsInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDBackground	*	theBackground = [[frontStack currentCard] owningBackground];
	
	if( theBackground )
		LEOPushIntegerOnStack( inContext, [theBackground numberOfPartsOfType: nil] );
	else
	{
		LEOContextStopWithError( inContext, "No stack open at the moment." );
	}
	
	inContext->currentInstruction++;
}



LEOINSTR_START(StacksmithHostFunction,WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS)
LEOINSTR(WILDStackInstruction)
LEOINSTR(WILDBackgroundInstruction)
LEOINSTR(WILDCardInstruction)
LEOINSTR(WILDCardFieldInstruction)
LEOINSTR(WILDCardButtonInstruction)
LEOINSTR(WILDCardMoviePlayerInstruction)
LEOINSTR(WILDCardPartInstruction)
LEOINSTR(WILDBackgroundFieldInstruction)
LEOINSTR(WILDBackgroundButtonInstruction)
LEOINSTR(WILDBackgroundMoviePlayerInstruction)
LEOINSTR(WILDBackgroundPartInstruction)
LEOINSTR(WILDNextCardInstruction)
LEOINSTR(WILDPreviousCardInstruction)
LEOINSTR(WILDFirstCardInstruction)
LEOINSTR(WILDLastCardInstruction)
LEOINSTR(WILDNextBackgroundInstruction)
LEOINSTR(WILDPreviousBackgroundInstruction)
LEOINSTR(WILDPushOrdinalBackgroundInstruction)
LEOINSTR(WILDPushOrdinalPartInstruction)
LEOINSTR(WILDThisStackInstruction)
LEOINSTR(WILDThisBackgroundInstruction)
LEOINSTR(WILDThisCardInstruction)
LEOINSTR(WILDNumberOfCardButtonsInstruction)
LEOINSTR(WILDNumberOfCardFieldsInstruction)
LEOINSTR(WILDNumberOfCardMoviePlayersInstruction)
LEOINSTR(WILDNumberOfCardPartsInstruction)
LEOINSTR(WILDNumberOfBackgroundButtonsInstruction)
LEOINSTR(WILDNumberOfBackgroundFieldsInstruction)
LEOINSTR(WILDNumberOfBackgroundMoviePlayersInstruction)
LEOINSTR_LAST(WILDNumberOfBackgroundPartsInstruction)


struct THostCommandEntry	gStacksmithHostFunctions[] =
{
	{
		EStackIdentifier, WILD_STACK_INSTRUCTION, 0, 0, '\0',
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EBackgroundIdentifier, WILD_BACKGROUND_INSTRUCTION, 0, 0, '\0',
		{
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_BACKGROUND_BUTTON_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_BACKGROUND_FIELD_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_BACKGROUND_PART_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_BACKGROUND_MOVIEPLAYER_INSTRUCTION, 0, 0, '\0', 'B' },
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterOptional, WILD_BACKGROUND_MOVIEPLAYER_INSTRUCTION, 0, 0, 'B', 'A' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'A', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ECardIdentifier, WILD_CARD_INSTRUCTION, 0, 0, '\0',
		{
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_CARD_BUTTON_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_CARD_FIELD_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_CARD_PART_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0, '\0', 'B' },
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterOptional, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0, 'B', 'A' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'A', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EFieldIdentifier, WILD_CARD_FIELD_INSTRUCTION, 0, 0, '\0',
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EButtonIdentifier, WILD_CARD_BUTTON_INSTRUCTION, 0, 0, '\0',
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EMovieIdentifier, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0, '\0',
		{
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EPartIdentifier, WILD_CARD_PART_INSTRUCTION, 0, 0, '\0',
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ENumberIdentifier, INVALID_INSTR2, 0, 0, 'X',
		{
			{ EHostParamInvisibleIdentifier, EOfIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'A' },
			{ EHostParamInvisibleIdentifier, EBackgroundIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'A', 'B' },
			{ EHostParamInvisibleIdentifier, ECardIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'A', 'C' },
			{ EHostParamInvisibleIdentifier, EButtonsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_BACKGROUND_BUTTONS_INSTRUCTION, 0, 0, 'B', 'X' },
			{ EHostParamInvisibleIdentifier, EFieldsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_BACKGROUND_FIELDS_INSTRUCTION, 0, 0, 'B', 'X' },
			{ EHostParamInvisibleIdentifier, EMovieIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'B', 'M' },
			{ EHostParamInvisibleIdentifier, EPlayersIdentifier, EHostParameterOptional, WILD_NUMBER_OF_BACKGROUND_MOVIEPLAYERS_INSTRUCTION, 0, 0, 'M', 'X' },
			{ EHostParamInvisibleIdentifier, EPartsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_BACKGROUND_PARTS_INSTRUCTION, 0, 0, 'B', 'X' },
			{ EHostParamInvisibleIdentifier, EButtonsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_CARD_BUTTONS_INSTRUCTION, 0, 0, 'C', 'X' },
			{ EHostParamInvisibleIdentifier, EFieldsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_CARD_FIELDS_INSTRUCTION, 0, 0, 'C', 'X' },
			{ EHostParamInvisibleIdentifier, EMovieIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'C', 'm' },
			{ EHostParamInvisibleIdentifier, EPlayersIdentifier, EHostParameterOptional, WILD_NUMBER_OF_CARD_MOVIEPLAYERS_INSTRUCTION, 0, 0, 'm', 'X' },
			{ EHostParamInvisibleIdentifier, EPartsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_CARD_PARTS_INSTRUCTION, 0, 0, 'C', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ENextIdentifier, INVALID_INSTR2, 0, 0, '\0',
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_NEXT_CARD_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_NEXT_BACKGROUND_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EPreviousIdentifier, INVALID_INSTR2, 0, 0, '\0',
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_PREVIOUS_CARD_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_PREVIOUS_BACKGROUND_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EFirstIdentifier, INVALID_INSTR2, 0, 0, '\0',
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_FIRST_CARD_INSTRUCTION, 0, 0, '\0', 'C' },
			{ EHostParamIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_BACKGROUND_INSTRUCTION, 32, 0, '\0', 'B' },
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 1, 0, 'C', 'x' },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 2, 0, 'C', 'x' },
			{ EHostParamIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 3, 0, 'C', 'y' },
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 3, 0, 'y', 'x' },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 0, 0, 'C', 'x' },
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+1, 0, 'B', 'x' },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+2, 0, 'B', 'x' },
			{ EHostParamIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+3, 0, 'B', 'z' },
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+3, 0, 'z', 'x' },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+0, 0, 'B', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ELastIdentifier, INVALID_INSTR2, 0, 0, '\0',
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_LAST_CARD_INSTRUCTION, 0, 0, '\0', 'C' },
			{ EHostParamIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_BACKGROUND_INSTRUCTION, 0, 0, '\0', 'B' },
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+1, 0, 'C', 'x' },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+2, 0, 'C', 'x' },
			{ EHostParamIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+3, 0, 'C', 'y' },
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+3, 0, 'y', 'x' },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+0, 0, 'C', 'x' },
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+1, 0, 'B', 'x' },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+2, 0, 'B', 'x' },
			{ EHostParamIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+3, 0, 'B', 'z' },
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+3, 0, 'z', 'x' },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+0, 0, 'B', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EThisIdentifier, INVALID_INSTR2, 0, 0, '\0',
		{
			{ EHostParamIdentifier, EStackIdentifier, EHostParameterOptional, WILD_THIS_STACK_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_THIS_BACKGROUND_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_THIS_CARD_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR2, 0, 0, '\0',
		{
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	}
};
