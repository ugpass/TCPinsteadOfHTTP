//
//  HTTPObject.h
//  test
//
//  Created by fwj on 2019/4/18.
//  Copyright © 2019年 sjdd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^CompletionHandler)(NSData *);

@interface HTTPObject : NSObject
 
- (void)getRequestWithURL:(NSURL *)serverUrl Complete:(CompletionHandler)handler;
@end

NS_ASSUME_NONNULL_END
