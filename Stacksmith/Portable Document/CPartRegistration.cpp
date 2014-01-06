//
//  CPartRegistration.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CPartRegistration.h"
#include "CButtonPart.h"
#include "CFieldPart.h"
#include "CTimerPart.h"
#include "CMoviePlayerPart.h"
#include "CWebBrowserPart.h"


extern "C" void	CPartRegistrationRegisterAllPartTypes( void )
{
	static bool		sAlreadyDidThisOne = false;
	
	if( !sAlreadyDidThisOne )
	{
		Carlson::CPart::RegisterPartCreator( new Carlson::CPartCreator<Carlson::CButtonPart>( "button" ) );
		Carlson::CPart::RegisterPartCreator( new Carlson::CPartCreator<Carlson::CFieldPart>( "field" ) );
		Carlson::CPart::RegisterPartCreator( new Carlson::CPartCreator<Carlson::CTimerPart>( "timer" ) );
		Carlson::CPart::RegisterPartCreator( new Carlson::CPartCreator<Carlson::CMoviePlayerPart>( "moviePlayer" ) );
		Carlson::CPart::RegisterPartCreator( new Carlson::CPartCreator<Carlson::CWebBrowserPart>( "browser" ) );
		
		sAlreadyDidThisOne = true;
	}
}