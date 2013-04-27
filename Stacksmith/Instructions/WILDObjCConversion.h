//
//  WILDObjCConversion.h
//  Stacksmith
//
//  Created by Uli Kusterer on 04.06.12.
//  Copyright (c) 2012 Uli Kusterer. All rights reserved.
//

/*!
	@header WILDObjCConversion
	Helper methods (mostly useful to people implementing a new type of WILDObject)
	that convert between the primitive LEOValue types and equivalent Objective-C
	types.
*/

#import <Foundation/Foundation.h>
#include "LEOValue.h"
#include "LEOInterpreter.h"


id		WILDObjCObjectFromLEOValue( LEOValuePtr inValue, LEOContext* inContext, LEOValueTypePtr inDesiredType );
BOOL	WILDObjCObjectToLEOValue( id inValue, LEOValuePtr outValue, LEOContext* inContext );
