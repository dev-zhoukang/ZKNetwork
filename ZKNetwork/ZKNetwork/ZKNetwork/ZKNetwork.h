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

@interface HTTPResponse : NSObject

@property (nonatomic, assign) BOOL isCache;
@property (nonatomic, strong) NSURL *requestURL;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) id payload;
@property (nonatomic, copy) NSString *hint;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) id extra;

@end

// ------

typedef void (^HttpTaskRequestHandler)(NSMutableURLRequest *request);
typedef void (^HttpTaskProgressHandler)(int64_t completedUnitCount, int64_t totalUnitCount);
typedef void (^HttpTaskCompleteHandler)(BOOL successed, HTTPResponse *response);

@interface ZKNetwork : NSObject

@end
