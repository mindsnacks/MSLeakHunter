//
//  MSLeakHunterRetainBreakpointsHelper.m
//  MindSnacks
//
//  Created by Javier Soto on 1/22/13.
//
//

#import "MSLeakHunterRetainBreakpointsHelper.h"

#if MSLeakHunter_ENABLED

#if __has_feature(objc_arc)
    #error MSLeakHunterRetainBreakpointsHelper is non-ARC only. Either turn off ARC for the project or use -fno-objc-arc flag \
           Because of how this class messes with retain and release calls, making this class support ARC is kind of tricky.
#endif

#import "MSLeakHunter+Private.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>

#pragma mark -

// Thanks to DCIntrospect for this trick: https://github.com/domesticcatsoftware/DCIntrospect

// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
static bool AmIBeingDebugged(void)
{
	int                 junk;
	int                 mib[4];
	struct kinfo_proc   info;
	size_t              size;

	// Initialize the flags so that, if sysctl fails for some bizarre
	// reason, we get a predictable result.

	info.kp_proc.p_flag = 0;

	// Initialize mib, which tells sysctl the info we want, in this case
	// we're looking for information about a specific process ID.

	mib[0] = CTL_KERN;
	mib[1] = KERN_PROC;
	mib[2] = KERN_PROC_PID;
	mib[3] = getpid();

	// Call sysctl.

	size = sizeof(info);
	junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
	assert(junk == 0);

	// We're being debugged if the P_TRACED flag is set.

	return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}

#if TARGET_CPU_ARM
#define DEBUGSTOP(signal) __asm__ __volatile__ ("mov r0, %0\nmov r1, %1\nmov r12, %2\nswi 128\n" : : "r"(getpid ()), "r"(signal), "r"(37) : "r12", "r0", "r1", "cc");
#define DEBUGGER do { int trapSignal = AmIBeingDebugged () ? SIGINT : SIGSTOP; DEBUGSTOP(trapSignal); if (trapSignal == SIGSTOP) { DEBUGSTOP (SIGINT); } } while (false);
#else
#define DEBUGGER() do { int trapSignal = AmIBeingDebugged () ? SIGINT : SIGSTOP; __asm__ __volatile__ ("pushl %0\npushl %1\npush $0\nmovl %2, %%eax\nint $0x80\nadd $12, %%esp" : : "g" (trapSignal), "g" (getpid ()), "n" (37) : "eax", "cc"); } while (false);
#endif

#define PARENT_IMP(object, selector) (class_getMethodImplementation(class_getSuperclass(object_getClass(object)), selector))

#define CALL_PARENT_IMP(object, selector) IMP i = PARENT_IMP(object, selector); i(object, selector);
#define CALL_AND_RETURN_PARENT_IMP(object, selector) IMP i = PARENT_IMP(object, selector); return i(object, selector);

#define ADD_NEW_METHOD(class, selector, function_pointer) class_addMethod(class, selector, (IMP)function_pointer, @encode(typeof(function_pointer)));

#pragma mark -

static id ms_retain(id self, SEL _cmd)
{
    DEBUGGER();

    CALL_AND_RETURN_PARENT_IMP(self, _cmd);
}

static void ms_release(id self, SEL _cmd)
{
    DEBUGGER();

    CALL_PARENT_IMP(self, _cmd);
}

static id ms_autorelease(id self, SEL _cmd)
{
    DEBUGGER();

    CALL_AND_RETURN_PARENT_IMP(self, _cmd);
}

static void ms_dealloc(id self, SEL _cmd)
{
    DEBUGGER();

    CALL_PARENT_IMP(self, _cmd);

    // We could remove the dynamic class with this undocumented method:
    // objc_disposeClassPair(object_getClass(self));
    // But we would probably need to do that only when this is the last living object of this class.
}

// We override class to make the dynamic subclass objects pose as the normal class
static Class ms_class(id self, SEL _cmd)
{
    Class thisClass = object_getClass(self);

    return class_getSuperclass(thisClass);
}

static BOOL _ms_hasBreakpointsEnabled(id self, SEL _cmd)
{
    return YES;
}

static SEL _ms_hasBreakpointsEnabledSelector(void)
{
    return NSSelectorFromString(@"_ms_hasBreakpointsEnabled");
}

#pragma mark -

#define kDynamicSubclassPrefix @"__MSLeak_"

static BOOL ms_objectIsOfDynamicSubclass(id object)
{
    if (!object)
    {
        return NO;
    }
    
    SEL selector = _ms_hasBreakpointsEnabledSelector();
 
    if (class_respondsToSelector(object_getClass(object), selector))
    {
        return ((BOOL(*)(id, SEL))objc_msgSend)((id)object, selector);
    }

    return NO;
}

static __inline__ NSString *ms_dynamicSubclassNameForObject(id object)
{
    return [NSString stringWithFormat:@"%@%@", kDynamicSubclassPrefix, NSStringFromClass([object class])];
}

void ms_enableMemoryManagementMethodBreakpointsOnObject(id object)
{
    NSCParameterAssert(object);
    
    // Add a dynamic subclass for that object

    // 1. Does the subclass already exist?
    NSString *subclassName = ms_dynamicSubclassNameForObject(object);
    Class subclass = NSClassFromString(subclassName);

    // 2. Doesn't exist. Creating the dynamic subclass
    if (!subclass)
    {
        Class parentClass = [object class];
        subclass = objc_allocateClassPair(parentClass, [subclassName cStringUsingEncoding:NSASCIIStringEncoding], 0);

        NSCAssert(subclass, @"Could not create dynamic subclass for object %@", object);

        objc_registerClassPair(subclass);

        // Implement the memory management methods for that subclass
        ADD_NEW_METHOD(subclass, @selector(retain), ms_retain);
        ADD_NEW_METHOD(subclass, @selector(release), ms_release);
        ADD_NEW_METHOD(subclass, @selector(autorelease), ms_autorelease);
        ADD_NEW_METHOD(subclass, @selector(dealloc), ms_dealloc);
        ADD_NEW_METHOD(subclass, @selector(class), ms_class);
        ADD_NEW_METHOD(subclass, _ms_hasBreakpointsEnabledSelector(), _ms_hasBreakpointsEnabled);
    }

    // 3. Make the object of that subclass
    object_setClass(object, subclass);
}

extern void ms_disableMemoryManagementMethodBreakpointsOnObject(id object)
{
    NSCParameterAssert(object);

    if (ms_objectIsOfDynamicSubclass(object))
    {
        // Simply set the class to the parent (the one posed as by -class) so that it doesn't have the modified method implementations
        object_setClass(object, [object class]);
        
        // Note: The dynamic subclass will still exist.
    }
}

#endif