//
//  LJBaseService.m
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import "LJBaseService.h"
#import "LJNetworkPrivate.h"

@implementation LJBaseService

#pragma mark
#pragma mark - 发起网络请求
- (void)startBaseService
{
    if (self.request != nil) {
        [self dealAccessoriesWillStart];
        
        if ([self.request checkReachability]) {
            __weak typeof(self) weakSelf = self;
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if (weakSelf != nil) {
                    NSLog(@"请求地址:%@",weakSelf.request.requestServiceURL);
                    [weakSelf.request start];
                }
            });
            
        }else {
            // 网络信号不好
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate != nil && [self.delegate respondsToSelector:@selector(serviceDidHandleWeakSingle:)]) {
                    [self.delegate serviceDidHandleWeakSingle:self];
                }
            });
            [self endBaseService];
        }
    }
}

#pragma mark
#pragma mark - 网络请求服务中止
- (void)endBaseService
{
    self.delegate = nil;
    [self.request stop];
    NSString *URLRecord = [[NSString alloc] initWithFormat:@"%@_%lu",self.request.requestServiceURL,
                                                                     (unsigned long)self.tag];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifation_service_end
                                                        object:URLRecord];
    
    [self dealAccessoriesDidStop];
}

#pragma mark
#pragma mark - 重写LJNetworkService类的方法
- (void)startServiceRequest
{
    [self startBaseService];
}

- (void)endServiceRequest
{
    [self endBaseService];
}

#pragma mark
#pragma mark - RequestDelegate
- (void)requestFinished:(__kindof LJBaseRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(serviceFinished:)]) {
        [self.delegate serviceFinished:self];
    }
    [self endBaseService];
}

- (void)requestFailed:(__kindof LJBaseRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(serviceFailed:)]) {
        [self.delegate serviceFailed:self];
    }
    [self endBaseService];
}

- (void)requestMaintenanceSwing:(__kindof LJBaseRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(serviceMaintenanceSwing:)]) {
        [self.delegate serviceMaintenanceSwing:self];
    }
    [self endBaseService];
}

@end

