//
//  KMAPIClient.m
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/6/27.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import "KMAPIClient.h"
#import "KMURLHelper.h"

@implementation KMAPIClient

+ (instancetype)sharedClient {
    static KMAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[KMAPIClient alloc] initWithBaseURL:[KMURLHelper baseURL]];
        _sharedClient.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    });
    
    return _sharedClient;
}

@end
