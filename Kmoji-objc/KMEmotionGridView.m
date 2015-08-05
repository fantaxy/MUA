//
//  KMEmotionGridView.m
//  Kmoji-objc
//
//  Created by yangx2 on 10/25/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMEmotionGridView.h"
#import "GlobalConfig.h"
#import "UIImage+animatedGIF.h"
#import "AppDelegate.h"
#import "KMEmotionManager.h"
#import "KMEmotionItem.h"
#import "FPPopoverController.h"
#import "KMURLHelper.h"

#import "UIActivityIndicatorView+AFNetworking.h"

@interface KMEmotionGridView ()
{
    int hInterval;
    int vInterval;
    int tileWidth;
    int tileHeight;
    int numberInRow;
}

@property (nonatomic, weak) UIImageView *currentFocusTile;
@property (nonatomic, weak) UIImageView *currentSelectedTile;
@property (nonatomic, strong) FPPopoverController *popoverView;
@property (nonatomic, weak) UIScrollView *parentScroolView;
@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) UIButton *deleteItemButton;
@property (nonatomic, weak) UITabBar *tabBar;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) NSArray *itemArray;

@end

@implementation KMEmotionGridView

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        UITabBarController *tabBarController = (UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        _tabBar = tabBarController.tabBar;
        
        _deleteItemButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteItemButton setBackgroundColor:UIColorWithRGB(243, 55, 50)];
        [_deleteItemButton addTarget:self action:@selector(didDeleteItems) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)awakeFromNib
{
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_sendButton setBackgroundColor:UIColorWithRGBA(0, 0, 0, 0.4)];
    [_sendButton setImage:[UIImage imageNamed:@"sendBtn"] forState:UIControlStateNormal];
    [_sendButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    _sendButton.layer.cornerRadius = 6.0f;
    [_sendButton addTarget:self action:@selector(sendButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpEmotionsWithArray:(NSArray *)emotionArray
{
    self.itemArray = emotionArray;
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.parentScroolView = (UIScrollView *)self.superview;
    
    for (id item in emotionArray)
    {
        NSString *name = nil;
        if ([item isKindOfClass:[KMEmotionItem class]]) {
            KMEmotionItem *eItem = (KMEmotionItem *)item;
            name = eItem.imageName;
        }
        else {
            name = item;
        }
        UIImageView *tile = [self createEmotionTileWithName:name];
        [self addSubview:tile];
    }
    [self layoutEmotionTiles];
}

- (UIImageView *)createEmotionTileWithName:(NSString *)name
{
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView.layer setCornerRadius:4.0];
    [imageView setClipsToBounds:YES];
    
    [[KMEmotionManager sharedManager] getImageWithName:name completionBlock:^(NSString *imagePath, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            [imageView setImage:image];
        }
    }];
    return imageView;
}

- (void)layoutEmotionTiles
{
    int totalWidth = self.frame.size.width;
    
    vInterval = 10;
    numberInRow = 4;
    hInterval = 12;
    tileWidth = (totalWidth - hInterval*(numberInRow-1))/4;
    tileHeight = tileWidth;
    
    int rowIndex = 0, columnIndex;
    NSUInteger count = self.subviews.count;
    for (int index = 0; index < count; index++)
    {
        UIImageView *tile = self.subviews[index];
        rowIndex  = index/numberInRow;
        columnIndex = index%numberInRow;
        CGRect frame = tile.frame;
        frame.size = CGSizeMake(tileWidth, tileHeight);
        frame.origin.x = (tileWidth + hInterval) * columnIndex;
        frame.origin.y = (tileHeight + vInterval) * rowIndex;
        tile.frame = frame;
    }
    int totalHeight = (tileHeight + vInterval) * (rowIndex + 1);
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
        [self updateTileBorderWithWidth:1.0f];
        self.deleteItemButton.frame = self.tabBar.frame;
        [self.tabBar.superview addSubview:self.deleteItemButton];
        [self updateDeleteButton];
    }
    else
    {
        _isEditing = isEditing;
        [self removeTileMask];
        [self updateTileBorderWithWidth:0.0f];
        [self.deleteItemButton removeFromSuperview];
    }
}

