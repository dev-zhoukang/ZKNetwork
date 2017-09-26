//
//  ZKNetwork.m
//  ZKNetwork
//
//  Created by Zhou Kang on 2017/9/25.
//  Copyright © 2017年 Zhou Kang. All rights reserved.
//

#import "ZKNetwork.h"
#import "NSObject+ZK_JSON.h"

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

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    ZKJSONResponseSerializer *responseSerializer = [ZKJSONResponseSerializer serializer];
    responseSerializer.acceptableContentTypes = nil;
    responseSerializer.removesKeysWithNullValues = false;
    NSURL *baseURL = [NSURL URLWithString:INIT_DOMAIN];
    
    _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    _sessionManager.responseSerializer = responseSerializer;
    
    [_sessionManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"Network Status change: %@", AFStringFromNetworkReachabilityStatus(status));
    }];
    [_sessionManager.reachabilityManager startMonitoring];
    
    NSURLCache *URLCache = [NSURLCache sharedURLCache];
    [URLCache setMemoryCapacity:50 * 1024 * 1024];
    [URLCache setDiskCapacity:200 * 1024 * 1024];
    [NSURLCache setSharedURLCache:URLCache];
}

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
                              complete:(HttpTaskCompleteHandler)completeHandler {
    NSMutableURLRequest *request = [self requestWithURL:URL method:method useCache:useCache params:params];
    
    !requestHandle ?: requestHandle(request);
    
    NSURLSessionDataTask *dataTask = nil;
    
    void (^AFCompletionHandler)(NSURLResponse *, id, NSError *) = ^(NSURLResponse *response, id responseObject, NSError *error) {
        [self logRequestInfoWithRequest:request responseObject:responseObject];
        
        HTTPResponse *resObj = [[HTTPResponse alloc] init];
        resObj.requestURL = request.URL;
        resObj.params = [request.accessibilityValue zk_object]?:params;
        resObj.error = error;
        
        if (error) {
            NSLog(@"%@ error :  %@",[method lowercaseString],error);
            !completeHandler ?: completeHandler(false, resObj);
            [self handleHttpResponseError:error useCache:useCache];
        }
        else{
            [self takesTimeWithRequest:request flag:@"接口"];
            
            //已在cache中完成自带表情的解析
            [self dictionaryWithData:responseObject handleEmoji:!useCache complete:^(NSDictionary *object) {
                resObj.payload = object;
                
                NSString *flagStr = response.accessibilityValue;
                if (flagStr && [flagStr isEqualToString:@"cache_data"]) {
                    resObj.isCache = YES;
                }
                
                [self handleResponse:resObj complete:completeHandler];
            }];
        }
    };
    
    if (useCache) {
        
    }
    else {
        dataTask = [_sessionManager dataTaskWithRequest:request completionHandler:AFCompletionHandler];
    }
    return nil;
}

- (void)dictionaryWithData:(id)data
               handleEmoji:(BOOL)handleEmoji
                  complete:(void (^)(NSDictionary *object))complete {
    __block NSDictionary *object = data;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //        NSDate *date = [NSDate date];
        if ([data isKindOfClass:[NSData class]]) {
            object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        }
        if ([data isKindOfClass:[NSString class]]) {
            object = [data zk_object];
        }
        object = [object zk_cleanNull];
        
        //TODO: 暂时还用不到emoji解析
        //        if(handleEmoji){
        //            object = [[[object json] stringByReplacingEmojiCheatCodesWithUnicode] object];
        //            DLOG(@"解析网络数据耗时 %.4f 秒",[[NSDate date] timeIntervalSinceDate:date]);
        //        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            complete ? complete(object?:data) : nil;
        });
    });
}

- (void)logRequestInfoWithRequest:(NSURLRequest *)request responseObject:(id)responseObject {
    if ([request.HTTPMethod isEqualToString:@"GET"]) {
        NSLog(@"GET request url:  %@  ",[request.URL.absoluteString zk_decode]);
    } else {
        NSLog(@"%@ request url:  %@  \npost params:  %@\n",request.HTTPMethod,[request.URL.absoluteString zk_decode],request.accessibilityValue);
    }
    NSLog(@"%@ responseObject:  %@",request.HTTPMethod, responseObject);
}

//打印每个接口的响应时间
- (void)takesTimeWithRequest:(NSURLRequest *)request flag:(NSString *)flag {
    if (request && request.accessibilityHint) {
        NSURL *url = request.URL;
        
        double beginTime = [request.accessibilityHint doubleValue];
        double localTime = [[NSDate date] timeIntervalSince1970];
        
        NSLog(@"%@: %@ 耗时：%.3f秒",flag,url.zk_interface,localTime - beginTime);
    }
}

- (void)handleHttpResponseError:(NSError *)error useCache:(BOOL)useCache {
    if (useCache || error.code == NSURLErrorCancelled) {
        return;
    }
    // 提示用户 网络请求出错
}

- (void)handleResponse:(HTTPResponse *)resObj complete:(HttpTaskCompleteHandler)complete {
    
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
    requestParams = [[self class] fillRequestBodyWithParams:params];
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    
    NSMutableURLRequest *request = [serializer requestWithMethod:method URLString:URL parameters:requestParams error:nil];
    request.accessibilityValue = [request zk_json];
    request.accessibilityHint = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    [request setTimeoutInterval:20];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    return request;
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

- (AFNetworkReachabilityStatus)networkStatus {
    return _sessionManager.reachabilityManager.networkReachabilityStatus;
}

@end
