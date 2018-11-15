//
//  LJNetworkClient.m
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import "LJNetworkClient.h"
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

@interface LJNetworkClient()
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) NSMutableDictionary *requestsRecord;
@property (nonatomic, strong) NSLock *lock;
@end

@implementation LJNetworkClient

+ (LJNetworkClient *)shareLJNetworkClient
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _requestsRecord = [NSMutableDictionary dictionary];
        _manager = [AFHTTPSessionManager manager];
        _manager.completionQueue = dispatch_queue_create("com.longlj.LJNetworkClient.processing", DISPATCH_QUEUE_CONCURRENT);
        _lock = [[NSLock alloc] init];
    }
    return self;
}

#pragma mark
#pragma mark - requestSerializer/responseSerialzier
- (AFHTTPRequestSerializer *)requestSerializerForRequest:(LJBaseRequest *)request
{
    AFHTTPRequestSerializer *serializer = nil;
    if (request.requestSerializerType == RequestSerializerTypeHTTP) {
        serializer = [AFHTTPRequestSerializer serializer];
    }else if (request.requestSerializerType == RequestSerializerTypeJSON){
        serializer = [AFJSONRequestSerializer serializer];
    }
    serializer.timeoutInterval = request.requestTimeOut;
    serializer.allowsCellularAccess = [request allowsCellularAccess];
    
    NSArray *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil) {
        [serializer setAuthorizationHeaderFieldWithUsername:(NSString *)authorizationHeaderFieldArray.firstObject
                                                                   password:(NSString *)authorizationHeaderFieldArray.lastObject];
    }
    NSDictionary *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
    if (headerFieldValueDictionary != nil) {
        for (id httpHeaderField in headerFieldValueDictionary.allKeys) {
            id value = headerFieldValueDictionary[httpHeaderField];
            if ([httpHeaderField isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
                [serializer setValue:(NSString *)value forHTTPHeaderField:(NSString *)httpHeaderField];
            }
        }
    }
    
    return serializer;
}

- (AFHTTPResponseSerializer *)responseSerializerForRequest:(LJBaseRequest *)request
{
    AFHTTPResponseSerializer *serializer = nil;
    if (request.responseSerializerType == ResponseSerializerTypeHTTP) {
        serializer = [AFHTTPResponseSerializer serializer];
    }else if (request.responseSerializerType == ResponseSerializerTypeJSON){
        serializer = [AFJSONResponseSerializer serializer];
    }
    
    serializer.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
    NSArray *responseAcceptableContentTypes = [request responseAcceptableContentTypeArray];
    if (responseAcceptableContentTypes != nil) {
        serializer.acceptableContentTypes = [_manager.responseSerializer.acceptableContentTypes setByAddingObjectsFromArray:responseAcceptableContentTypes];
    }
    return serializer;
}

#pragma mark
#pragma mark - 外部接口
//发送网络请求
- (void)addRequest:(LJBaseRequest *)request
{
    if (request == nil) {
        return;
    }
    
    if (request.mockFilePath.length) {
        [self startWithMockFile:request];
    }else {
        [self startNetwork:request];
    }
}

//取消网络请求
- (void)cancelRequest:(LJBaseRequest *)request
{
    if (request != nil) {
        [request.requestTask cancel];
        request.delegate = nil;
        [request cleanRequestCompletionBlock];
        [self removeRequestFromRecord:request];
    }
}


#pragma mark
#pragma mark - 发送网络请求
- (void)startNetwork:(LJBaseRequest *)request
{
    NSError * __autoreleasing requestSerializationError = nil;
    
    request.requestTask = [self sessionTaskForNetworkRequest:request
                                                       error:&requestSerializationError];
    
    if (requestSerializationError) {
        //设置网络请求Task失败
        [self requestDidFailForRequest:request error:requestSerializationError];
        return;
    }
    
    if (request.requestTask != nil) {
        //设置优先级 IOS 8+才有用
        if (([[[UIDevice currentDevice] systemVersion] integerValue] >= 9) &&
            [request.requestTask respondsToSelector:@selector(priority)]) {
            switch (request.requestPriority) {
                case RequestPriorityHigh:
                    request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                    break;
                case RequestPriorityLow:
                    request.requestTask.priority = NSURLSessionTaskPriorityLow;
                    break;
                case RequestPriorityDefault:
                default:
                    request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                    break;
            }
        }
        
        [self addRequestToRecord:request];
        
        //启动网络请求
        [request.requestTask resume];
    }
}

