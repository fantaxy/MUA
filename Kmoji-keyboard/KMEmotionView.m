//
//  KMEmotionView.m
//  Kmoji-objc
//
//  Created by yangx2 on 10/9/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMEmotionView.h"
#import "GlobalConfig.h"
#import "YLCToastManager.h"
#import "UIImage+animatedGIF.h"
#import "KMEmotionItem.h"
#import "KMEmotionTag.h"
#import "FPPopoverController.h"
#import "KMEmotionManager.h"

@protocol KMEmotionScrollViewDelegate <UIScrollViewDelegate>

- (void)didSelectEmotionWithName:(NSString *)emotionName;
- (void)didFocusOnEmotionButton:(UIButton *)button;

@end

@interface KMEmotionScrollView : UIScrollView

@property (nonatomic, weak) id<KMEmotionScrollViewDelegate> emotionScrollViewDelegate;
@property (nonatomic, strong) UIButton *currentFocusButton;
@property (nonatomic) int pageCount;

@end

@implementation KMEmotionScrollView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.bounces = YES;
        self.alwaysBounceHorizontal = YES;
        self.pagingEnabled = YES;
        self.canCancelContentTouches = NO;
    }
    return self;
}

- (BOOL)layoutEmotionButtons
{
    int leftMargin;
    int topMargin = 0;
    int hInterval = 12;
    int vInterval = 10;
    int buttonWidth = 60;
    int buttonHeight = 60;
    int totalWidth = self.frame.size.width;
    int totalHeight = self.frame.size.height;
    if (!totalWidth || !totalHeight)
    {
        return NO;
    }
    int numberInRow = floorf(totalWidth/(buttonWidth+hInterval));
    int numberInPage = numberInRow * 2;
    leftMargin = (totalWidth - (buttonWidth * numberInRow + hInterval * (numberInRow-1)))/2;
    
    int pageIndex = 0, indexInPage, rowIndex, columnIndex;
    NSUInteger count = self.subviews.count;
    for (int index = 0; index < count; index++)
    {
        UIButton *button = self.subviews[index];
        pageIndex = index/numberInPage;
        indexInPage  = index%numberInPage;
        rowIndex  = indexInPage/numberInRow;
        columnIndex = indexInPage%numberInRow;
        CGRect frame = button.frame;
        frame.size = CGSizeMake(buttonWidth, buttonHeight);
        frame.origin.x = totalWidth * pageIndex + leftMargin + (buttonWidth + hInterval) * columnIndex;
        frame.origin.y = topMargin + (buttonHeight + vInterval) * rowIndex;
        button.frame = frame;
    }
    self.pageCount = pageIndex+1;
    self.contentSize = CGSizeMake(totalWidth * (pageIndex+1), totalHeight);
    self.contentOffset = CGPointMake(0, 0);
    
    return YES;
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
        if (self.scrollEnabled == NO)
        {
            self.currentFocusButton = targetBtn;
            [self.emotionScrollViewDelegate didFocusOnEmotionButton:targetBtn];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longTap) object:nil];
    if (self.scrollEnabled == NO)
    {
        //End previewing
        [self.emotionScrollViewDelegate didFocusOnEmotionButton:nil];
    }
    else
    {
        CGPoint touchPoint;
        UITouch * touchObj = [touches anyObject];
        touchPoint = [touchObj locationInView:self];
        UIButton *targetBtn = [self getTargetButtonFromTouches:touches];
        if (targetBtn)
        {
            [self.emotionScrollViewDelegate didSelectEmotionWithName:targetBtn.titleLabel.text];
        }
    }
    self.scrollEnabled = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longTap) object:nil];
    self.scrollEnabled = YES;
    [self.emotionScrollViewDelegate didFocusOnEmotionButton:nil];
}

- (void)longTap
{
    self.scrollEnabled = NO;
    [self.emotionScrollViewDelegate didFocusOnEmotionButton:self.currentFocusButton];
}

