//
//  MSAbstractLeakHunter+Private.h
//  MindSnacks
//
//  Created by Javier Soto on 11/16/12.
//
//

#if MSLeakHunter_ENABLED

/**
 * @discussion leaks hunters must use these methods to implement their functionality.
 */
@interface MSLeakHunter ()

/**
 * @discussion call this method when an object got a notification that indicates that it will be deallocated soon.
 * @param objectReference should be a string that contains the class, the pointer, and a description of the object that leaked.
 */
+ (void)scheduleLeakNotificationWithObjectReferenceString:(NSString *)referenceString
                                               afterDelay:(NSTimeInterval)delay;

/**
 * @discussion call this method to cancel the schedule of a log for a leaked object
 * when it's finally deallocated.
 */
+ (void)cancelLeakNotificationWithObjectReferenceString:(NSString *)referenceString;

/**
 * @discussion you can call this method to swizzle the original method of the class you're trying to
 * catch leaks from, and replace it with a method in a category of that class.
 */
+ (void)swizzleMethod:(SEL)aOriginalMethod ofClass:(Class)class withMethod:(SEL)aNewMethod;

@end

#endif