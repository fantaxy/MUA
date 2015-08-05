//
//  KMURLHelper.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/6/28.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KMURLHelper : NSObject

+ (NSURL *)baseURL;
+ (NSString *)dataPath;
+ (NSURL *)imageURLWithName:(NSString *)name;

@end
