//
//  ZKNetwork.h
//  ZKNetwork
//
//  Created by Zhou Kang on 2017/9/25.
//  Copyright © 2017年 Zhou Kang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface NSString (ZK_HTTP)

- (NSString *)zk_encode;
- (NSString *)zk_decode;
- (id)zk_object;

@end

// ------

@interface NSObject (ZK_HTTP)

- (NSString *)zk_json;

@end

// ------

@interface NSURL (ZK_HTTP)

- (NSString *)zk_interface;

@end

// ------

@interface ZKNetwork : NSObject

@end
