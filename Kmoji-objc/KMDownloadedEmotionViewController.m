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

@interface KMDownloadedEmotionViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet KMEmotionGridView *emotionGridView;
@property (strong, nonatomic) UIButton *sendButton;
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
    [self.emotionGridView layoutEmotionButtons];
    
    CGPoint center = self.sendButton.center;
    center.x = CGRectGetWidth(self.topView.frame) - (CGRectGetWidth(self.topView.frame) - CGRectGetWidth(self.coverImageView.frame))/4;
    center.y = CGRectGetHeight(self.topView.frame)/2;
    self.sendButton.center = center;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupUI
{
    self.coverImageView.layer.cornerRadius = 8.0f;
    self.emotionGridView.delegate = self;
    self.sendButton = [UIButton new];
    [self.sendButton setImage:[UIImage imageNamed:@"icon_send"] forState:UIControlStateNormal];
    [self.sendButton setImage:[UIImage imageNamed:@"icon_send_highlighted"] forState:UIControlStateHighlighted];
    [self.sendButton sizeToFit];
    [self.sendButton addTarget:self action:@selector(showShareView:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.sendButton];
    
    if (self.emotionInfo)
    {
        NSString *folder = self.emotionInfo[@"folder"];
        NSString *name = self.emotionInfo[@"name"];
        self.navigationItem.title = name;
        NSString *coverImgPath = [NSString stringWithFormat:@"%@/%@/%@", sharedEmotionsDirURL.path, folder, CoverImageName];
        UIImage *coverImg = [UIImage imageWithContentsOfFile:coverImgPath];
        [self.coverImageView setImage:coverImg];
        self.scrollView.contentSize = self.scrollView.bounds.size;
        
        [self.emotionGridView setDisplayType:GridViewType_Downloaded];
        [self.emotionGridView setUpEmotionsWithGroupName:folder];
    }
    [self.emotionGridView selectItemAtIndex:0];
}

- (void)updateTopView
{
    if (self.selectedEmotion && ![@"" isEqualToString:self.selectedEmotion])
    {
        NSString *imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, self.selectedEmotion];
        NSData *gifData = [[NSData alloc] initWithContentsOfFile:imagePath];
        UIImage *image = [UIImage animatedImageWithAnimatedGIFData:gifData];
        [self.coverImageView setImage:image];
    }
}

#pragma mark - KMEmotionGridViewDelegate

- (void)didSelectEmotion:(NSString *)name
{
    NSLog(@"%s - %@", __func__, name);
    self.selectedEmotion = name;
    [self updateTopView];
}

- (IBAction)showShareView:(id)sender
{
    NSLog(@"%s", __func__);
    if (!self.activityView)
    {
        self.activityView = [[HYActivityView alloc]initWithTitle:@"发送到" referView:self.view.window];
        
        //横屏会变成一行6个, 竖屏无法一行同时显示6个, 会自动使用默认一行4个的设置.
        self.activityView.numberOfButtonPerLine = 6;
        
        ButtonView *bv = [[ButtonView alloc]initWithText:@"微信" image:[UIImage imageNamed:@"share_platform_wechat"] handler:^(ButtonView *buttonView){
            [self sendGifToWechat];
        }];
        [self.activityView addButtonView:bv];
        
        bv = [[ButtonView alloc]initWithText:@"微信朋友圈" image:[UIImage imageNamed:@"share_platform_wechattimeline"] handler:^(ButtonView *buttonView){
            [self sendGifToWechatTimeline];
        }];
        [self.activityView addButtonView:bv];
        
        //        bv = [[ButtonView alloc]initWithText:@"QQ" image:[UIImage imageNamed:@"share_platform_qqfriends"] handler:^(ButtonView *buttonView){
        //            NSLog(@"点击QQ");
        //        }];
        //        [self.activityView addButtonView:bv];
        
    }
    
    [self.activityView show];
}

- (void)sendGifToWechat
{
    NSLog(@"%s - %@", __func__, self.selectedEmotion);
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, self.selectedEmotion];
    UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
    
    WXMediaMessage *message = [WXMediaMessage message];
    [message setThumbImage:img];
    
    WXEmoticonObject *emObj = [WXEmoticonObject object];
    emObj.emoticonData = [[NSData alloc] initWithContentsOfFile:imagePath]; ;
    
    message.mediaObject = emObj;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneSession;
    
    [WXApi sendReq:req];
}

- (void)sendGifToWechatTimeline
{
    NSLog(@"%s - %@", __func__, self.selectedEmotion);
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, self.selectedEmotion];
    UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
    
    WXMediaMessage *message = [WXMediaMessage message];
    [message setThumbImage:img];
    
    WXImageObject *imgObj = [WXImageObject object];
    imgObj.imageData = [[NSData alloc] initWithContentsOfFile:imagePath]; ;
    
    message.mediaObject = imgObj;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneTimeline;
    
    [WXApi sendReq:req];
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
