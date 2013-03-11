//
//  MSViewLeakHunter.m
//  MindSnacks
//
//  Created by Javier Soto on 12/7/12.
//
//

#import "MSViewLeakHunter.h"

#import "MSLeakHunter+Private.h"

#if MSLeakHunter_ENABLED

#if MSViewLeakHunter_ENABLED

@interface UIView (MSViewLeakHunter)

- (void)_msviewLeakHunter_didMoveToWindow;
- (void)_msviewLeakHunter_dealloc;
@end

@implementation MSViewLeakHunter

+ (void)install
{
    Class class = [UIView class];

    [MSLeakHunter swizzleMethod:@selector(didMoveToWindow)
                        ofClass:class
                     withMethod:@selector(_msviewLeakHunter_didMoveToWindow)];

    [MSLeakHunter swizzleMethod:NSSelectorFromString(@"dealloc")
                        ofClass:class
                     withMethod:@selector(_msviewLeakHunter_dealloc)];
}

@end

@implementation UIView (MSViewLeakHunter)

/**
 * @return a string that identifies the controller. This is used to be pased to `MSVCLeakHunter` without retaining the controller.
 */
- (NSString *)viewReferenceString
{
    return [NSString stringWithFormat:@"VIEW %@ <%p>", NSStringFromClass([self class]), self];
}

- (void)cancelLeakCheck
{
    [MSLeakHunter cancelLeakNotificationWithObjectReferenceString:[self viewReferenceString]];
}

- (void)_msviewLeakHunter_didMoveToWindow
{
    if (!self.window)
    {
        [MSLeakHunter scheduleLeakNotificationWithObjectReferenceString:[self viewReferenceString]
                                                             afterDelay:kMSViewLeakHunterDisappearAndDeallocateMaxInterval];
    }
    else
    {
        [self cancelLeakCheck];
    }
}

- (void)_msviewLeakHunter_dealloc
{
    [self cancelLeakCheck];

    // Call original implementation
    [self _msviewLeakHunter_dealloc];
}

@end

#endif 

#endif
