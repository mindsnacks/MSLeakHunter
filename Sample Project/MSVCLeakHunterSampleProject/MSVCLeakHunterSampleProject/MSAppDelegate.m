//
//  MSAppDelegate.m
//  MSVCLeakHunterSampleProject
//
//  Created by Javier Soto on 10/20/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "MSAppDelegate.h"

#import "MSMenuVC.h"

#import "MSLeakHunter.h"
#import "MSViewControllerLeakHunter.h"
#import "MSViewLeakHunter.h"

@implementation MSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // installing the MSVCLeakHunter
#if MSLeakHunter_ENABLED
    [MSLeakHunter installLeakHunter:[MSViewControllerLeakHunter class]];
#endif

#if MSViewLeakHunter_ENABLED
    [MSLeakHunter installLeakHunter:[MSViewLeakHunter class]];
#endif
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    MSMenuVC *menuVC = [[MSMenuVC alloc] init];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:menuVC];
    self.window.rootViewController = navigationController;

    [self.window makeKeyAndVisible];

    return YES;
}
@end
