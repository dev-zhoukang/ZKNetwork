//
//  NSObject+ZK_JSON.m
//  ZKNetwork
//
//  Created by Zhou Kang on 2017/9/26.
//  Copyright © 2017年 Zhou Kang. All rights reserved.
//

#import "NSObject+ZK_JSON.h"

@implementation NSObject (ZK_JSON)

//去掉 json 中的多余的 null
- (instancetype)zk_cleanNull {
    NSError *error;
    if (self == (id)[NSNull null]) {
        return [[NSObject alloc] init];
    }
    
    id jsonObject;
    if ([self isKindOfClass:[NSData class]]) {
        jsonObject = [NSJSONSerialization JSONObjectWithData:(NSData *)self options:kNilOptions error:&error];
    }
    else {
        jsonObject = self;
    }
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [jsonObject mutableCopy];
        for (NSInteger i = array.count - 1; i >= 0; i--) {
            id a = array[i];
            if (a == (id)[NSNull null]) {
                [array removeObjectAtIndex:i];
            }
            else {
                array[i] = [a zk_cleanNull];
            }
        }
        return array;
    }
    else if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dictionary = [jsonObject mutableCopy];
        for (NSString *key in[dictionary allKeys]) {
            id d = dictionary[key];
            if (d == (id)[NSNull null]) {
                dictionary[key] = @"";
            }
            else {
                dictionary[key] = [d zk_cleanNull];
            }
        }
        return dictionary;
    }
    else {
        return jsonObject;
    }
}

@end