- (UIButton *)getTargetButtonFromTouches:(NSSet *)touches
{
    CGPoint point = [[touches anyObject] locationInView:self];
    
    int leftMargin;
    int topMargin = 18;
    int hInterval = 12;
    int vInterval = 10;
    int buttonWidth = 60;
    int buttonHeight = 60;
    int totalWidth = self.frame.size.width;
    
    int numberInRow = floorf(totalWidth/(buttonWidth+hInterval));
    int numberInPage = numberInRow * 2;
    leftMargin = (totalWidth - (buttonWidth * numberInRow + hInterval * (numberInRow-1)))/2;
    
    CGFloat x = fmodf(point.x, totalWidth);
    CGFloat y = point.y;
    int currentPage = point.x/totalWidth;
    int rowIndex = (y-topMargin)/(buttonHeight+vInterval);
    int columnIndex = (x-leftMargin)/(buttonWidth+hInterval);
    int buttonIndex = numberInPage*currentPage + numberInRow * rowIndex  + columnIndex;
    if (buttonIndex < self.subviews.count)
    {
        if (buttonIndex >= numberInPage*currentPage && buttonIndex <= numberInPage*(currentPage+1))
        {
            id target = self.subviews[buttonIndex];
            if ([target isKindOfClass:[UIButton class]]) {
                return target;
            }
        }
    }
    return nil;
}

@end

@interface KMEmotionView () <KMEmotionScrollViewDelegate>

@property (nonatomic, strong) KMEmotionScrollView *contentView;
@property (nonatomic, strong) UIImageView *imageTipView;
@property (nonatomic, retain) FPPopoverController *popoverView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic) BOOL isLandscape;
@property (nonatomic) BOOL needLayoutLater;
@property (nonatomic) BOOL needScrollToPageLater;

@end

@implementation KMEmotionView

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
    if (self) {
//        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        _contentView = [KMEmotionScrollView new];
        _contentView.emotionScrollViewDelegate = self;
        [self addSubview:_contentView];
        
        _pageControl = [UIPageControl new];
        _pageControl.hidesForSinglePage = NO;
        _pageControl.currentPageIndicatorTintColor = UIColorWithRGB(196, 202, 205);
        _pageControl.pageIndicatorTintColor = UIColorWithRGB(217, 225, 229);
        _pageControl.userInteractionEnabled = NO;
        [self addSubview:_pageControl];
        
        _imageTipView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    }
    return self;
}

- (void)layoutSubviews
{
    self.contentView.frame = self.bounds;
    
    CGFloat screenWidth = [UIScreen mainScreen].applicationFrame.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].applicationFrame.size.height;
    if (screenWidth > screenHeight && !self.isLandscape)
    {
        self.isLandscape = YES;
        [self.contentView layoutEmotionButtons];
    }
    else if (screenWidth <= screenHeight && self.isLandscape)
    {
        self.isLandscape = NO;
        [self.contentView layoutEmotionButtons];
    }
    else if (self.needLayoutLater)
    {
        self.needLayoutLater = ![self.contentView layoutEmotionButtons];
    }    
    
    self.pageControl.frame = CGRectMake(0, CGRectGetHeight(self.frame)-30, CGRectGetWidth(self.frame), 30);
    self.pageControl.numberOfPages = self.contentView.pageCount;
    if (self.needScrollToPageLater)
    {
        NSNumber *selectedPage = (NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"selectedPage"];
        [self scrollToPageAtIndex:[selectedPage unsignedIntegerValue] animater:NO];
    }
}

- (void)setupEmotionsWithGroup:(KMEmotionTag *)tag
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSDate* tmpStartData = [NSDate date];
    for (KMEmotionItem *item in tag.itemArray)
    {
        UIButton *button = [self createEmotionButtonWithName:item.imageName];
        [self.contentView addSubview:button];
    }
    double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
    NSLog(@"Read image cost time = %f", deltaTime);
    tmpStartData = [NSDate date];
    self.pageControl.currentPage = 0;
    self.needLayoutLater = YES;
    self.needScrollToPageLater = NO;
    [self layoutSubviews];
    deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
    NSLog(@"Layout cost time = %f", deltaTime);
}

- (void)setupEmotionsForFavorite
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (NSString *path in [[KMEmotionManager sharedManager] getFavoriteItemArray])
    {
        UIButton *button = [self createEmotionButtonWithName:path];
        [self.contentView addSubview:button];
    }
    
    self.needLayoutLater = YES;
    self.needScrollToPageLater = NO;
    [self layoutSubviews];
}

- (void)scrollToPreviousPage
{
    if (!self.needLayoutLater)
    {
        NSNumber *selectedPage = (NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"selectedPage"];
        [self scrollToPageAtIndex:[selectedPage unsignedIntegerValue] animater:NO];
    }
    else
    {
        self.needScrollToPageLater = YES;
    }
}

