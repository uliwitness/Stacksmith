//
//  CIOSPartBase.h
//  Stacksmith
//
//  Created by Uli Kusterer on 20.06.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CIOSPartBase_hpp
#define CIOSPartBase_hpp

#import <UIKit/UIKit.h>

namespace Carlson
{

	class CIOSPartBase
	{
	public:
		virtual UIView* GetView() { return nil; }
		
		virtual void	CreateViewIn( UIView * inParentView ) = 0;
		virtual void	DestroyView() = 0;
		
	protected:
		virtual ~CIOSPartBase() {}
	};
	
} /* namespace Carlson */

#endif /* CIOSPartBase_h */
