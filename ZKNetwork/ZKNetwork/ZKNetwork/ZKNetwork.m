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

- (NSURLSessionDataTask *)getRequestToURL:(NSString *)URL
                                   params:(NSDictionary *)params
                                 complete:(HttpTaskCompleteHandler)complete {
    return [self getRequestToURL:URL params:params request:nil complete:complete];
}

- (NSURLSessionDataTask *)getRequestToURL:(NSString *)URL
                                   params:(NSDictionary *)params
                                  request:(HttpTaskRequestHandler)requestHandle
                                 complete:(HttpTaskCompleteHandler)completeHandle {
    return [self requestToURL:URL method:@"GET" useCache:false params:params request:requestHandle complete:completeHandle];
}

- (NSURLSessionDataTask *)requestToURL:(NSString *)URL
                                method:(NSString *)method
                              useCache:(BOOL)useCache
                                params:(NSDictionary *)params
                               request:(HttpTaskRequestHandler)requestHandle
                              complete:(HttpTaskCompleteHandler)completeHandle {
    return nil;
}

- (NSMutableURLRequest *)requestWithURL:(NSString *)URL
                                 method:(NSString *)method
                               useCache:(BOOL)useCache
                                 params:(NSDictionary *)params {
#if DEBUG
    NSDictionary *proxySettings = (__bridge NSDictionary *)(CFNetworkCopySystemProxySettings());
    CFURLRef URLRef = (__bridge CFURLRef _Nonnull)([NSURL URLWithString:@"https://www.baidu.com"]);
    NSArray *proxies = (__bridge NSArray *)(CFNetworkCopyProxiesForURL(URLRef, (__bridge CFDictionaryRef _Nonnull)(proxySettings)));
    NSDictionary *settings = proxies[0];
    BOOL noneProxy = [settings[(NSString *)kCFProxyTypeNone] isEqualToString:@"kCFProxyTypeNone"];
    if (!noneProxy) {
        NSString *hostName = [settings objectForKey:(NSString *)kCFProxyHostNameKey];
        NSString *portNumber = [settings objectForKey:(NSString *)kCFProxyPortNumberKey];
        if (hostName || portNumber) {
            NSLog(@"检测到设备已设置了代理 --> %@:%@", hostName, portNumber);
        }
        else {
            NSLog(@"检测到设备已设置了代理 --> %@",[settings objectForKey:(NSString *)kCFProxyAutoConfigurationURLKey]);
        }
    }
#endif
    NSMutableDictionary *requestParams = [params mutableCopy];
    return nil;
}

+ (NSMutableDictionary *)fillRequestBodyWithParams:(NSDictionary *)params {
    NSMutableDictionary *requestBody = params ? [params mutableCopy] : [NSMutableArray array];
    double timeDiff = 0; // 本机与服务器时间差值
    double localTime = [[NSDate date] timeIntervalSince1970] * 1000;
    NSString *sysTime = [NSString stringWithFormat:@"%.0f", (localTime + timeDiff)];
    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    requestBody[@"time"] = sysTime;
    requestBody[@"platform"] = @"1";
    requestBody[@"version"] = bundleVersion;
    requestBody[@"distributor"] = @"app_store";
    // requestBody[@"device_id"] = [[UIDevice currentDevice] udid];
    // if (_loginUser.uid.length) {
    //     requestBody[@"login_uid"] = _loginUser.uid;
    // }
    // if (_loginUser.session_key.length) {
    //     requestBody[@"session_key"] = _loginUser.session_key;
    // }
    
    return requestBody;
}

@end
