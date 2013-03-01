//
//  MSZombieHunter.m
//  MindSnacks
//
//  Created by Javier Soto on 3/1/13.
//
//

#import "MSZombieHunter.h"

#if MSZombieHunter_Available

#if __has_feature(objc_arc)
    #error MSZombieHunter is non-ARC only. Either turn off ARC for the project or use -fno-objc-arc flag \
           ARC explicitly disallows implementing retain/release/autorelease methods which must be implemented here.
#endif

#import "MSLeakHunter.h"
#import "MSLeakHunter+Private.h"

#import <objc/runtime.h>

@interface _MSZombie : NSProxy

@property (nonatomic, assign) Class originalClass;

@end

@interface NSObject (MSZombieHunter)

- (void)ms_zombieHunterDealloc;

@end

static BOOL _enabled = NO;

@implementation MSZombieHunter

+ (void)swizzleDealloc
{
    [MSLeakHunter swizzleMethod:@selector(dealloc)
                        ofClass:[NSObject class]
                     withMethod:@selector(ms_zombieHunterDealloc)];
}

+ (void)enable
{
    @synchronized(self)
    {
        if (!_enabled)
        {
            [self swizzleDealloc];

            _enabled = YES;
        }
    }
}

+ (void)disable
{
    @synchronized(self)
    {
        if (_enabled)
        {
            [self swizzleDealloc];

            _enabled = NO;
        }
    }
}

@end

@implementation NSObject (MSZombieHunter)

- (void)ms_zombieHunterDealloc
{
    Class currentClass = [self class];

    object_setClass(self, [_MSZombie class]);

    ((_MSZombie *)self).originalClass = currentClass;

}

@end

static char MSZombieOriginalClassKey;

#define MSZombieThrowMesssageSentException() [self throwMessageSentExceptionWithSelector:_cmd]

@implementation _MSZombie

- (void)throwMessageSentExceptionWithSelector:(SEL)selector
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"An Objective-C message (-[%@ %@]) was sent to a deallocated object (zombie) at address: %p",
                                           NSStringFromClass(self.originalClass),
                                           NSStringFromSelector(selector),
                                           self]
                                 userInfo:nil];
}

#pragma mark - NSProxy stuff

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.originalClass instancesRespondToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [self.originalClass instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [self throwMessageSentExceptionWithSelector:invocation.selector];
}

#pragma mark - NSObject protocol methods

// These methods won't trigger the proxy forwarding, so we must implement them to throw the exception too:

- (Class)class
{
    MSZombieThrowMesssageSentException();

    return nil;
}

- (BOOL)isEqual:(id)object
{
    MSZombieThrowMesssageSentException();

    return NO;
}

- (NSUInteger)hash
{
    MSZombieThrowMesssageSentException();

    return 0;
}

- (id)self
{
    MSZombieThrowMesssageSentException();

    return nil;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    MSZombieThrowMesssageSentException();

    return NO;
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    MSZombieThrowMesssageSentException();

    return NO;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    MSZombieThrowMesssageSentException();

    return NO;
}

- (BOOL)isProxy
{
    MSZombieThrowMesssageSentException();

    return NO;
}

- (id)retain
{
    MSZombieThrowMesssageSentException();

    return nil;
}

- (oneway void)release
{
    MSZombieThrowMesssageSentException();
}

- (id)autorelease
{
    MSZombieThrowMesssageSentException();

    return nil;
}

- (void)dealloc
{
    MSZombieThrowMesssageSentException();

    [super dealloc];
}

- (NSUInteger)retainCount
{
    MSZombieThrowMesssageSentException();

    return 0;
}

- (NSZone *)zone
{
    MSZombieThrowMesssageSentException();

    return nil;
}

- (NSString *)description
{
    MSZombieThrowMesssageSentException();

    return nil;
}

#pragma mark - Properties

- (Class)originalClass
{
    return objc_getAssociatedObject(self, &MSZombieOriginalClassKey);
}

- (void)setOriginalClass:(Class)originalClass
{
    objc_setAssociatedObject(self, &MSZombieOriginalClassKey, originalClass, OBJC_ASSOCIATION_ASSIGN);
}

@end

#endif