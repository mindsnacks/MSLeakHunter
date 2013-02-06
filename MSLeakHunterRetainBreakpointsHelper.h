//
//  MSLeakHunterRetainBreakpointsHelper.h
//  MindSnacks
//
//  Created by Javier Soto on 1/22/13.
//
//

#import "MSLeakHunter.h"

#if MSLeakHunter_ENABLED

/**
 * @discussion installs a series of handles so that subsequent calls to the methods listed below result
 * in the debugger stopping with a brekapoint so that you can trace the calls in the stack to those methods.
 * @ methods:
 * - retain
 * - release
 * - autorelease
 * - dealloc
 *
 * @note these methods are not thread safe and should be called from the main thread.
 */
extern void ms_enableMemoryManagementMethodBreakpointsOnObject(id object);

/**
 * @discussion undoes what `ms_enableMemoryManagementMethodBreakpointsOnObject()` did, so the object will no longer
 * make the debugger stop when those methods are called on it.
 */
extern void ms_disableMemoryManagementMethodBreakpointsOnObject(id object);

#endif