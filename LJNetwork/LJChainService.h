//
//  LJChainService.h
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//
//  处理依赖请求类
//  本类依赖处理，重点处理等fromRequest请求返回后再去择机处理是否发起toRequest请求，如果toRequest的发起
//  需要从fromRequest的返回报文中获取某些参数的值映射到toRequest的请求参数中,则对chainKVParamter进行处理.
//  

#import "LJNetworkService.h"

@interface LJChainService : LJNetworkService

@property (nonatomic, strong) LJBaseRequest *fromRequest;
@property (nonatomic, strong) LJBaseRequest *toRequest;
//如果toRequest的发起，需要从fromRequest的返回报文中获取某些参数的值映射到toRequest的请求参数中.
//则把fromRequest的返回报文中需要的参数路径做为K,toRequest需要映射的请求参数路径做为V，组成KV键，组装到chainKVParamter参数中.
//chainKVParamter 参数为字符串字典
@property (nonatomic, copy) NSDictionary *chainKVParamter;

- (void)startChainRequest;

- (void)endChainRequest;

#pragma mark
#pragma mark - 以下方法为子类重写方法
- (BOOL)requestFinishedWithFromRequest;
- (BOOL)requestFailedWithFromRequest;

@end
