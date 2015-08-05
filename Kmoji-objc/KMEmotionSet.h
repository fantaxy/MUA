//
//  KMEmotionSet.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/2/24.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KMEmotionSet : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *thumbName;
@property (nonatomic) NSUInteger               order;
@property (nonatomic) int               seq;
@property (nonatomic, strong) NSMutableArray *itemArray;
@property (nonatomic)         BOOL isDownloaded;

@end
