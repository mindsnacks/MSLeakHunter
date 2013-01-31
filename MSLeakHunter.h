//
//  MSLeakHunter.h
//  MindSnacks
//
//  Created by Javier Soto on 11/16/12.
//
//

#import <Foundation/Foundation.h>

/**
 * @discussion this is a general on/off switch for MSLeakHunter.
 * Classes that implement the `MSLeakHunter` protocol should wrap all their code between #if and #endif
 * statements so that none of their code is compiled if this is turned off.
 */
#define MSLeakHunter_ENABLED TARGET_IPHONE_SIMULATOR

#if MSLeakHunter_ENABLED

@protocol MSLeakHunter <NSObject>

/**
 * @discussion leak hunters should implement the appropiate method swizzling in this method.
 */
+ (void)install;

@end

@interface MSLeakHunter : NSObject

+ (void)installLeakHunter:(Class<MSLeakHunter>)leakHunter;

@end

#endif