//
//  CButtonPartIOS.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 20.06.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CButtonPartIOS_hpp
#define CButtonPartIOS_hpp

#include "CButtonPart.h"
#include "CIOSPartBase.h"


@class WILDButtonActionTarget;


namespace Carlson
{
	
	class CButtonPartIOS : public CButtonPart, public CIOSPartBase
	{
	public:
		CButtonPartIOS( CLayer *inOwner ) : CButtonPart(inOwner) {}
		
		virtual UIView	*	GetView() override { return mView; };
		virtual void		CreateViewIn( UIView * inParentView ) override;
		virtual void		DestroyView() override;
		
		virtual void		SetHighlight( bool inState ) override;
	
	protected:
		UIControl				*	mView = nil;
		WILDButtonActionTarget	*	mActionTarget = nil;
	};
	
} /* namespace Carlson */

#endif /* CButtonPartIOS_hpp */
