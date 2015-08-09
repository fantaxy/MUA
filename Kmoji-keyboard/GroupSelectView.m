//
//  GroupSelectView.m
//  Kmoji-objc
//
//  Created by yangx2 on 10/5/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "GroupSelectView.h"
#import "GlobalConfig.h"
#import "KMEmotionTag.h"
#import "UIPureColorButton.h"
#import "KMEmotionManager.h"

#define RECENT_BTN_WIDTH (37.f)
#define BTN_WIDTH (60.f)
#define BTN_HEIGHT (37.f)

@interface GroupSelectView () <UIGestureRecognizerDelegate>
{
    UITapGestureRecognizer *tapGestureRecognizer;
}

@property (nonatomic, strong) NSArray *emotionTags;

@end

@implementation GroupSelectView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.bounces = YES;
        self.alwaysBounceHorizontal = YES;
//        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    return self;
}

- (void)layoutSubviews
{
    if (!self.subviews.count) {
        return;
    }
    UIButton *recentBtn = self.subviews[0];
    recentBtn.frame = CGRectMake(0, 0, RECENT_BTN_WIDTH, RECENT_BTN_WIDTH);
    [recentBtn setImageEdgeInsets:UIEdgeInsetsZero];
    for (int i=1; i<self.subviews.count; i++)
    {
        UIView *view = self.subviews[i];
        view.frame = CGRectMake((RECENT_BTN_WIDTH+1)+(BTN_WIDTH+1)*(i-1), 0, BTN_WIDTH, BTN_HEIGHT);
    }
}

- (void)setGroupSelectViewDelegate:(id<GroupSelectViewDelegate>)groupSelectViewDelegate
{
    _groupSelectViewDelegate = groupSelectViewDelegate;
    self.delegate = groupSelectViewDelegate;
}

- (void)selectPreviousGroup
{
    NSNumber *selectedGroup = (NSNumber *)[KMEmotionManager getSharedSettingsForKey:@"selectedGroup"];
    [self selectGroupAtIndexCommon:[selectedGroup unsignedIntegerValue]];
}

- (void)selectGroupAtIndex:(NSUInteger)index
{
    [self selectGroupAtIndexCommon:index];
    [KMEmotionManager setSharedSettingsWithValueArray:@[@(index),@(0)] forKeyArray:@[@"selectedGroup", @"selectedPage"]];
}

- (void)selectGroupAtIndexCommon:(NSUInteger)index
{
    if (self.subviews.count > index)
    {
        for (UIButton *button in self.subviews)
        {
            [button setSelected:NO];
        }
        UIButton *selectedBtn = self.subviews[index];
        [selectedBtn setSelected:YES];
        KMEmotionTag *group = self.emotionTags[index];
        [self.groupSelectViewDelegate didSelectGroup:group];
    }
}

- (void)setupWithGroups:(NSArray *)emotionTags
{
    NSMutableArray *tags = [NSMutableArray new];
    //常用分组
    KMEmotionTag *favTag = [[KMEmotionTag alloc] initWithName:@"favorite" thumbName:@"favorite"];
    favTag.itemArray = [[KMEmotionManager sharedManager] getFavoriteItemArray];
    [tags addObject:favTag];
    if (emotionTags && emotionTags.count)
    {
        [tags addObjectsFromArray:emotionTags];
    }
    self.emotionTags = tags;
    NSMutableArray *groupButtonArray = [NSMutableArray new];
    for (KMEmotionTag *eTag in tags)
    {
        UIButton *groupButton = [self createGroupButtonWithTitle:eTag.name iconName:eTag.thumbName];
        [self addSubview:groupButton];
        [groupButtonArray addObject:groupButton];
    }
    
    [groupButtonArray[0] setImage:[UIImage imageNamed:@"recent"] forState:UIControlStateNormal];
    [groupButtonArray[0] setImage:[UIImage imageNamed:@"recent_pressed"] forState:UIControlStateHighlighted];
    [groupButtonArray[0] setTitle:@"" forState:UIControlStateNormal];
    self.contentSize = CGSizeMake((RECENT_BTN_WIDTH+1)+(BTN_WIDTH+1)*emotionTags.count, BTN_HEIGHT);
}

- (void)handleTapGesture:(UITapGestureRecognizer *)reconizer
{
    CGPoint tapPoint = [reconizer locationOfTouch:0 inView:self];
    int buttonWidth = BTN_WIDTH;
    int groupIndex = 0;
    if (tapPoint.x > RECENT_BTN_WIDTH) {
        groupIndex = (tapPoint.x-RECENT_BTN_WIDTH)/buttonWidth + 1;
    }
    else {
        groupIndex = 0;
    }
    [self selectGroupAtIndex:groupIndex];
}

- (UIButton *)createGroupButtonWithTitle:(NSString *)title iconName:(NSString *)icon
{
    UIButton *button = [[UIPureColorButton alloc] initWithBgColor:UIColorWithRGBHex(0xf3f3f3) highlightedColor:UIColorWithRGBHex(0xe6e6e6)];
    button.adjustsImageWhenHighlighted = NO;
    button.userInteractionEnabled = NO;
    [button setImageEdgeInsets:UIEdgeInsetsMake(4, 11, 4, 11)];
    
    NSString *coverImagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, icon];
    UIImage *coverImage = [UIImage imageWithContentsOfFile:coverImagePath];
    [button setImage:coverImage forState:UIControlStateNormal];
    
    return button;
}

//- (void)addGroupButtonConstraintForButtons:(NSArray *)buttons
//{
//    for (int i=0; i<buttons.count; i++)
//    {
//        UIButton *button = buttons[i];
//        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
//        
//        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:60.0];
//        
//        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
//        
//        NSLayoutConstraint *leftConstraint, *rightConstraint;
//        
//        if (i == 0)
//        {
//            leftConstraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
//        }
//        else
//        {
//            leftConstraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:buttons[i-1] attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
//        }
//        
//        
//        if (i == buttons.count-1)
//        {
//            rightConstraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
//            
//        }
//        else
//        {
//            rightConstraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:buttons[i+1] attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
//        }
//        [self addConstraints:@[topConstraint, leftConstraint, rightConstraint, widthConstraint, heightConstraint]];
//    }
//}

@end