- (void)selectItemAtIndex:(int)index
{
    NSLog(@"%s", __func__);
    if (index < self.subviews.count)
    {
        UIImageView *tile = [self.subviews objectAtIndex:index];
        [self selectItem:tile];
    }
}

- (void)selectItem:(UIImageView *)tile
{
    NSUInteger index = [self.subviews indexOfObject:tile];
    if (index == NSNotFound || index >= self.itemArray.count) {
        return;
    }
    KMEmotionItem *item = self.itemArray[index];
    if (self.isEditing)
    {
        //收藏页
        NSLog(@"%s - Mark selected %@.", __func__, item.imageName);
        if (![self.selectedItems containsObject:item.imageName])
        {
            UIImageView *maskView = [[UIImageView alloc] initWithFrame:tile.bounds];
            [maskView setImage:[UIImage imageNamed:@"mask_select"]];
            [tile addSubview:maskView];
            [self.selectedItems addObject:item.imageName];
        }
        else
        {
            for (UIView *view in tile.subviews)
            {
                if (CGSizeEqualToSize(view.frame.size, tile.frame.size))
                {
                    [view removeFromSuperview];
                }
            }
            [self.selectedItems removeObject:item.imageName];
        }
        [self updateDeleteButton];
    }
    else
    {
        //发送页
        if (tile == self.currentSelectedTile) {
            //已经选中得再点一遍
            if ([self.delegate respondsToSelector:@selector(sendSelectedEmotion)]) {
                [self.delegate sendSelectedEmotion];
            }
        }
        else if ([self.delegate respondsToSelector:@selector(didSelectEmotion:)])
        {
            self.currentSelectedTile = tile;
            self.sendButton.frame = tile.bounds;
            CGFloat insetX = CGRectGetWidth(self.sendButton.frame)/4;
            CGFloat insetY = CGRectGetHeight(self.sendButton.frame)/4;
            [self.sendButton setImageEdgeInsets:UIEdgeInsetsMake(insetY, insetX, insetY, insetX)];
            [tile addSubview:self.sendButton];
            [self.delegate didSelectEmotion:item.imageName];
        }
    }
}

- (void)sendButtonClicked:(id)sender
{
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

- (void)updateTileBorderWithWidth:(CGFloat)borderWidth
{
    for (UIImageView *tile in self.subviews)
    {
        [tile.layer setBorderWidth:borderWidth];
    }
}

- (void)removeTileMask
{
    for (UIImageView *tile in self.subviews)
    {
        for (UIView *view in tile.subviews)
        {
            if (CGSizeEqualToSize(view.frame.size, tile.frame.size))
            {
                [view removeFromSuperview];
            }
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.currentFocusTile = [self getTargetTileFromTouches:touches];
    [self performSelector:@selector(longTap) withObject:nil afterDelay:0.3f];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIImageView *targetTile = [self getTargetTileFromTouches:touches];
    if (targetTile && targetTile != self.currentFocusTile)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longTap) object:nil];
        if (self.parentScroolView.scrollEnabled == NO)
        {
            self.currentFocusTile = targetTile;
            [self didFocusOnEmotionTile:targetTile];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longTap) object:nil];
    if (self.parentScroolView.scrollEnabled == NO)
    {
        [self didFocusOnEmotionTile:nil];
    }
    else
    {
        CGPoint touchPoint;
        UITouch * touchObj = [touches anyObject];
        touchPoint = [touchObj locationInView:self];
        UIImageView *targetTile = [self getTargetTileFromTouches:touches];
        if (targetTile)
        {
            [self selectItem:targetTile];
        }
    }
    self.parentScroolView.scrollEnabled = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longTap) object:nil];
    self.parentScroolView.scrollEnabled = YES;
    [self didFocusOnEmotionTile:nil];
}

