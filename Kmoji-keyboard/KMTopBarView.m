//
//  KMTopBarView.m
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/8/2.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import "KMTopBarView.h"

@interface KMTopBarView ()

@property (nonatomic, strong) UIButton *wechatBtn;
@property (nonatomic, strong) UIButton *wechatTimelineBtn;
@property (nonatomic, strong) UIButton *qqBtn;
@property (nonatomic, strong) NSArray *sharingBtnArray;
@property (nonatomic, weak) UIButton *lastSelectedBtn;

@end

@implementation KMTopBarView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _wechatBtn = [UIButton new];
        _wechatBtn.backgroundColor = [UIColor clearColor];
        [_wechatBtn setImage:[UIImage imageNamed:@"weixin"] forState:UIControlStateNormal];
        [_wechatBtn setImage:[UIImage imageNamed:@"weixin_selected"] forState:UIControlStateSelected];
        [_wechatBtn sizeToFit];
        [_wechatBtn addTarget:self action:@selector(onSharingBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        _wechatBtn.tag = KMSharingDestination_Wechat;
        [self addSubview:_wechatBtn];
        
        _wechatTimelineBtn = [UIButton new];
        _wechatTimelineBtn.backgroundColor = [UIColor clearColor];
        [_wechatTimelineBtn setImage:[UIImage imageNamed:@"weixintimeline"] forState:UIControlStateNormal];
        [_wechatTimelineBtn setImage:[UIImage imageNamed:@"weixintimeline_selected"] forState:UIControlStateSelected];
        [_wechatTimelineBtn sizeToFit];
        [_wechatTimelineBtn addTarget:self action:@selector(onSharingBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        _wechatTimelineBtn.tag = KMSharingDestination_WechatTimeline;
        [self addSubview:_wechatTimelineBtn];
        
        _qqBtn = [UIButton new];
        _qqBtn.backgroundColor = [UIColor clearColor];
        [_qqBtn setImage:[UIImage imageNamed:@"qq"] forState:UIControlStateNormal];
        [_qqBtn setImage:[UIImage imageNamed:@"qq_selected"] forState:UIControlStateSelected];
        [_qqBtn sizeToFit];
        [_qqBtn addTarget:self action:@selector(onSharingBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        _qqBtn.tag = KMSharingDestination_QQ;
        [self addSubview:_qqBtn];
        
        _sharingBtnArray = [NSArray arrayWithObjects:_wechatBtn, _qqBtn, _wechatTimelineBtn, nil];
        [self initSharingOption];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.sharingBtnArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIButton *btn = (UIButton *)obj;
        btn.frame = CGRectMake(20 + (30+50)*idx, 10, 30, 30);
    }];
}

- (void)onSharingBtnClicked:(id)sender
{
    UIButton *target = (UIButton *)sender;
    [self.lastSelectedBtn setSelected:NO];
    [target setSelected:YES];
    if (self.lastSelectedBtn != target) {
        self.lastSelectedBtn = target;
        self.shareTo = target.tag;
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:target.tag] forKey:@"SavedSharingOption"];
    }
}

- (void)initSharingOption
{
    UIButton *selectedBtn = nil;
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedSharingOption"];
    if (number && [number integerValue] != 0) {
        selectedBtn = (UIButton *)[self viewWithTag:[number integerValue]];
    }
    else {
        selectedBtn = self.wechatBtn;
    }
    [self onSharingBtnClicked:selectedBtn];
}


@end
