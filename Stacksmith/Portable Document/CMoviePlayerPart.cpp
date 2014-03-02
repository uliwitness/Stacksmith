//
//  CMoviePlayerPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMoviePlayerPart.h"
#include "CTinyXMLUtils.h"
#include <CoreMedia/CoreMedia.h>


using namespace Carlson;


void	CMoviePlayerPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::LoadPropertiesFromElement( inElement );
	
	mMediaPath.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "mediaPath", mMediaPath );
	SetCurrentTime( CTinyXMLUtils::GetLongLongNamed( inElement, "currentTime", 0 ) );
	mControllerVisible = CTinyXMLUtils::GetBoolNamed( inElement, "controllerVisible", true );
}


void	CMoviePlayerPart::SavePropertiesToElementOfDocument( tinyxml2::XMLElement * inElement, tinyxml2::XMLDocument* document )
{
	CVisiblePart::SavePropertiesToElementOfDocument( inElement, document );
	
	tinyxml2::XMLElement	*	elem = document->NewElement("mediaPath");
	elem->SetText(mMediaPath.c_str());
	inElement->InsertEndChild(elem);
	
	CTinyXMLUtils::AddLongLongNamed( inElement, GetCurrentTime(), "currentTime" );
	
	CTinyXMLUtils::AddBoolNamed( inElement, mControllerVisible, "controllerVisible" );
}


bool	CMoviePlayerPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("currentTime", inPropertyName) == 0 )
	{
		LEOInitIntegerValue( outValue, GetCurrentTime(), kLEOUnitTicks, kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("controllerVisible", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetControllerVisible(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("started", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, GetStarted(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("movie", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, GetMediaPath().c_str(), GetMediaPath().size(), kLEOInvalidateReferences, inContext );
	}
	else
		return CVisiblePart::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CMoviePlayerPart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("currentTime", inPropertyName) == 0 )
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
		SetCurrentTime( theInterval );
	}
	else if( strcasecmp("started", inPropertyName) == 0 )
	{
		bool	theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetStarted( theHighlight );
	}
	else if( strcasecmp("controllerVisible", inPropertyName) == 0 )
	{
		bool	theHighlight = LEOGetValueAsBoolean( inValue, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetControllerVisible( theHighlight );
	}
	else if( strcasecmp("movie", inPropertyName) == 0 )
	{
		char		msgBuf[1024] = {0};
		const char* msgStr = LEOGetValueAsString( inValue, msgBuf, sizeof(msgBuf), inContext );
		if( !msgStr || (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		SetMediaPath( msgStr );
	}
	else
		return CVisiblePart::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


void	CMoviePlayerPart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
	printf( "%smediaPath = %s\n", indentStr, mMediaPath.c_str() );
	printf( "%scurrentTime = %lld\n", indentStr, GetCurrentTime() );
	printf( "%scontrollerVisible = %s\n", indentStr, (mControllerVisible ? "true" : "false") );
	printf( "%sstarted = %s\n", indentStr, (mStarted ? "true" : "false") );
}