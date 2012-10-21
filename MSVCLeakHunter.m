/*

 Copyright 2012 Javier Soto (javi@mindsnacks.com)

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MSVCLeakHunter.h"
#include <objc/runtime.h>

#if MSVCLeakHunter_ENABLED

#if MSVCLeakHunter_EnableUIViewControllerLog
    #define MSLOG_METHOD(NAME) NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NAME)
#else
    #define MSLOG_METHOD(NAME)
#endif

@interface UIViewController (MSVCLeakHunter)

- (void)_msvcLeakHunter_viewDidAppear:(BOOL)animated;
- (void)_msvcLeakHunter_viewDidDisappear:(BOOL)animated;
- (void)_msvcLeakHunter_dealloc;

@end

@implementation MSVCLeakHunter

/**
 * @discussion just an instance of the class to schedule the calls to `viewControllerLeakedWithReference:`
 */
+ (MSVCLeakHunter *)sharedInstance
{
    static MSVCLeakHunter *sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (void)viewControllerLeakedWithReference:(NSString *)viewControllerReference
{
    NSLog(@"[%@] POSSIBLE LEAK OF VIEW CONTROLLER %@", NSStringFromClass([self class]), viewControllerReference);
}

+ (void)install
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleUIViewControllerSelector:@selector(viewDidAppear:)
                                 withSelector:@selector(_msvcLeakHunter_viewDidAppear:)];

        [self swizzleUIViewControllerSelector:@selector(viewDidDisappear:)
                                 withSelector:@selector(_msvcLeakHunter_viewDidDisappear:)];

        [self swizzleUIViewControllerSelector:NSSelectorFromString(@"dealloc")
                                 withSelector:@selector(_msvcLeakHunter_dealloc)];
    });

}

#pragma mark - Swizzling

+ (void)swizzleUIViewControllerSelector:(SEL)originalSelector
                           withSelector:(SEL)newSelector
{
    Class class = [UIViewController class];

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method newMethod = class_getInstanceMethod(class, newSelector);

    method_exchangeImplementations(originalMethod, newMethod);
}

@end

@implementation UIViewController (MSVCLeakHunter)

/**
 * @return a string that identifies the controller. This is used to be pased to `MSVCLeakHunter` without retaining the controller.
 */
- (NSString *)controllerReferenceString
{
    return [NSString stringWithFormat:@"%@ <%p>", NSStringFromClass([self class]), self];
}

#pragma mark - Alternative method implementations

- (void)_msvcLeakHunter_viewDidAppear:(BOOL)animated
{
    MSLOG_METHOD(@"viewDidAppear:");

    [self cancelLeakCheck];

    // Call original implementation
    [self _msvcLeakHunter_viewDidAppear:animated];
}

- (void)_msvcLeakHunter_viewDidDisappear:(BOOL)animated
{
    MSLOG_METHOD(@"viewDidDisappear:");

    // Call original implementation
    [self _msvcLeakHunter_viewDidDisappear:animated];

    [self scheduleLeakCheck];
}

- (void)_msvcLeakHunter_dealloc
{
    MSLOG_METHOD(@"dealloc");

    [self cancelLeakCheck];

    // Call original implementation
    [self _msvcLeakHunter_dealloc];
}

- (void)cancelLeakCheck
{
    [NSObject cancelPreviousPerformRequestsWithTarget:[MSVCLeakHunter sharedInstance]
                                             selector:@selector(viewControllerLeakedWithReference:)
                                               object:[self controllerReferenceString]];
}

- (void)scheduleLeakCheck
{
    // Cancel previous ones just in case to avoid multiple calls.
    [self cancelLeakCheck];

    [[MSVCLeakHunter sharedInstance] performSelector:@selector(viewControllerLeakedWithReference:)
                                          withObject:[self controllerReferenceString]
                                          afterDelay:kMSVCLeakHunterDisappearAndDeallocateMaxInterval];
}

@end

#endif