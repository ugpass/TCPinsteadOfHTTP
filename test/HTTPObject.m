//
//  HTTPObject.m
//  test
//
//  Created by fwj on 2019/4/18.
//  Copyright © 2019年 sjdd. All rights reserved.
//

#import "HTTPObject.h"

@interface HTTPObject()<GCDAsyncSocketDelegate>
{
    NSString       *_serverHost;//IP或者域名
    int             _serverPort;//端口，https一般是443 http80
    GCDAsyncSocket *_asyncSocket;//一个全局的对象
}
@property (nonatomic, strong) NSMutableData     *sendData;//最终拼接好的需要发送出去的数据
@property (nonatomic, copy)   NSString          *uriString;//具体请求哪个接口，比如https://xxx.xxxxx.com/verificationCode里的verificationCode
@property (nonatomic, strong) NSDictionary      *paramters;//Body里面需要传递的参数
@property (nonatomic, copy)   CompletionHandler  completeHandler;//收到返回数据后的回调Block
@property (nonatomic, strong) NSMutableArray *dcNetArr;//网络请求参数的暂存数组，后面会用到
@end

@implementation HTTPObject

- (instancetype)init{
    if (self = [super init]) {
        NSLog(@"-- init --"); 
        _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue() socketQueue:nil];
        _dcNetArr = [NSMutableArray arrayWithCapacity:20];
    }
    return self;
}

- (void)getRequestWithURL:(NSURL *)serverUrl Complete:(CompletionHandler)handler{
    _serverHost = serverUrl.host;
    _serverPort = [serverUrl.port intValue];
    _uriString = serverUrl.path;
    if (_serverPort == 0) {
        _serverPort = 80;
    }
    NSLog(@"host=%@,port=%d,serverPath=%@",_serverHost,_serverPort,_uriString);
    _completeHandler = handler;
    [_asyncSocket connectToHost:_serverHost onPort:_serverPort error:nil];
}


#pragma mark - delegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"didConnectToHost host=%@ port=%d",host,port);
    NSLog(@"sendData = %@",[[NSString alloc] initWithData:self.sendData encoding:NSUTF8StringEncoding]);
    [sock writeData:self.sendData withTimeout:-1 tag:0];
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(@"didReadData length: %lu, tag: %ld", (unsigned long)data.length, tag);
    self.completeHandler(data);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{//成功发送数据时会调用
    NSLog(@"didWriteDataWithTag: %ld", tag);
    [sock readDataWithTimeout:-1 tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url{
    NSLog(@"didConnectToUrl url:%@",url);
}

#pragma mark - private
- (NSMutableData *)sendData{
    NSMutableData *packetData = [[NSMutableData alloc] init];
    NSData *ctrlData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];//回车换行

    [packetData appendData:[[NSString stringWithFormat:@"GET %@ HTTP/1.1",self.uriString] dataUsingEncoding:NSUTF8StringEncoding]];
    [packetData appendData:ctrlData];
    
    [packetData appendData:[[NSString stringWithFormat:@"cache-control: no-cache"] dataUsingEncoding:NSUTF8StringEncoding]];
    [packetData appendData:ctrlData];
    
//    NSError *error;
//    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:self.paramters
//                                                       options:0
//                                                         error:&error];
//    NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];//生成请求体的内容
    
//    [packetData appendData:[[NSString stringWithFormat:@"Content-Length: %ld", bodyString.length] dataUsingEncoding:NSUTF8StringEncoding]];//说明请求体内容的长度
//    [packetData appendData:ctrlData];
    
    [packetData appendData:[[NSString stringWithFormat:@"Content-Type: application/json; charset=utf-8"] dataUsingEncoding:NSUTF8StringEncoding]];//说明请求体内容的长度
    [packetData appendData:ctrlData];
    
    [packetData appendData:[@"Connection:keep-alive" dataUsingEncoding:NSUTF8StringEncoding]];
    [packetData appendData:ctrlData];
    [packetData appendData:ctrlData];//注意这里请求头拼接完成要加两个回车换行
    //以上http头信息就拼接完成，下面继续拼接上body信息
//    NSString *encodeBodyStr = [NSString stringWithFormat:@"%@\r\n\r\n", bodyString];//请求体最后也要加上两个回车换行说明数据已经发送完毕
//    [packetData appendData:[encodeBodyStr dataUsingEncoding:NSUTF8StringEncoding]];
    return packetData;
    
}

- (void)doTLSConnect:(GCDAsyncSocket *)sock {
    //HTTPS
    NSMutableDictionary *sslSettings = [[NSMutableDictionary alloc] init];
    NSData *pkcs12data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"xxx.xxxxxxx.com" ofType:@"p12"]];//已经支持https的网站会有CA证书，给服务器要一个导出的p12格式证书
    CFDataRef inPKCS12Data = (CFDataRef)CFBridgingRetain(pkcs12data);
    CFStringRef password = CFSTR("xxxxxx");//这里填写上面p12文件的密码
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    
    OSStatus securityError = SecPKCS12Import(inPKCS12Data, options, &items);
    CFRelease(options);
    CFRelease(password);
    
    if (securityError == errSecSuccess) {
        NSLog(@"Success opening p12 certificate.");
    }
    
    CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
    SecIdentityRef myIdent = (SecIdentityRef)CFDictionaryGetValue(identityDict, kSecImportItemIdentity);
    SecIdentityRef  certArray[1] = { myIdent };
    CFArrayRef myCerts = CFArrayCreate(NULL, (void *)certArray, 1, NULL);
    [sslSettings setObject:(id)CFBridgingRelease(myCerts) forKey:(NSString *)kCFStreamSSLCertificates];
    [sslSettings setObject:@"api.pandaworker.com" forKey:(NSString *)kCFStreamSSLPeerName];
    [sock startTLS:sslSettings];//最后调用一下GCDAsyncSocket这个方法进行ssl设置就Ok了
}

@end
