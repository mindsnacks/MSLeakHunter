//
//  MSLeakHunter.m
//  MindSnacks
//
//  Created by Javier Soto on 11/16/12.
//
//

#import "MSLeakHunter.h"

#import <objc/runtime.h>

#if MSLeakHunter_ENABLED

// This is hacky and relies on a "deprecated" (althought the documentation isn't updated saying so) method. What's the alternative?
static inline void ms_dispatch_sync_safe(dispatch_queue_t dispatchQueue, dispatch_block_t block)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == dispatchQueue)
    {
#pragma clang diagnostic pop
        block();
    }
    else
    {
        dispatch_sync(dispatchQueue, block);
    }
}

/**
 * @discussion this queue lets us ensure that the calls to `performSector:...` and `cancelPrevious...`
 * are always made in the same run loop.
 */
static dispatch_queue_t _msLeakHunterQueue = nil;

@implementation MSLeakHunter

+ (void)initialize
{
    if ([self class] == [MSLeakHunter class])
    {
        _msLeakHunterQueue = dispatch_queue_create("com.mindsnacks.leakhunter", DISPATCH_QUEUE_SERIAL);
    }
}

+ (MSLeakHunter *)sharedInstance
{
    static MSLeakHunter *sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MSLeakHunter alloc] init];
    });

    return sharedInstance;
}

- (void)objectLeakedWithReference:(NSString *)objectReference
{
    NSLog(@"[%@] POSSIBLE LEAK OF %@", NSStringFromClass([self class]), objectReference);
}

+ (void)installLeakHunter:(Class<MSLeakHunter>)leakHunter
{
    [leakHunter install];
}

#pragma mark - Swizzling

+ (void)swizzleMethod:(SEL)aOriginalMethod
              ofClass:(Class)class
           withMethod:(SEL)aNewMethod
{
    Method oldMethod = class_getInstanceMethod(class, aOriginalMethod);
    Method newMethod = class_getInstanceMethod(class, aNewMethod);

    method_exchangeImplementations(oldMethod, newMethod);
}

#pragma mark - Checking

+ (void)scheduleLeakNotificationWithObjectReferenceString:(NSString *)referenceString
                                               afterDelay:(NSTimeInterval)delay
{
    // Ensure we always run these methods on the same thread
    ms_dispatch_sync_safe(_msLeakHunterQueue, ^{
        // Cancel previous ones just in case to avoid multiple calls.
        [self cancelLeakNotificationWithObjectReferenceString:referenceString];

        [[self sharedInstance] performSelector:@selector(objectLeakedWithReference:)
                                    withObject:referenceString
                                    afterDelay:delay];
    });
}

+ (void)cancelLeakNotificationWithObjectReferenceString:(NSString *)referenceString
{
    ms_dispatch_sync_safe(_msLeakHunterQueue, ^{
        [self cancelPreviousPerformRequestsWithTarget:[self sharedInstance]
                                             selector:@selector(objectLeakedWithReference:)
                                               object:referenceString];
    });
}

@end

#endif