- (NSURLSessionTask *)sessionTaskForNetworkRequest:(LJBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    RequestMethod method = request.requestMethod;
    ConstructingBlock constructingBlock = nil;//用来上传图片文件等流文件
    NSString *HTTPMode;
    
    switch (method) {
        case RequestMethodGet:
        {
            HTTPMode = @"GET";
            constructingBlock  = nil;
        }
            break;
        case RequestMethodPost:
        {
            HTTPMode = @"POST";
            constructingBlock  = request.constructingBodyBlock;
        }
            break;
        case RequestMethodHead:
        {
            HTTPMode = @"HEAD";
            constructingBlock  = request.constructingBodyBlock;
        }
            break;
        case RequestMethodPut:
        {
            HTTPMode = @"PUT";
            constructingBlock  = request.constructingBodyBlock;
        }
            break;
        case RequestMethodDelete:
        {
            HTTPMode = @"DELETE";
            constructingBlock  = request.constructingBodyBlock;
        }
            break;
        case RequestMethodPatch:
        {
            HTTPMode = @"PATCH";
            constructingBlock  = request.constructingBodyBlock;
        }
            break;
        default:
            break;
    }
    
    NSMutableURLRequest *URLRequest = nil;
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    AFHTTPResponseSerializer *responseSerializer = [self responseSerializerForRequest:request];
    
    NSString *requestURL;
    if ([request requestURL] != nil) {
        requestURL = [request requestURL];
    }else{
        requestURL = request.requestServiceURL;
    }
    
    id parameters = [request assemblyRequestArguments];
    
    if (constructingBlock) {
        URLRequest = [requestSerializer multipartFormRequestWithMethod:HTTPMode
                                                             URLString:requestURL
                                                            parameters:parameters
                                             constructingBodyWithBlock:constructingBlock
                                                                 error:error];
    } else {
        if (request.requestCachePolicy == RequestCachePolicyIngoring) {
            NSMutableURLRequest *policyURLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]
                                                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                             timeoutInterval:request.requestTimeOut];
            policyURLRequest.HTTPMethod = HTTPMode;
            URLRequest = [[requestSerializer requestBySerializingRequest:policyURLRequest
                                                          withParameters:parameters
                                                                   error:error] mutableCopy];
        }else{
            URLRequest = [requestSerializer requestWithMethod:HTTPMode
                                                    URLString:requestURL
                                                   parameters:parameters
                                                        error:error];
        }
    }
    
    _manager.responseSerializer = responseSerializer;
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:URLRequest
                              uploadProgress:request.uploadProgressBlock
                            downloadProgress:request.downloadProgressBlock
                           completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                               [self handleRequestResult:dataTask responseObject:responseObject error:error];
                           }];
    
    return dataTask;
}

#pragma mark
#pragma mark - 流程处理内部方法
- (NSString *)requestKey:(NSURLSessionTask *)sessionTask
{
    NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)[sessionTask taskIdentifier]];
    return key;
}

- (void)addRequestToRecord:(LJBaseRequest *)request
{
    if (request.requestTask != nil) {
        [_lock lock];
        NSString *key = [self requestKey:request.requestTask];
        _requestsRecord[key] = request;
        [_lock unlock];
    }
}

- (void)removeRequestFromRecord:(LJBaseRequest *)request
{
    [_lock lock];
    NSString *key = [self requestKey:request.requestTask];
    [_requestsRecord removeObjectForKey:key];
    [_lock unlock];
    NSLog(@"同时请求的数目 = %lu", (unsigned long)[_requestsRecord count]);
}

#pragma mark
#pragma mark - mock & cache
- (void)startWithMockFile:(LJBaseRequest *)request
{
    NSError *error;
    NSString *mockStr = [[NSString alloc] initWithContentsOfFile:request.mockFilePath encoding:NSUTF8StringEncoding error:&error];
    id mockObject = [NSJSONSerialization JSONObjectWithData:[mockStr dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:NSJSONReadingMutableContainers
                                                      error:&error];
    [self handleCacheResult:request responseObject:mockObject error:error];
}

#pragma mark
#pragma mark - 处理请求结果
- (void)handleCacheResult:(LJBaseRequest *)request responseObject:(id)responseObject error:(NSError *)error
{
    if (request != nil) {
        request.responseObject = responseObject;
        BOOL isSuccess = YES;
        NSError *requestError = nil;
        if (error) {
            requestError = error;
            isSuccess = NO;
        }else{
            isSuccess = [request checkResult];
        }
        
        BOOL isBroken = [request checkServiceFail];
        if (isBroken) {
            [self requestDidMaintenanceSwingForRequest:request];
        }else{
            if (isSuccess) {
                [self requestDidSuccessForRequest:request];
            }else{
                [self requestDidFailForRequest:request error:requestError];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeRequestFromRecord:request];
        });
    }
}
- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error
{
    [_lock lock];
    LJBaseRequest *request = [_requestsRecord objectForKey:[self requestKey:task]];
    [_lock unlock];
    
    [self handleCacheResult:request responseObject:responseObject error:error];
}

- (void)requestDidSuccessForRequest:(LJBaseRequest *)request
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(requestFinished:)]) {
            [request.delegate requestFinished:request];
        }
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
    });
}

- (void)requestDidFailForRequest:(LJBaseRequest *)request error:(NSError *)error
{
    request.responseError = error;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(requestFailed:)]) {
            [request.delegate requestFailed:request];
        }
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
    });
}

- (void)requestDidMaintenanceSwingForRequest:(LJBaseRequest *)request
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(requestMaintenanceSwing:)]) {
            [request.delegate requestMaintenanceSwing:request];
        }
        if (request.serviceSwingCompletionBlock) {
            request.serviceSwingCompletionBlock(request);
        }
    });
}

@end
