//
//  LJBatchService.m
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import "LJBatchService.h"
#import "LJNetworkPrivate.h"

@interface LJBatchService()
@property (nonatomic, assign) NSInteger batchFinishCount;
@property (nonatomic, strong) LJBaseRequest *failRequest;
@property (nonatomic, assign) BOOL isMainteance;
@end

@implementation LJBatchService

- (instancetype)init
{
    if (self = [super init]) {
        self.batchFinishCount = 0;
        self.failRequest = nil;
        self.isMainteance = NO;
    }
    return self;
}

#pragma mark
#pragma mark - 发送网络请求
- (void)startBatchRequest
{
    if (self.requestList != nil &&
        [self.requestList count] > 0) {
        __weak typeof(self) weakSelf = self;
        
        [self dealAccessoriesWillStart];
        
        for (LJBaseRequest *request in self.requestList) {
            if ([request checkReachability]) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (weakSelf != nil) {
                        NSLog(@"请求地址:%@",request.requestServiceURL);
                        [request start];
                    }
                });
                
            }else {
                //回调给UI层
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(serviceDidHandleWeakSingle:)]) {
                        [self.delegate serviceDidHandleWeakSingle:self];
                    }
                });
                [self endBatchRequest];
                break;
            }
        }
    }
}

#pragma mark
#pragma mark - RequestDelegate
- (void)requestFinished:(__kindof LJBaseRequest *)request
{
    self.batchFinishCount++;
    if (self.batchFinishCount == [self.requestList count]) {
        if ([self.delegate respondsToSelector:@selector(serviceFinished:)]) {
            [self.delegate serviceFinished:self];
        }
        [self endBatchRequest];
    }
}

- (void)requestFailed:(__kindof LJBaseRequest *)request
{
    //一旦检测到有网络请求失败，立刻中断全部网络请求
    if (self.failRequest == nil) {
        __weak typeof(self) weakSelf = self;
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            if (weakSelf != nil) {
                weakSelf.failRequest = request;
            }
        });
        
        if (self.failRequest) {
            if ([self.delegate respondsToSelector:@selector(serviceFailed:)]) {
                [self.delegate serviceFailed:self];
            }
            [self endBatchRequest];
        }
    }
}

- (void)requestMaintenanceSwing:(__kindof LJBaseRequest *)request
{
    //网络服务器挂掉导致批量网络请求服务中断后,只处理一次进行处理
    if (self.isMainteance == NO) {
        self.isMainteance = YES;
        
        if ([self.delegate respondsToSelector:@selector(serviceMaintenanceSwing:)]) {
            [self.delegate serviceMaintenanceSwing:self];
        }
        [self endBatchRequest];
    }
}

#pragma mark
#pragma mark - 网络请求服务中止
- (void)interruptService
{
    NSString *URLRecord = [[NSString alloc] initWithFormat:@"%ld",(unsigned long)self.tag];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifation_service_end
                                                        object:URLRecord];
    
    [self dealAccessoriesDidStop];
}

- (void)endBatchRequest
{
    for (LJBaseRequest *request in self.requestList) {
        [request stop];
    }
    
    [self interruptService];
}


#pragma mark
#pragma mark - 重写LJNetworkService类的方法
- (void)startServiceRequest
{
    [self startBatchRequest];
}

- (void)endServiceRequest
{
    [self endBatchRequest];
}

#pragma mark
#pragma mark - 该网络请求的描述，以网络请求地址作为唯一标识码，便于区分
- (NSString *)description
{
    NSMutableString *description = [[NSMutableString alloc] initWithCapacity:0];
    NSInteger index = 0;
    for (LJBaseRequest *request in self.requestList) {
        if (index == 0) {
            [description appendFormat:@"%@",request.requestServiceURL];
        }else{
            [description appendFormat:@"_%@",request.requestServiceURL];
        }
        index++;
    }
    return description;
}

@end
