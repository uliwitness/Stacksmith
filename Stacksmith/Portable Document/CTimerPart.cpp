//
//  CTimerPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CTimerPart.h"
#include "CTinyXMLUtils.h"
#include "CStack.h"
#include "CAlert.h"
#include <sstream>


using namespace Carlson;


CTimerPart::CTimerPart( CLayer *inOwner )
	: CPart( inOwner ), mInterval(120), mStarted(false), mRepeat(false)
{
	mActualTimer.SetHandler( [this](CTimer *inSender) { Trigger(); });
	mActualTimer.SetInterval( mInterval );
}


void	CTimerPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CPart::LoadPropertiesFromElement( inElement );
	
	mMessage.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "message", mMessage );
	mInterval = CTinyXMLUtils::GetLongLongNamed( inElement, "interval", 0 );
	mStarted = CTinyXMLUtils::GetBoolNamed( inElement, "started", true );
	mRepeat = CTinyXMLUtils::GetBoolNamed( inElement, "repeat", true );
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
	if( GetStack()->GetTool() != EBrowseTool )
		return;
	
	CAutoreleasePool		pool;
	SendMessage( NULL, [](const char * errMsg, size_t inLine, size_t inOffs, CScriptableObject * obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, mMessage.c_str() );
	
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
				size_t		lineNo = SIZE_T_MAX;
				uint16_t	fileID = 0;
				LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
				LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Expected a time interval, found%s.", gUnitLabels[theUnit] );
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


std::vector<CAddHandlerListEntry>	CTimerPart::GetAddHandlerList()
{
	std::vector<CAddHandlerListEntry>	handlers = CPart::GetAddHandlerList();
	
	if( mMessage.length() == 0 )
		SetMessage("timerTriggered");
	
	LEOContextGroup*	theGroup = GetScriptContextGroupObject();
	LEOHandlerID timerMessageHandlerID = LEOContextGroupHandlerIDForHandlerName( theGroup, mMessage.c_str() );
	if( LEOScriptFindCommandHandlerWithID( mScriptObject, timerMessageHandlerID ) == NULL )
	{
		CAddHandlerListEntry	currSeparator;
		currSeparator.mHandlerName = "Timer Messages";
		currSeparator.mType = EHandlerEntryGroupHeader;
		handlers.push_back( currSeparator );
		
		CAddHandlerListEntry	currHandler;
		currSeparator.mType = EHandlerEntryCommand;
		currHandler.mHandlerName = mMessage;
		currHandler.mHandlerID = timerMessageHandlerID;
		currHandler.mHandlerDescription = "The message that this timer will periodically send to itself.";
		
		std::stringstream	strstr;
		strstr << "\n\non " << currHandler.mHandlerName << "\n\t\nend " << currHandler.mHandlerName;
		currHandler.mHandlerTemplate = strstr.str();
		
		handlers.push_back( currHandler );
	}
	
	return handlers;
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