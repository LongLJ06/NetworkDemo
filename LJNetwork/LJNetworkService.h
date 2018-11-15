//
//  LJNetworkService.h
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LJBaseRequest.h"

static NSString * const kNotifation_service_end = @"ServiceEndNotifation";

/**
 基于request的状态进行扩展：如Toast及Loading等
 */
@protocol ServiceAccessory <NSObject>
@optional
- (void)serviceWillStart:(id)request;
- (void)serviceDidStop:(id)request;
@end

/**
 网络请求回调
 */
@protocol ServiceDelegate <NSObject>
@optional
/// 请求成功
- (void)serviceFinished:(id)request;
/// 请求失败
- (void)serviceFailed:(id)request;
/// 检测到服务器挂掉时的处理(不同App检测机制不一样,如果需要实现该功能需要子类实现- (BOOL)checkServiceFail)
- (void)serviceMaintenanceSwing:(id)request;
/// 网络信号不好
- (void)serviceDidHandleWeakSingle:(id)request;
@end

@interface LJNetworkService : NSObject <RequestDelegate>

@property (nonatomic, weak) id<ServiceDelegate> delegate;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) NSMutableArray<id<ServiceAccessory>> *requestAccessories;

- (void)addAccessory:(id<ServiceAccessory>)accessory;

#pragma mark
#pragma mark - 以下方法为子类重写方法(必须重写)
/**
 重新发起网络服务
 */
- (void)startServiceRequest;
/**
 结束网络服务
 */
- (void)endServiceRequest;

@end
