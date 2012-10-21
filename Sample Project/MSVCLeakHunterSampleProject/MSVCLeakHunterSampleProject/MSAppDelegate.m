//
//  MSAppDelegate.m
//  MSVCLeakHunterSampleProject
//
//  Created by Javier Soto on 10/20/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "MSAppDelegate.h"

#import "MSMenuVC.h"

#import "MSVCLeakHunter.h"

@implementation MSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // installing the MSVCLeakHunter
    [MSVCLeakHunter install];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    MSMenuVC *menuVC = [[MSMenuVC alloc] init];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:menuVC];
    self.window.rootViewController = navigationController;

    [self.window makeKeyAndVisible];

    return YES;
}
@end
