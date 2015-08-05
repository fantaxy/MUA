//
//  KMDownloadedEmotionViewController.m
//  Kmoji-objc
//
//  Created by yangx2 on 12/6/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMDownloadedEmotionViewController.h"
#import "GlobalConfig.h"
#import "KMEmotionManager.h"
#import "HYActivityView.h"
#import "WXApi.h"
#import "UIImage+animatedGIF.h"
#import "KMEmotionTag.h"
#import "KMURLHelper.h"
#import "OpenShare+Weixin.h"
#import "OpenShare+QQ.h"

#import "UIImageView+AFNetworking.h"

@interface KMDownloadedEmotionViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet KMEmotionGridView *emotionGridView;
@property (nonatomic, strong) HYActivityView *activityView;
@property (nonatomic, strong) NSString *selectedEmotion;

@end

@implementation KMDownloadedEmotionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[KMEmotionManager sharedManager] setSelectedEmotion:nil];
}

- (void)viewDidLayoutSubviews
{
//    CGRect frame = CGRectMake(HorizontalMargin, CGRectGetMaxY(self.topView.frame) + 12, CGRectGetWidth(self.view.frame) - HorizontalMargin*2, 0);
//    self.emotionGridView.frame = frame;
    [self.emotionGridView layoutEmotionTiles];
    [self adjustCoverImageViewFrame];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupUI
{
    self.coverImageView = [UIImageView new];
    self.coverImageView.layer.cornerRadius = 6.0f;
    self.coverImageView.clipsToBounds = YES;
    [self.topView addSubview:self.coverImageView];
    self.emotionGridView.delegate = self;
    
    if (self.emotionTag)
    {
        NSString *name = self.emotionTag.name;
        self.navigationItem.title = name;
        self.scrollView.contentSize = self.scrollView.bounds.size;
        
        [self.emotionGridView setDisplayType:GridViewType_Downloaded];
        [self.emotionGridView setUpEmotionsWithArray:self.emotionTag.itemArray];
    }
    [self.emotionGridView selectItemAtIndex:0];
}

- (void)adjustCoverImageViewFrame
{
    CGFloat width = self.coverImageView.frame.size.width;
    CGFloat height = self.coverImageView.frame.size.height;
    CGFloat maxWidth = self.topView.frame.size.width;
    CGFloat maxHeight = self.topView.frame.size.height - 10;
    CGFloat imageScale = width/height;
    CGFloat scale = maxWidth/maxHeight;
    CGFloat adjustedWidth, adjustedHeight;
    if (imageScale > scale) {
        adjustedWidth = maxWidth;
        adjustedHeight = maxWidth / imageScale;
    }
    else {
        adjustedHeight = maxHeight;
        adjustedWidth = maxHeight * imageScale;
    }
    self.coverImageView.frame = CGRectMake((CGRectGetWidth(self.topView.frame)-adjustedWidth)/2, (CGRectGetHeight(self.topView.frame)-adjustedHeight)/2, adjustedWidth, adjustedHeight);
}

- (void)updateTopView
{
    if (self.selectedEmotion && ![@"" isEqualToString:self.selectedEmotion])
    {
        [[KMEmotionManager sharedManager] getImageWithName:self.selectedEmotion completionBlock:^(NSString *imagePath, NSError *error) {
            if (!error) {
                NSData *gifData = [[NSData alloc] initWithContentsOfFile:imagePath];
                UIImage *image = [UIImage animatedImageWithAnimatedGIFData:gifData];
                [self.coverImageView setImage:image];
                [self.coverImageView sizeToFit];
                [self adjustCoverImageViewFrame];
            }
        }];
    }
}

#pragma mark - KMEmotionGridViewDelegate

- (void)didSelectEmotion:(NSString *)name
{
//    NSLog(@"%s - %@", __func__, name);
    self.selectedEmotion = name;
    [self updateTopView];
}

- (void)sendSelectedEmotion
{
    [self showShareView:nil];
}

- (IBAction)showShareView:(id)sender
{
    NSLog(@"%s", __func__);
    if (!self.activityView)
    {
        self.activityView = [[HYActivityView alloc]initWithTitle:@"发送到" referView:self.view.window];
        
        //横屏会变成一行6个, 竖屏无法一行同时显示6个, 会自动使用默认一行4个的设置.
        self.activityView.numberOfButtonPerLine = 6;
        
        ButtonView *bv = [[ButtonView alloc] initWithText:@"微信" image:[UIImage imageNamed:@"weixin"] handler:^(ButtonView *buttonView){
            [self sendGifToWechat];
        }];
        [self.activityView addButtonView:bv];
        
        bv = [[ButtonView alloc] initWithText:@"朋友圈" image:[UIImage imageNamed:@"weixintimeline"] handler:^(ButtonView *buttonView){
            [self sendGifToWechatTimeline];
        }];
        [self.activityView addButtonView:bv];
        
        bv = [[ButtonView alloc]initWithText:@"QQ" image:[UIImage imageNamed:@"qq"] handler:^(ButtonView *buttonView){
            [self sendGifToQQ];
        }];
        [self.activityView addButtonView:bv];
        
    }
    
    [self.activityView show];
}

- (void)sendGifToWechat
{
    NSLog(@"%s - %@", __func__, self.selectedEmotion);
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, self.selectedEmotion];
    UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
    
    OSMessage *msg=[[OSMessage alloc]init];
    
    msg.image = [[NSData alloc] initWithContentsOfFile:imagePath];
    //压缩下 微信对缩略图大小有限制
    msg.thumbnail = UIImageJPEGRepresentation(img, 0);
    
    [OpenShare shareToWeixinSession:msg Success:^(OSMessage *message) {
        NSLog(@"微信分享到会话成功：\n%@",message);
    } Fail:^(OSMessage *message, NSError *error) {
        NSLog(@"微信分享到会话失败：\n%@\n%@",error,message);
    }];
}

- (void)sendGifToWechatTimeline
{
    NSLog(@"%s - %@", __func__, self.selectedEmotion);
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, self.selectedEmotion];
    UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
    
    OSMessage *msg=[[OSMessage alloc]init];
    
    msg.image = [[NSData alloc] initWithContentsOfFile:imagePath];
    //压缩下 微信对缩略图大小有限制
    msg.thumbnail = UIImageJPEGRepresentation(img, 0);
    
    [OpenShare shareToWeixinTimeline:msg Success:^(OSMessage *message) {
        NSLog(@"微信分享到朋友圈成功：\n%@",message);
    } Fail:^(OSMessage *message, NSError *error) {
        NSLog(@"微信分享到朋友圈失败：\n%@\n%@",error,message);
    }];
    
}
- (void)sendGifToQQ
{
    NSLog(@"%s - %@", __func__, self.selectedEmotion);
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, self.selectedEmotion];
    UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
    
    OSMessage *msg=[[OSMessage alloc]init];
    msg.title = @"MUA表情";
    msg.image = [[NSData alloc] initWithContentsOfFile:imagePath];
    msg.thumbnail = UIImageJPEGRepresentation(img, 0);
    msg.desc = @"分享快乐";
    
    [OpenShare shareToQQFriends:msg Success:^(OSMessage *message) {
        NSLog(@"QQ分享到会话成功：\n%@",message);
    } Fail:^(OSMessage *message, NSError *error) {
        NSLog(@"QQ分享到会话失败：\n%@\n%@",error,message);
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
