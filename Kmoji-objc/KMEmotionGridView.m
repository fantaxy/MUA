//
//  KMEmotionGridView.m
//  Kmoji-objc
//
//  Created by yangx2 on 10/25/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMEmotionGridView.h"
#import "GlobalConfig.h"
#import "FWTPopoverView.h"
#import "UIImage+animatedGIF.h"
#import "AppDelegate.h"
#import "KMEmotionManager.h"

@interface KMEmotionGridView ()
{
    int hInterval;
    int vInterval;
    int buttonWidth;
    int buttonHeight;
    int numberInRow;
}

@property (nonatomic, weak) UIButton *currentFocusButton;
@property (nonatomic, weak) UIButton *previousSelectedButton;
@property (nonatomic, strong) UIImageView *imageTipView;
@property (nonatomic, strong) FWTPopoverView *popoverView;
@property (nonatomic, weak) UIScrollView *parentScroolView;
@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) UIButton *deleteItemButton;
@property (nonatomic, weak) UITabBar *tabBar;

@end

@implementation KMEmotionGridView

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _imageTipView = [UIImageView new];
        UITabBarController *tabBarController = (UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        _tabBar = tabBarController.tabBar;
        
        _deleteItemButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteItemButton setBackgroundColor:UIColorWithRGB(243, 55, 50)];
        [_deleteItemButton addTarget:self action:@selector(didDeleteItems) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setUpEmotionsWithGroupName:(NSString *)groupName
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.parentScroolView = (UIScrollView *)self.superview;
    NSString *emotionsDirPath = [NSString stringWithFormat:@"%@/%@", emotionsDirURL.path, groupName];
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *emotionArray = [fileManager contentsOfDirectoryAtPath:emotionsDirPath error:&error];
    for (NSString *name in emotionArray)
    {
        if (![name isEqualToString:CoverImageName])
        {
            NSString *emotionName = [NSString stringWithFormat:@"%@/%@", groupName, name];
            UIButton *button = [self createEmotionButtonWithName:emotionName];
            [self addSubview:button];
        }
    }
}

- (void)setUpEmotionsWithArray:(NSArray *)emotionArray
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.parentScroolView = (UIScrollView *)self.superview;
    
    for (NSString *name in emotionArray)
    {
        if (![name containsString:CoverImageName])
        {
            UIButton *button = [self createEmotionButtonWithName:name];
            [self addSubview:button];
        }
    }
    [self layoutEmotionButtons];
}

- (UIButton *)createEmotionButtonWithName:(NSString *)name
{
    UIButton *button = [[UIButton alloc] init];
    [button setUserInteractionEnabled:NO];
    [button setBackgroundColor:[UIColor whiteColor]];
    [button setTitle:name forState:UIControlStateNormal];
    [button.layer setBorderColor:UIColorWithRGB(198, 198, 198).CGColor];
    [button.layer setCornerRadius:6.0];
    [button setImageEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
    NSString *imagePath;
    if (self.displayType == GridViewType_Normal)
    {
        imagePath = [NSString stringWithFormat:@"%@/%@", emotionsDirURL.path, name];
    }
    else
    {
        imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, name];
    }
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    [button setImage:image forState:UIControlStateNormal];
    return button;
}

- (void)layoutEmotionButtons
{
    int totalWidth = self.frame.size.width;
    
    vInterval = 10;
    numberInRow = 4;
    hInterval = 10;
    buttonWidth = (totalWidth - hInterval*(numberInRow-1))/4;
    buttonHeight = buttonWidth;
    
    int rowIndex = 0, columnIndex;
    NSUInteger count = self.subviews.count;
    for (int index = 0; index < count; index++)
    {
        UIButton *button = self.subviews[index];
        rowIndex  = index/numberInRow;
        columnIndex = index%numberInRow;
        CGRect frame = button.frame;
        frame.size = CGSizeMake(buttonWidth, buttonHeight);
        frame.origin.x = (buttonWidth + hInterval) * columnIndex;
        frame.origin.y = (buttonHeight + vInterval) * rowIndex;
        button.frame = frame;
    }
    int totalHeight = (buttonHeight + vInterval) * (rowIndex + 1);
    CGRect frame = self.frame;
    frame.size.height = totalHeight;
    self.frame = frame;
    
    self.deleteItemButton.frame = self.tabBar.frame;
    
    CGSize contentSize = self.parentScroolView.contentSize;
    contentSize.height = CGRectGetMaxY(frame);
    self.parentScroolView.contentSize = contentSize;
}

