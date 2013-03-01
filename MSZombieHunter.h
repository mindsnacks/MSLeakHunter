//
//  MSZombieHunter.h
//  MindSnacks
//
//  Created by Javier Soto on 3/1/13.
//
//

#import <Foundation/Foundation.h>

#define MSZombieHunter_Available (TARGET_IPHONE_SIMULATOR || (!TARGET_OS_IPHONE))

#if MSZombieHunter_Available

@interface MSZombieHunter : NSObject

+ (void)enable;
+ (void)disable;

@end

#endif