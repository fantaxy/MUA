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
//        self.bounces = YES;
//        self.alwaysBounceHorizontal = YES;
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
    UIButton *recentBtn = self.subviews[0];
    recentBtn.frame = CGRectMake(0, 0, 37, 37);
    [recentBtn setImageEdgeInsets:UIEdgeInsetsZero];
    for (int i=1; i<self.subviews.count; i++)
    {
        UIView *view = self.subviews[i];
        view.frame = CGRectMake((37+1)+(60+1)*(i-1), 0, 60, 37);
    }
}

- (void)selectPreviousGroup
{
    NSNumber *selectedGroup = (NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"selectedGroup"];
    [self selectGroupAtIndexCommon:[selectedGroup unsignedIntegerValue]];
}

- (void)selectGroupAtIndex:(NSUInteger)index
{
    [self selectGroupAtIndexCommon:index];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:index] forKey:@"selectedGroup"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:0] forKey:@"selectedPage"];
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
    if (!emotionTags || !emotionTags.count)
    {
        return;
    }
    //常用分组
    NSMutableArray *tags = [NSMutableArray arrayWithArray:emotionTags];
    KMEmotionTag *favTag = [[KMEmotionTag alloc] initWithName:@"favorite" thumbName:@"favorite"];
    favTag.itemArray = [[KMEmotionManager sharedManager] getFavoriteItemArray];
    [tags insertObject:favTag atIndex:0];
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
    self.contentSize = CGSizeMake((37+1)+(60+1)*emotionTags.count, 37.0f);
}

- (void)handleTapGesture:(UITapGestureRecognizer *)reconizer
{
    CGPoint tapPoint = [reconizer locationOfTouch:0 inView:self];
    int buttonWidth = 60.0;
    int groupIndex = tapPoint.x/buttonWidth;
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
