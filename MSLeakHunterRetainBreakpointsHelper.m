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

#define PARENT_IMP(object, selector) (class_getMethodImplementation(class_getSuperclass([object class]), selector))

#define CALL_PARENT_IMP(object, selector) IMP i = PARENT_IMP(object, selector); i(object, selector);
#define CALL_AND_RETURN_PARENT_IMP(object, selector) IMP i = PARENT_IMP(object, selector); return i(object, selector);

#define ADD_NEW_METHOD(class, selector, function_pointer) class_addMethod(class, selector, (IMP)function_pointer, @encode(typeof(function_pointer)));

#pragma mark -

static id leak_retain(id self, SEL _cmd)
{
    DEBUGGER();

    CALL_AND_RETURN_PARENT_IMP(self, _cmd);
}

static void leak_release(id self, SEL _cmd)
{
    DEBUGGER();

    CALL_PARENT_IMP(self, _cmd);
}

static id leak_autorelease(id self, SEL _cmd)
{
    DEBUGGER();

    CALL_AND_RETURN_PARENT_IMP(self, _cmd);
}

static void leak_dealloc(id self, SEL _cmd)
{
    DEBUGGER();

    CALL_PARENT_IMP(self, _cmd);
}

#pragma mark -

#define kDynamicSubclassPrefix @"__MSLeak_"

static BOOL ms_objectIsOfDynamicSubclass(id object)
{
    return ([NSStringFromClass([object class]) rangeOfString:kDynamicSubclassPrefix].location != NSNotFound);
}

static __inline__ NSString *ms_dyanmicSubclassNameForObject(id object)
{
    return [NSString stringWithFormat:@"%@%@", kDynamicSubclassPrefix, NSStringFromClass([object class])];
}

void ms_stopOnMemoryManagementMethodsOfObject(id object)
{
    NSCParameterAssert(object);

    // Add a dynamic subclass for that object

    // 1. Does the subclass already exist?
    NSString *subclassName = ms_dyanmicSubclassNameForObject(object);
    Class subclass = NSClassFromString(subclassName);

    // 2. Doesn't exist. Creating the dynamic subclass
    if (!subclass)
    {
        subclass = objc_allocateClassPair([object class], [subclassName cStringUsingEncoding:NSASCIIStringEncoding], 0);

        NSCAssert(subclass, @"Could not create dynamic subclass for object %@", object);

        objc_registerClassPair(subclass);

        // Implement the memory management methods for that subclass
        ADD_NEW_METHOD(subclass, @selector(retain), leak_retain);
        ADD_NEW_METHOD(subclass, @selector(release), leak_release);
        ADD_NEW_METHOD(subclass, @selector(autorelease), leak_autorelease);
        ADD_NEW_METHOD(subclass, @selector(dealloc), leak_dealloc);
    }

    // 3. Make the object of that subclass
    object_setClass(object, subclass);
}

extern void ms_disableMemoryManagementMethodBreakpointsOnObject(id object)
{
    NSCParameterAssert(object);

    if (ms_objectIsOfDynamicSubclass(object))
    {
        // Simply set the class to the parent so that it doesn't have the modified method implementations anymore.
        object_setClass(object, class_getSuperclass([object class]));
        
        // Note: The dynamic subclass will still exist.
    }
}

#endif