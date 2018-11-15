//
//  LJBatchService.h
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//
//  处理批量请求类
//  本类用来监控多个网络请求全部返回后然后回调给业务层
//  

#import "LJNetworkService.h"

@interface LJBatchService : LJNetworkService

@property (nonatomic, copy) NSArray<LJBaseRequest *> *requestList;

- (void)startBatchRequest;

- (void)endBatchRequest;

@end