- (void)longTap
{
    self.parentScroolView.scrollEnabled = NO;
    [self didFocusOnEmotionTile:self.currentFocusTile];
}

- (UIImageView *)getTargetTileFromTouches:(NSSet *)touches
{
    CGPoint point = [[touches anyObject] locationInView:self];
    
    CGFloat x = point.x;
    CGFloat y = point.y;
    int rowIndex = y/(tileHeight+vInterval);
    int columnIndex = x/(tileWidth+hInterval);
    int tileIndex = numberInRow * rowIndex  + columnIndex;
    if (tileIndex < self.subviews.count)
    {
        id target = self.subviews[tileIndex];
        if ([target isKindOfClass:[UIImageView class]]) {
            return target;
        }
    }
    return nil;
}

- (void)didFocusOnEmotionTile:(UIImageView *)tile
{
    if (self.popoverView)
    {
        [self.popoverView dismissPopoverAnimated:NO];
    }
    
    if (!tile || self.displayType == GridViewType_Downloaded)
    {
        return;
    }
    
    [self previewItem:tile];
}

- (void)previewItem:(UIImageView *)tile
{
    NSUInteger index = [self.subviews indexOfObject:tile];
    if (index == NSNotFound || index >= self.itemArray.count) {
        return;
    }
    id item = self.itemArray[index];
    NSString *imageName = nil;
    if ([item isKindOfClass:[KMEmotionItem class]]) {
        KMEmotionItem *eItem = (KMEmotionItem *)item;
        imageName = eItem.imageName;
    }
    else if ([item isKindOfClass:[NSString class]]) {
        imageName = (NSString *)item;
    }
    
    UIImageView *imageTipView = [UIImageView new];
    UIViewController *vc = [[UIViewController alloc] init];
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [vc.view addSubview:indicatorView];
    
    
    //    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    self.popoverView = [[FPPopoverController alloc] initWithViewController:vc contentSize:CGSizeMake(120, 120)];
    self.popoverView.border = NO;
    self.popoverView.tint = FPPopoverWhiteTint;
    
    if (self.displayType == GridViewType_Favorite && 20 + CGRectGetMinY(tile.frame) < 162)
    {
        //show preview view below
        self.popoverView.arrowDirection = FPPopoverArrowDirectionUp;
//        [self.popoverView presentFromRect:CGRectMake(arrowPoint.x, arrowPoint.y, 1.0f, 1.0f)
//                                   inView:self.superview
//                  permittedArrowDirection:FWTPopoverArrowDirectionUp
//                                 animated:NO];
    }
    else
    {
        //show preview view above
        self.popoverView.arrowDirection = FPPopoverArrowDirectionDown;
//        [self.popoverView presentFromRect:CGRectMake(arrowPoint.x, arrowPoint.y, 1.0f, 1.0f)
//                                   inView:self.superview
//                  permittedArrowDirection:FWTPopoverArrowDirectionDown
//                                 animated:NO];
    }
    [self.popoverView presentPopoverFromView:tile inView:self.superview];
    indicatorView.frame = vc.view.bounds;
    
    AFURLConnectionOperation *operation = [[KMEmotionManager sharedManager] getImageWithName:imageName completionBlock:^(NSString *imagePath, NSError *error) {
        if (!error) {
            [indicatorView removeFromSuperview];
            NSData *gifData = [[NSData alloc] initWithContentsOfFile:imagePath];
            [imageTipView setImage:[UIImage animatedImageWithAnimatedGIFData:gifData]];
            [imageTipView sizeToFit];
            [vc.view addSubview:imageTipView];
            
            CGRect displayArea = vc.view.bounds;
            imageTipView.frame = [self calculateCenterFrameWithSize:imageTipView.frame.size inFrame:displayArea];
        }
    }];
    [indicatorView setAnimatingWithStateOfOperation:operation];
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