- (void)setIsEditing:(BOOL)isEditing
{
    if (isEditing)
    {
        _isEditing = isEditing;
        _selectedItems = [NSMutableArray new];
        [self updateButtonBorderWithWidth:1.0f];
        self.deleteItemButton.frame = self.tabBar.frame;
        [self.tabBar.superview addSubview:self.deleteItemButton];
        [self updateDeleteButton];
    }
    else
    {
        _isEditing = isEditing;
        [self removeButtonMask];
        [self updateButtonBorderWithWidth:0.0f];
        [self.deleteItemButton removeFromSuperview];
    }
}

- (void)selectItemAtIndex:(int)index
{
    NSLog(@"%s", __func__);
    if (index <= self.subviews.count)
    {
        UIButton *button = [self.subviews objectAtIndex:index];
        [self selectItem:button];
    }
}

- (void)selectItem:(UIButton *)button
{
    if (self.isEditing)
    {
        NSLog(@"%s - Mark selected %@.", __func__, button.titleLabel.text);
        if (![self.selectedItems containsObject:button.titleLabel.text])
        {
            UIImageView *maskView = [[UIImageView alloc] initWithFrame:button.bounds];
            [maskView setImage:[UIImage imageNamed:@"mask_select"]];
            [button addSubview:maskView];
            [self.selectedItems addObject:button.titleLabel.text];
        }
        else
        {
            for (UIView *view in button.subviews)
            {
                if (CGSizeEqualToSize(view.frame.size, button.frame.size))
                {
                    [view removeFromSuperview];
                }
            }
            [self.selectedItems removeObject:button.titleLabel.text];
        }
        [self updateDeleteButton];
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(didSelectEmotion:)])
        {
            [self.previousSelectedButton.layer setBorderWidth:0.0f];
            [button.layer setBorderWidth:1.0f];
            [self.delegate didSelectEmotion:button.titleLabel.text];
            self.previousSelectedButton = button;
        }
    }
}

- (void)didDeleteItems
{
    if (self.selectedItems.count)
    {
        NSArray *afterDeleted = [[KMEmotionManager sharedManager] deleteFavoriteEmotion:self.selectedItems];
        [self setUpEmotionsWithArray:afterDeleted];
        [self setIsEditing:NO];
        if ([self.delegate respondsToSelector:@selector(didFinishEditing)])
        {
            [self.delegate didFinishEditing];
        }
    }
}

- (void)updateDeleteButton
{
    if (self.selectedItems.count)
    {
        [self.deleteItemButton setEnabled:YES];
        [_deleteItemButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.deleteItemButton setTitle:[NSString stringWithFormat:@"删除(%d)", (int)self.selectedItems.count] forState:UIControlStateNormal];
    }
    else
    {
        [_deleteItemButton setTitleColor:UIColorWithRGB(170, 170, 170) forState:UIControlStateNormal];
        [_deleteItemButton setTitleColor:UIColorWithRGB(170, 170, 170) forState:UIControlStateHighlighted];
        [self.deleteItemButton setTitle:@"删除" forState:UIControlStateNormal];
    }
}

- (void)updateButtonBorderWithWidth:(CGFloat)borderWidth
{
    for (UIButton *button in self.subviews)
    {
        [button.layer setBorderWidth:borderWidth];
    }
}

- (void)removeButtonMask
{
    for (UIButton *button in self.subviews)
    {
        for (UIView *view in button.subviews)
        {
            if (CGSizeEqualToSize(view.frame.size, button.frame.size))
            {
                [view removeFromSuperview];
            }
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.currentFocusButton = [self getTargetButtonFromTouches:touches];
    [self performSelector:@selector(longTap) withObject:nil afterDelay:0.3f];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIButton *targetBtn = [self getTargetButtonFromTouches:touches];
    if (targetBtn && targetBtn != self.currentFocusButton)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longTap) object:nil];
        if (self.parentScroolView.scrollEnabled == NO)
        {
            self.currentFocusButton = targetBtn;
            [self didFocusOnEmotionButton:targetBtn];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longTap) object:nil];
    if (self.parentScroolView.scrollEnabled == NO)
    {
        [self didFocusOnEmotionButton:nil];
    }
    else
    {
        CGPoint touchPoint;
        UITouch * touchObj = [touches anyObject];
        touchPoint = [touchObj locationInView:self];
        UIButton *targetBtn = [self getTargetButtonFromTouches:touches];
        if (targetBtn)
        {
            [self selectItem:targetBtn];
        }
    }
    self.parentScroolView.scrollEnabled = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longTap) object:nil];
    self.parentScroolView.scrollEnabled = YES;
    [self didFocusOnEmotionButton:nil];
}

