//
//  KMModel.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/7/19.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KMModel : NSObject<NSCoding>

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;

@end
