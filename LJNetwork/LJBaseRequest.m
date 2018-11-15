//
//  LJBaseRequest.m
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import "LJBaseRequest.h"
#import "LJNetworkClient.h"
#import "Reachability.h"

@implementation LJBaseRequest

- (instancetype)init
{
    if (self = [super init]) {
        self.requestSerializerType = RequestSerializerTypeHTTP;
        self.responseSerializerType = ResponseSerializerTypeJSON;
        self.requestMethod = RequestMethodPost;
        self.requestPriority = RequestPriorityDefault;
        self.requestCachePolicy = RequestCachePolicyIngoring;
    }
    return self;
}

#pragma mark
#pragma mark - Set/Get
- (NSInteger)responseStatusCode
{
    return self.response.statusCode;
}

- (NSHTTPURLResponse *)response
{
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSInteger)errorCode
{
    if (self.responseError != nil) {
        return self.responseError.code;
    }
    return self.responseStatusCode;
}

- (NSDictionary *)responseHeaders
{
    return self.response.allHeaderFields;
}

- (NSURLSessionTaskState)state
{
    return self.requestTask.state;
}

#pragma mark
#pragma mark - 通用接口
- (BOOL)checkResult
{
    NSInteger stateCode = self.responseStatusCode;
    if (stateCode >= 200 && stateCode <=299) {
        return YES;
    }else{
        return NO;
    }
    return YES;

}

- (BOOL)checkReachability
{
    BOOL isConnect = YES;
    NSString *requestURL;
    if ([self requestURL] != nil) {
        requestURL = [self requestURL];
    }else{
        requestURL = self.requestServiceURL;
    }
    
    if (requestURL != nil && ![requestURL isEqualToString:@""]) {
        NSArray *seperURLAry = [requestURL componentsSeparatedByString:@"/"];
        if ([seperURLAry count] >= 3) {
            NSString *hostURLName = [seperURLAry objectAtIndex:2];
            Reachability *reachability = [Reachability reachabilityWithHostName:hostURLName];
            if ([reachability currentReachabilityStatus] == NotReachable) {
                isConnect = NO;
            }
        }
    }else{
        isConnect = NO;
    }
    
    return isConnect;
}

//检查服务器是否故障(需要子类覆盖实现)
- (BOOL)checkServiceFail
{
    return NO;
}

- (NSString *)requestURL
{
    return nil;
}

#pragma mark
#pragma mark - 网络请求回调采用Block回调的方式
- (void)setSuccessCompletionBlock:(RequestCompletionBlock)success failureCompletionBlock:(RequestCompletionBlock)failure
{
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)cleanRequestCompletionBlock
{
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

#pragma mark
#pragma mark - 网络请求动作
- (void)start
{
    LJNetworkClient *client = [LJNetworkClient shareLJNetworkClient];
    [client addRequest:self];
}

- (void)startWithSuccess:(RequestCompletionBlock)success
                 failure:(RequestCompletionBlock)failure
{
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
    [self start];
}

- (void)stop
{
    LJNetworkClient *client = [LJNetworkClient shareLJNetworkClient];
    [client cancelRequest:self];
}

#pragma mark
#pragma mark - 公用属性(子类可以自定义设置)
- (NSArray *)requestAuthorizationHeaderFieldArray
{
    return nil;
}

- (NSDictionary *)requestHeaderFieldValueDictionary
{
    return nil;
}

- (NSArray *)responseAcceptableContentTypeArray
{
    return nil;
}

- (BOOL)allowsCellularAccess
{
    return YES;
}

#pragma mark
#pragma mark - 自定义请求报文组装和返回报文解析(子类可以覆盖)
- (NSDictionary *)assemblyRequestArguments
{
    return self.requestParamter;
}

- (void)parseResponseArguments
{
    
}

@end
