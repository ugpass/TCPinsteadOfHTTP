//
//  ViewController.m
//  test
//
//  Created by fwj on 2019/4/18.
//  Copyright © 2019年 sjdd. All rights reserved.
//
//参考：https://www.jianshu.com/p/0a11b2d0f4ae
#import "ViewController.h"
#import "HTTPObject.h"

#define kHTTPSURL @"http://host:port/path"

@interface ViewController ()
@property (nonatomic, strong)HTTPObject *httpObj;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.httpObj getRequestWithURL:[NSURL URLWithString:kHTTPSURL] Complete:^(NSData *data){
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"response=%@",str);
        NSRange range = [str rangeOfString:@"\r\n\r\n"];
        if (range.location == NSNotFound) {
            NSLog(@"error");
            return;
        }
        NSString *newStr = [str substringFromIndex:range.location+1];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[newStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"dic=%@",dic);
    }];
}
 
- (HTTPObject *)httpObj{
    if (!_httpObj) {
        _httpObj = [[HTTPObject alloc] init];
    }
    return _httpObj;
}

@end
