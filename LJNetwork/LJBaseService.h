//
//  LJBaseService.h
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//
//  处理单一请求类
//  

#import "LJNetworkService.h"

@class LJBaseService;

@interface LJBaseService : LJNetworkService

@property (nonatomic, strong) LJBaseRequest *request;

/**
 开始请求
 */
- (void)startBaseService;

/**
 结束请求
 注意:一般由 BaseService 的子类调用,在处理完所有的业务逻辑后进行调用，用来销毁这个网络请求服务
 */
- (void)endBaseService;

@end
