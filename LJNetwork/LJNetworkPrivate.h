//
//  LJNetworkPrivate.h
//  NetworkDemo
//
//  Created by long on 2017/3/30.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LJNetworkService.h"

@interface LJNetworkPrivate : NSObject

@end

@interface LJNetworkService (Private)

- (void)dealAccessoriesWillStart;
- (void)dealAccessoriesDidStop;

@end
