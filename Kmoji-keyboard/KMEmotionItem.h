//
//  KMEmotionItem.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/2/24.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KMEmotionItem : NSObject

@property (nonatomic, strong) NSString *imageName;
@property (nonatomic) BOOL isDownloaded;
@property (nonatomic, strong) NSString *series;
@property (nonatomic, strong) NSMutableArray *tagArray;

- (NSString *)tagArrayToString;
- (void)updatetoDb;

@end
