//
//  ZKNetwork.m
//  ZKNetwork
//
//  Created by Zhou Kang on 2017/9/25.
//  Copyright © 2017年 Zhou Kang. All rights reserved.
//

#import "ZKNetwork.h"

@implementation NSString (ZK_HTTP)

- (NSString *)zk_encode {
    NSString *outputStr = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)self,
                                                              (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                              NULL,
                                                              kCFStringEncodingUTF8));
    outputStr = [outputStr stringByReplacingOccurrencesOfString:@"<null>" withString:@""];
    return outputStr;
}

- (NSString *)zk_decode {
    NSString *outputStr = (NSString *)
    CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                              kCFAllocatorDefault,
                                                                              (__bridge CFStringRef)self,
                                                                              CFSTR(""),
                                                                              kCFStringEncodingUTF8));
    return outputStr;
}

- (id)zk_object {
    id object = nil;
    @try {
        NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
        object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"%s [Line %d] JSON 字符串转换成对象出错-->\n%@",__PRETTY_FUNCTION__, __LINE__, exception);
    }
    @finally {
    }
    return object;
}

@end

// ------

@implementation NSObject (ZK_HTTP)

- (NSString *)zk_json {
    NSString *jsonStr = @"";
    @try {
        if ([NSJSONSerialization isValidJSONObject:self]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:nil];
            jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        else {
            NSLog(@"data was not a proper JSON object, check All objects are NSString, NSNumber, NSArray, NSDictionary, or NSNull !!!!!");
        }
    }
    @catch (NSException *exception) {
        
    }
    return jsonStr;
}

@end

// ------

@implementation NSURL (ZK_HTTP)

- (NSString *)zk_interface {
    if(self.port){
        return [NSString stringWithFormat:@"%@://%@:%@%@", self.scheme, self.host, self.port, self.path];
    }
    return [NSString stringWithFormat:@"%@://%@%@", self.scheme, self.host, self.path];
}

@end

// ------

@implementation HTTPResponse

@end

// ------

@interface ZKJSONResponseSerializer : AFJSONResponseSerializer
@end

@implementation ZKJSONResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    id responseObj = [super responseObjectForResponse:response data:data error:error];
    if (!responseObj && *error && data && [data length]) {
        responseObj = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return responseObj;
}

@end

// ------

@implementation ZKNetwork

@end
