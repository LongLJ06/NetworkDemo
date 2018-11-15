//
//  LJBaseRequest.h
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RequestMethod){
    RequestMethodPost = 0,
    RequestMethodGet,
    RequestMethodHead,
    RequestMethodPut,
    RequestMethodDelete,
    RequestMethodPatch,
};

typedef NS_ENUM(NSInteger ,RequestSerializerType) {
    RequestSerializerTypeHTTP = 0,
    RequestSerializerTypeJSON,
};

typedef NS_ENUM(NSInteger ,ResponseSerializerType) {
    ResponseSerializerTypeHTTP = 0,
    ResponseSerializerTypeJSON,
};

typedef NS_ENUM(NSInteger, RequestPriority) {
    RequestPriorityDefault = 0,
    RequestPriorityLow,
    RequestPriorityHigh,
};

typedef NS_ENUM(NSInteger, RequestCachePolicy) {
    RequestCachePolicyIngoring = 0,
    RequestCachePolicyDefault,
};

@class LJBaseRequest;

@protocol RequestDelegate <NSObject>
@optional
- (void)requestFinished:(__kindof LJBaseRequest *)request;
- (void)requestFailed:(__kindof LJBaseRequest *)request;
/// 检测到服务器挂掉时的处理(不同App检测机制不一样,如果需要实现该功能需要子类实现- (BOOL)checkServiceFail)
- (void)requestMaintenanceSwing:(__kindof LJBaseRequest *)request;
@end

@protocol AFMultipartFormData;

typedef void (^ConstructingBlock)(id<AFMultipartFormData> formData);
typedef void (^UploadProgressBlock)(NSProgress *uploadProgress);
typedef void (^DownloadProgressBlock)(NSProgress *downloadProgressBlock);
typedef void (^RequestCompletionBlock)(__kindof LJBaseRequest *request);

@interface LJBaseRequest : NSObject
#pragma mark
#pragma mark - Request请求设置参数
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) RequestMethod requestMethod;
@property (nonatomic, assign) NSTimeInterval requestTimeOut;
@property (nonatomic, assign) RequestPriority requestPriority;
@property (nonatomic, assign) RequestSerializerType requestSerializerType;
@property (nonatomic, assign) ResponseSerializerType responseSerializerType;
/// 重新加载请求时是否采用缓存，默认忽略请求
@property (nonatomic, assign) RequestCachePolicy requestCachePolicy;
/// 用来上传的图片文件等流文件
@property (nonatomic, copy) ConstructingBlock constructingBodyBlock;
@property (nonatomic, copy) NSString *requestServiceURL;
@property (nonatomic, copy) NSDictionary *requestParamter;
@property (nonatomic, weak) id<RequestDelegate> delegate;
@property (nonatomic, copy) UploadProgressBlock uploadProgressBlock;
@property (nonatomic, copy) DownloadProgressBlock downloadProgressBlock;
@property (nonatomic, copy) RequestCompletionBlock successCompletionBlock;
@property (nonatomic, copy) RequestCompletionBlock failureCompletionBlock;
/// 服务器挂了的情况下的回调Block
@property (nonatomic, copy) RequestCompletionBlock serviceSwingCompletionBlock;

#pragma mark
#pragma mark - mock & cache
@property (nonatomic, copy) NSString *mockFilePath;

#pragma mark
#pragma mark - Request/Response 信息参数
@property (nonatomic, strong) NSError *responseError;
@property (nonatomic, strong) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
@property (nonatomic, assign, readonly) NSInteger responseStatusCode;
@property (nonatomic, copy, readonly) NSDictionary *responseHeaders;
@property (nonatomic, strong) id responseObject;
@property (nonatomic, assign, readonly) NSInteger errorCode;
@property (nonatomic, assign, readonly) NSURLSessionTaskState state;

- (BOOL)checkResult;
- (BOOL)checkReachability;
- (BOOL)checkServiceFail;
- (NSString *)requestURL;

#pragma mark
#pragma mark - 网络请求回调采用Block回调的方式
- (void)setSuccessCompletionBlock:(RequestCompletionBlock)success
           failureCompletionBlock:(RequestCompletionBlock)failure;

- (void)cleanRequestCompletionBlock;

#pragma mark
#pragma mark - 网络请求动作
/// 发起网络请求
- (void)start;
/// 取消网络请求
- (void)startWithSuccess:(nullable RequestCompletionBlock)success
                 failure:(nullable RequestCompletionBlock)failure;
- (void)stop;

#pragma mark
#pragma mark - 公用属性(子类可以自定义设置)
/// 设置HTTP授权的授权证书
- (NSArray *)requestAuthorizationHeaderFieldArray;
/// 设置报文头的字段
- (NSDictionary *)requestHeaderFieldValueDictionary;
/// 设置返回报文可以接收的格式
- (NSArray *)responseAcceptableContentTypeArray;
/// 设置是否使用蜂窝网络连接，默认是YES,置为NO表示只在WIFI模式下进行网络连接
- (BOOL)allowsCellularAccess;

#pragma mark
#pragma mark - 自定义请求报文组装和返回报文解析(子类可以覆盖)
/// 组装请求参数
- (NSDictionary *)assemblyRequestArguments;
/// 解析返回参数
- (void)parseResponseArguments;
@end
