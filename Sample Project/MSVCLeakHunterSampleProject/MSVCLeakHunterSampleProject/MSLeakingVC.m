//
//  MSLeakingVC.m
//  MSVCLeakHunterSampleProject
//
//  Created by Javier Soto on 10/20/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "MSLeakingVC.h"

@interface MSLeakingVC ()

@property (nonatomic, copy) dispatch_block_t block;

@end

@implementation MSLeakingVC

- (id)init
{
    if ((self = [super init]))
    {
        self.block = ^{
            NSLog(@"%@ this blocks references self, so it retains self, and self retains the block, so there's a retain cycle => the VC never deallocates.", self);
        };
    }

    return self;
}

@end
