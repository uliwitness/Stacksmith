//
//  eleven_semaphore.h
//  interconnectserver
//
//  Created by Uli Kusterer on 2014-11-29.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef CSemaphore_h
#define CSemaphore_h

#include <mutex>
#include <condition_variable>


namespace Carlson
{

	class  CSemaphore
	{  
	public:
		CSemaphore() : mCount(0) {}
		
		void reset()
		{
			std::unique_lock<std::mutex> lock(mCountLock);
			mCount = 0;
		}
		
		void signal()
		{
			std::unique_lock<std::mutex> lock(mCountLock);
			
			++mCount;
			
			mCondition.notify_one();
		}
		
		void wait()
		{
			std::unique_lock<std::mutex> lock(mCountLock);
			
			while( !mCount )
				mCondition.wait(lock);
			
			--mCount;
		}
		
	protected:
		std::mutex				mCountLock;
		std::condition_variable	mCondition;
		unsigned int			mCount;
	};
 
 
}

#endif /* CSemaphore_h */
