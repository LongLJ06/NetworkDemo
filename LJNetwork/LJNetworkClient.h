//
//  LJNetworkClient.h
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//
//  请求工具核心类
//  获取LJBaseRequest，然后发起/关闭请求

#import <Foundation/Foundation.h>
#import "LJBaseRequest.h"

@interface LJNetworkClient : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (LJNetworkClient *)shareLJNetworkClient;

- (void)addRequest:(LJBaseRequest *)request;
- (void)cancelRequest:(LJBaseRequest *)request;

@end