- (void)longTap
{
    self.parentScroolView.scrollEnabled = NO;
    [self didFocusOnEmotionButton:self.currentFocusButton];
}

- (UIButton *)getTargetButtonFromTouches:(NSSet *)touches
{
    CGPoint point = [[touches anyObject] locationInView:self];
    
    CGFloat x = point.x;
    CGFloat y = point.y;
    int rowIndex = y/(buttonHeight+vInterval);
    int columnIndex = x/(buttonWidth+hInterval);
    int buttonIndex = numberInRow * rowIndex  + columnIndex;
    if (buttonIndex < self.subviews.count)
    {
        return self.subviews[buttonIndex];
    }
    return nil;
}

- (void)didFocusOnEmotionButton:(UIButton *)button
{
    if (self.popoverView)
    {
        [self.popoverView dismissPopoverAnimated:NO];
    }
    
    if (!button || self.displayType == GridViewType_Downloaded)
    {
        return;
    }
    
    [self previewItem:button];
}

- (void)previewItem:(UIButton *)button
{
    self.popoverView = [[FWTPopoverView alloc] init];
    
    CGPoint arrowPoint;
    if (self.displayType == GridViewType_Favorite && 20 + CGRectGetMinY(button.frame) < 162)
    {
        arrowPoint.x = button.frame.origin.x + button.frame.size.width/2;
        arrowPoint.y = CGRectGetMaxY(button.frame);
        arrowPoint = [self convertPoint:arrowPoint toView:self.superview];
        //show preview view below
        [self.popoverView presentFromRect:CGRectMake(arrowPoint.x, arrowPoint.y, 1.0f, 1.0f)
                                   inView:self.superview
                  permittedArrowDirection:FWTPopoverArrowDirectionUp
                                 animated:NO];
    }
    else
    {
        arrowPoint.x = button.frame.origin.x + button.frame.size.width/2;
        arrowPoint.y = button.frame.origin.y;
        arrowPoint = [self convertPoint:arrowPoint toView:self.superview];
        //show preview view above
        [self.popoverView presentFromRect:CGRectMake(arrowPoint.x, arrowPoint.y, 1.0f, 1.0f)
                                   inView:self.superview
                  permittedArrowDirection:FWTPopoverArrowDirectionDown
                                 animated:NO];
    }
    
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", emotionsDirURL.path, button.titleLabel.text];
    //    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    NSData *gifData = [[NSData alloc] initWithContentsOfFile:imagePath];
    self.imageTipView.image = [UIImage animatedImageWithAnimatedGIFData:gifData];
    [self.imageTipView sizeToFit];
    [self.popoverView layoutSubviews];
    CGRect displayArea = UIEdgeInsetsInsetRect(self.popoverView.contentView.bounds, UIEdgeInsetsMake(10, 10, 10, 10));
    self.imageTipView.frame = [self calculateCenterFrameWithSize:self.imageTipView.frame.size inFrame:displayArea];
    [self.popoverView.contentView addSubview:self.imageTipView];
}

- (CGRect)calculateCenterFrameWithSize:(CGSize)size inFrame:(CGRect)frame
{
    CGRect result = CGRectZero;
    CGFloat maxWidth = frame.size.width;
    CGFloat maxHeight = frame.size.height;
    CGFloat scale = size.width/size.height;
    if (scale > 1.0)
    {
        result.size.width = MIN(size.width, maxWidth);
        result.size.height = result.size.width/scale;
    }
    else
    {
        result.size.height = MIN(size.height, maxHeight);
        result.size.width = result.size.height * scale;
    }
    result.origin.x = frame.origin.x + (maxWidth - result.size.width)/2.0;
    result.origin.y = frame.origin.y + (maxHeight - result.size.height)/2.0;
    return result;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
