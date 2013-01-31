//
//  MSVCLeakHunter.m
//  MSAppKit
//
//  Created by Javier Soto on 10/16/12.
//
//

#import "MSViewControllerLeakHunter.h"

#import "MSLeakHunter+Private.h"

#if MSLeakHunter_ENABLED

#if MSVCLeakHunter_EnableUIViewControllerLog
    #define LOG_METHOD(NAME) NSLog(@"MSViewControllerLeakHunter -[%@ %@]", NSStringFromClass([self class]), NAME)
#else
    #define LOG_METHOD(NAME)
#endif

@interface UIViewController (MSViewControllerLeakHunter)

- (void)_msvcLeakHunter_viewDidAppear:(BOOL)animated;
- (void)_msvcLeakHunter_viewDidDisappear:(BOOL)animated;
- (void)_msvcLeakHunter_dealloc;

@end

@implementation MSViewControllerLeakHunter

+ (void)install
{
    Class class = [UIViewController class];

    [MSLeakHunter swizzleMethod:@selector(viewDidAppear:)
                        ofClass:class
                     withMethod:@selector(_msvcLeakHunter_viewDidAppear:)];

    [MSLeakHunter swizzleMethod:@selector(viewDidDisappear:)
                        ofClass:class
                     withMethod:@selector(_msvcLeakHunter_viewDidDisappear:)];

    [MSLeakHunter swizzleMethod:NSSelectorFromString(@"dealloc")
                        ofClass:class
                     withMethod:@selector(_msvcLeakHunter_dealloc)];
}

@end

@implementation UIViewController (MSViewControllerLeakHunter)

/**
 * @return a string that identifies the controller. This is used to be pased to `MSVCLeakHunter` without retaining the controller.
 */
- (NSString *)controllerReferenceString
{
    return [NSString stringWithFormat:@"VIEW CONTROLLER %@ <%p>", NSStringFromClass([self class]), self];
}

- (void)cancelLeakCheck
{
    [MSLeakHunter cancelLeakNotificationWithObjectReferenceString:[self controllerReferenceString]];
}

- (void)scheduleLeakCheck
{
    [MSLeakHunter scheduleLeakNotificationWithObjectReferenceString:[self controllerReferenceString]
                                                         afterDelay:kMSVCLeakHunterDisappearAndDeallocateMaxInterval];
}

#pragma mark - Alternative method implementations)

- (void)_msvcLeakHunter_viewDidAppear:(BOOL)animated
{
    LOG_METHOD(@"viewDidAppear:");

    [self cancelLeakCheck];

    // Call original implementation
    [self _msvcLeakHunter_viewDidAppear:animated];
}

- (void)_msvcLeakHunter_viewDidDisappear:(BOOL)animated
{
    LOG_METHOD(@"viewDidDisappear:");

    [self scheduleLeakCheck];

    // Call original implementation
    [self _msvcLeakHunter_viewDidDisappear:animated];
}

- (void)_msvcLeakHunter_dealloc
{
    LOG_METHOD(@"dealloc");

    [self cancelLeakCheck];

    // Call original implementation
    [self _msvcLeakHunter_dealloc];
}

@end

#endif