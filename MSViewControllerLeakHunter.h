//
//  MSViewControllerLeakHunter.h
//  MSAppKit
//
//  Created by Javier Soto on 10/16/12.
//
//

#import "MSLeakHunter.h"

#if MSLeakHunter_ENABLED

/**
 * @discussion if a view controller hasn't been deallocated after this time after it disappeared from screen, it's considered "pottentially leaked"
 */
#define kMSVCLeakHunterDisappearAndDeallocateMaxInterval 30.0f

/**
 * @discussion this makes MSVCLeakHunter print logs when view controllers appear, disappear and are deallocated.
 */
#define MSVCLeakHunter_EnableUIViewControllerLog 0

/**
 * @discussion when installed, it's going to print messages in the log whenever a view controller is not deallocated after a while of disappearing from screen.
 */
@interface MSViewControllerLeakHunter : NSObject <MSLeakHunter>

@end

#endif