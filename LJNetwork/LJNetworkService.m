//
//  LJNetworkService.m
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import "LJNetworkService.h"

@interface LJNetworkService()
@end

@implementation LJNetworkService

#pragma mark - Request Accessoies

- (void)addAccessory:(id<ServiceAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

#pragma mark
#pragma mark - 以下方法为子类重写方法
- (void)endServiceRequest
{

}

- (void)startServiceRequest
{

}

@end
