//
//  eleven_concurrent_queue.h
//  interconnectserver
//
//  Created by Uli Kusterer on 2014-11-29.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef CConcurrentQueue_h
#define CConcurrentQueue_h

#include "CSemaphore.h"
#include <mutex>
#include <functional>

namespace Carlson
{
	
	template< class E >
	class CConcurrentQueue
	{
	public:
		struct Element
		{
			Element() : mNext(NULL) {};
			explicit Element( const E& inPayload ) : mPayload(inPayload), mNext(NULL) {};
			
			E			mPayload;
			Element*	mNext;
		};
		
		CConcurrentQueue() : mHead(NULL), mTail(NULL) {}
		
		void	push( const E& inPayload )
		{
			Element*	newElem = new Element( inPayload );
			std::lock_guard<std::mutex>	lock(mHeadTailMutex);
			
			if( mTail )
			{
				mTail->mNext = newElem;
				mTail = newElem;
			}
			else
				mHead = mTail = newElem;
			
			mSemaphore.signal();
		}
		
		bool	pop( E& outPayload )
		{
			Element* 	poppedElem  = NULL;
			{
				std::lock_guard<std::mutex>	lock(mHeadTailMutex);
				poppedElem = mHead;
				
				if( mHead )
				{
					mHead = poppedElem->mNext;
					if( !mHead )
						mTail = NULL;
				}
			}

			if( poppedElem )
			{
				outPayload = poppedElem->mPayload;
				return true;
			}
			else
				return false;
		}
		
		void	wait( std::function<bool(const E&)> newItemCallback )
		{
			bool	keepGoing = true;
			while( keepGoing )
			{
				mSemaphore.wait();
				
				E	payload;
				if( pop(payload) )
					keepGoing = newItemCallback( payload );
			}
		}
		
		bool	empty()	{ std::lock_guard<std::mutex>	lock(mHeadTailMutex); return( mHead == NULL ); };
		
	protected:
		Element*		mHead;
		Element*		mTail;
		std::mutex		mHeadTailMutex;
		CSemaphore		mSemaphore;
	};
	
}


#endif /* CConcurrentQueue_h */
