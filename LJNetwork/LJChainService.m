//
//  LJChainService.m
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import "LJChainService.h"
#import "LJNetworkPrivate.h"

@interface LJChainService()
@property (nonatomic, assign) BOOL isfromRequestBackSuccess;
@end

@implementation LJChainService

#pragma mark
#pragma mark - 发送网络请求
- (void)startChainRequest
{
    if (self.fromRequest != nil) {
        [self dealAccessoriesWillStart];
        [self startFromRequest];
    }
}

//发起fromRequest
- (void)startFromRequest
{
    if ([self.fromRequest checkReachability]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (weakSelf != nil) {
                NSLog(@"Chain From 请求地址:%@",weakSelf.fromRequest.requestServiceURL);
                weakSelf.isfromRequestBackSuccess = NO;
                [weakSelf.fromRequest start];
            }
        });
    }else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(serviceDidHandleWeakSingle:)]) {
                [self.delegate serviceDidHandleWeakSingle:self];
            }
        });
    }
}

//发起toRequest
- (void)startToRequest
{
    if (self.toRequest != nil) {
        __weak typeof(self) weakSelf = self;
        if ([self.toRequest checkReachability]) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if (weakSelf != nil) {
                    NSLog(@"Chain to 请求地址:%@",weakSelf.toRequest.requestServiceURL);
                    [weakSelf.toRequest start];
                }
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate != nil && [self.delegate respondsToSelector:@selector(serviceDidHandleWeakSingle:)]) {
                    [self.delegate serviceDidHandleWeakSingle:self];
                }
            });
        }
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


- (void)endChainRequest
{
    if (self.fromRequest != nil) {
        [self.fromRequest stop];
    }
    if (self.toRequest != nil) {
        [self.toRequest stop];
    }
    
    [self endChainRequest];
}

//fromRequest 到 toRequest参数映射
- (void)chainRequestParamterKVO
{
    if (self.chainKVParamter != nil && [self.chainKVParamter count] > 0) {
        NSArray *allKeys = [self.chainKVParamter allKeys];
        for (NSString *oneKey in allKeys) {
            if ([oneKey isEqualToString:@""]) {
                if (self.fromRequest.responseObject != nil &&
                    [self.fromRequest.responseObject isKindOfClass:[NSDictionary class]]) {
                    NSObject *oneToValue = [self.fromRequest.responseObject valueForKeyPath:oneKey];
                    if (oneToValue != nil) {
                        NSString *oneToParamter = [self.chainKVParamter objectForKey:oneKey];
                        [self.toRequest.requestParamter setValue:oneToValue forKey:oneToParamter];
                    }
                }
            }
        }
    }
}

#pragma mark
#pragma mark - 重写LJNetworkService类的方法
- (void)startServiceRequest
{
    if (self.isfromRequestBackSuccess) {
        //如果fromRequest 请求返回已经成功了则直接发起toRequest
        [self startToRequest];
    }else{
        [self startFromRequest];
    }
}

- (void)endServiceRequest
{
    [self endChainRequest];
}

#pragma mark
#pragma mark - 以下方法为子类重写方法
- (BOOL)requestFinishedWithFromRequest
{
    return YES;
}

- (BOOL)requestFailedWithFromRequest
{
    return NO;
}

#pragma mark
#pragma mark - RequestDelegate
- (void)requestFinished:(__kindof LJBaseRequest *)request
{
    if (request == self.fromRequest) {
        BOOL isContinue = [self requestFinishedWithFromRequest];
        if (isContinue) {
            [self chainRequestParamterKVO];
            self.isfromRequestBackSuccess = YES;
            [self startToRequest];
        }else{
            if ([self.delegate respondsToSelector:@selector(serviceFinished:)]) {
                [self.delegate serviceFinished:self];
            }
            [self endChainRequest];
        }
    }
    if (request == self.toRequest) {
        if ([self.delegate respondsToSelector:@selector(serviceFinished:)]) {
            [self.delegate serviceFinished:self];
        }
        [self endChainRequest];
    }
}

- (void)requestFailed:(__kindof LJBaseRequest *)request
{
    if (self.fromRequest == request) {
        BOOL isContinue = [self requestFailedWithFromRequest];
        if (isContinue) {
            [self startToRequest];
        }else{
            if ([self.delegate respondsToSelector:@selector(serviceFailed:)]) {
                [self.delegate serviceFailed:self];
            }
            [self endChainRequest];
        }
    }
    
    if (self.toRequest == request) {
        if ([self.delegate respondsToSelector:@selector(serviceFailed:)]) {
            [self.delegate serviceFailed:self];
        }
        [self endChainRequest];
    }
}

- (void)requestMaintenanceSwing:(__kindof LJBaseRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(serviceMaintenanceSwing:)]) {
        [self.delegate serviceMaintenanceSwing:self];
    }
    [self endChainRequest];
}

#pragma mark
#pragma mark - 该网络请求的描述，以网络请求地址作为唯一标识码，便于区分
- (NSString *)description
{
    NSString *description = [[NSString alloc] initWithFormat:@"%@_%@",self.fromRequest.requestServiceURL,
                                                                      self.toRequest.requestServiceURL];
    
    return description;
}

@end
