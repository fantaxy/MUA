//
//  KMEmotionTag.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/6/27.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KMEmotionTag : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *thumbName;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSDate *addTime;
@property (nonatomic, strong) NSArray *itemArray;
@property (nonatomic) int order;

- (instancetype)initWithName:(NSString *)name thumbName:(NSString *)thunmName;
- (NSString *)addTimeString;
- (void)setAddTimeWithString:(NSString *)timeString;
//- (void)updatetoDb;


@end