- (void)scrollToPageAtIndex:(NSUInteger)index animater:(BOOL)animated
{
    if (index < self.pageControl.numberOfPages)
    {
        CGFloat screenWidth = [UIScreen mainScreen].applicationFrame.size.width;
        CGPoint offset = CGPointMake(screenWidth*index, 0);
        [self.contentView setContentOffset:offset animated:animated];
        self.pageControl.currentPage = index;
    }
}

- (UIButton *)createEmotionButtonWithName:(NSString *)name
{
    UIButton *button = [[UIButton alloc] init];
    [button setUserInteractionEnabled:NO];
    [button setBackgroundColor:[UIColor whiteColor]];
    [button setTitle:name forState:UIControlStateNormal];
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, name];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    [button setImage:image forState:UIControlStateNormal];
    return button;
}

- (void)didSelectEmotionWithName:(NSString *)emotionName
{
    if (self.popoverView) {
        [self.popoverView dismissPopoverAnimated:NO];
    }
    
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, emotionName];
//    NSData *gifData = [[NSData alloc] initWithContentsOfFile:imagePath];
//    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//    [pasteboard setData:gifData forPasteboardType:@"com.compuserve.gif"];
    
//    [[YLCToastManager sharedInstance] showToastWithStyle:YLCToastTypeConfirm message:@"表情已复制到粘贴板" onView:self autoDismiss:YES];
    
    [self addToFavoriteWithName:emotionName];
    if ([self.delegate respondsToSelector:@selector(didSendEmotionWithImagePath:)]) {
        [self.delegate didSendEmotionWithImagePath:imagePath];
    }
}
     
- (void)addToFavoriteWithName:(NSString *)name
{
    [[KMEmotionManager sharedManager] addFavoriteItem:name];
}

- (void)didFocusOnEmotionButton:(UIButton *)button
{
    NSLog(@"%s", __func__);
    if (self.popoverView)
    {
        [self.popoverView dismissPopoverAnimated:NO];
    }
    
    if (!button)
    {
        return;
    }
    
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, button.titleLabel.text];
    //    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    NSData *gifData = [[NSData alloc] initWithContentsOfFile:imagePath];
    if (gifData)
    {
        self.imageTipView.image = [UIImage animatedImageWithAnimatedGIFData:gifData];
        [self.imageTipView sizeToFit];
    }
    else
    {
        NSLog(@"%s - Error: can not load image at path %@", __func__, imagePath);
    }
    
    UIViewController *vc = [[UIViewController alloc] init];
    [vc.view addSubview:self.imageTipView];
    
    self.popoverView = [[FPPopoverController alloc] initWithViewController:vc contentSize:CGSizeMake(120, 108)];
    self.popoverView.border = NO;
    self.popoverView.tint = FPPopoverWhiteTint;
    
    CGPoint arrowPoint;
    arrowPoint.x = fmodf(button.frame.origin.x, CGRectGetWidth(self.frame));
    arrowPoint.y = button.frame.origin.y + button.frame.size.height/2;
    if (arrowPoint.x < self.center.x)
    {
        //show preview view on the right
        arrowPoint.x += button.frame.size.width;
        self.popoverView.arrowDirection = FPPopoverArrowDirectionLeft;
//        [self.popoverView presentFromRect:CGRectMake(arrowPoint.x, arrowPoint.y, 1.0f, 1.0f)
//                                   inView:self
//                  permittedArrowDirection:FWTPopoverArrowDirectionLeft
//                                 animated:NO];
    }
    else
    {
        //show preview view on the left
        self.popoverView.arrowDirection = FPPopoverArrowDirectionRight;
        
//        [self.popoverView presentFromRect:CGRectMake(arrowPoint.x, arrowPoint.y, 1.0f, 1.0f)
//                                   inView:self
//                  permittedArrowDirection:FWTPopoverArrowDirectionRight
//                                 animated:NO];
    }
    [self.popoverView presentPopoverFromView:button inView:self];
    
    self.imageTipView.frame = [self calculateCenterFrameWithSize:self.imageTipView.frame.size inFrame:vc.view.bounds];
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

//- (void)addConstraintForPageControl
//{
//    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.pageControl attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:30.0];
//    
//    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.pageControl attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.pageControl attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.pageControl attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
//    
//    [self.pageControl addConstraint:heightConstraint];
//    [self addConstraints:@[bottomConstraint, leftConstraint, rightConstraint]];
//}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = CGRectGetWidth(self.frame);
    NSUInteger page = floor(self.contentView.contentOffset.x / pageWidth - 0.5) + 1;
    self.pageControl.currentPage = page;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:page] forKey:@"selectedPage"];
}

@end
