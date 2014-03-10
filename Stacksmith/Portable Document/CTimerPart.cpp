//
//  CTimerPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CTimerPart.h"
#include "CTinyXMLUtils.h"


using namespace Carlson;


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
}


void	CTimerPart::SavePropertiesToElement( tinyxml2::XMLElement * inElement )
{
	CPart::SavePropertiesToElement( inElement );
	
	tinyxml2::XMLDocument	*	document = inElement->GetDocument();
	tinyxml2::XMLElement	*	elem = document->NewElement("message");
	elem->SetText(mMessage.c_str());
	inElement->InsertEndChild(elem);
	
	CTinyXMLUtils::AddLongLongNamed( inElement, mInterval, "interval" );
	
	CTinyXMLUtils::AddBoolNamed( inElement, mStarted, "started" );
	CTinyXMLUtils::AddBoolNamed( inElement, mRepeat, "repeat" );
}


void	CTimerPart::Trigger()
{
	CAutoreleasePool		pool;
	SendMessage( NULL, [](const char *, size_t, size_t, CScriptableObject *){}, mMessage.c_str() );
	
	if( !mRepeat )
	{
		mActualTimer.Stop();
		mStarted = false;
	}
}


void	CTimerPart::WakeUp()
{
	if( mStarted )
		mActualTimer.Start();
}


void	CTimerPart::GoToSleep()
{
	if( mStarted )
		mActualTimer.Stop();
}


bool	CTimerPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("started", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetStarted(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("interval", inPropertyName) == 0 )
	{
		LEOInitIntegerValue( outValue, GetInterval(), kLEOUnitTicks, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("message", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, GetMessage().c_str(), GetMessage().size(), kLEOInvalidateReferences, inContext );
	}
	else
		return CPart::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CTimerPart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("started", inPropertyName) == 0 )
	{
		bool	startState = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetStarted( startState );
	}
	else if( strcasecmp("interval", inPropertyName) == 0 )
	{
		LEOUnit		theUnit = kLEOUnitNone;
		LEOInteger	theInterval = LEOGetValueAsInteger( inValue, &theUnit, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		if( theUnit != kLEOUnitNone )	// We take "none" to be ticks as well.
		{
			if( gUnitGroupsForLabels[theUnit] != gUnitGroupsForLabels[kLEOUnitTicks] )
			{
				LEOContextStopWithError( inContext, SIZE_T_MAX, SIZE_T_MAX, 0, "Expected a time interval, found%s.", gUnitLabels[theUnit] );
				return true;
			}
			theInterval = LEONumberWithUnitAsUnit( theInterval, theUnit, kLEOUnitTicks );
		}
		
		SetInterval( theInterval );
	}
	else if( strcasecmp("message", inPropertyName) == 0 )
	{
		char		msgBuf[1024] = {0};
		const char* msgStr = LEOGetValueAsString( inValue, msgBuf, sizeof(msgBuf), inContext );
		if( !msgStr || (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetMessage( msgStr );
	}
	else
		return CPart::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
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