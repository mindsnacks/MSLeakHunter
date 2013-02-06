//
//  MSMenuVC.m
//  MSVCLeakHunterSampleProject
//
//  Created by Javier Soto on 10/20/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "MSMenuVC.h"

#import "MSOKVC.h"
#import "MSLeakingVC.h"

#import "MSLeakHunterRetainBreakpointsHelper.h"

@interface MSMenuVC ()

@end

@implementation MSMenuVC

- (void)pushViewControllerOfClass:(Class)class
{
    UIViewController *viewController = [[class alloc] init];

    ms_enableMemoryManagementMethodBreakpointsOnObject(viewController);

    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)onPushOKVC
{
    [self pushViewControllerOfClass:[MSOKVC class]];
}

- (IBAction)onPushLeakingVC
{
    [self pushViewControllerOfClass:[MSLeakingVC class]];
}

@end
