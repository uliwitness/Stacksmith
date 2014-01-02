//
//  CTimerPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CTimerPart.h"
#include "CTinyXMLUtils.h"


using namespace Calhoun;


void	CTimerPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CPart::LoadPropertiesFromElement( inElement );
	
	mMessage.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "message", mMessage );
	mInterval = CTinyXMLUtils::GetLongLongNamed( inElement, "interval", 0 );
	mStarted = CTinyXMLUtils::GetBoolNamed( inElement, "started", true );
	mRepeat = CTinyXMLUtils::GetBoolNamed( inElement, "repeat", true );
	mActualTimer.SetHandler( [this](CTimer *inSender) { Trigger(); });
	mActualTimer.SetInterval( mInterval );
	if( mStarted )
		mActualTimer.Start();
}


void	CTimerPart::Trigger()
{
	
	
	if( !mRepeat )
	{
		mActualTimer.Stop();
		mStarted = false;
	}
}


void	CTimerPart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CPart::DumpProperties( inIndentLevel );
	
	printf( "%smessage = %s\n", indentStr, mMessage.c_str() );
	printf( "%sinterval = %lld\n", indentStr, mInterval );
	printf( "%sstarted = %s\n", indentStr, (mStarted ? "true" : "false") );
	printf( "%srepeat = %s\n", indentStr, (mRepeat ? "true" : "false") );
}