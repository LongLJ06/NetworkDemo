//
//  LJNetworkPrivate.m
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import "LJNetworkPrivate.h"

@implementation LJNetworkPrivate

@end

@implementation LJNetworkService (Private)

- (void)dealAccessoriesWillStart {
    for (id<ServiceAccessory> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(serviceWillStart:)]) {
            [accessory serviceWillStart:self];
        }
    }
}

- (void)dealAccessoriesDidStop {
    for (id<ServiceAccessory> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(serviceDidStop:)]) {
            [accessory serviceDidStop:self];
        }
    }
}

@end
