//
//  KMEmotionDetatlViewController.m
//  Kmoji-objc
//
//  Created by yangx2 on 10/22/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMEmotionDownloadViewController.h"
#import "GlobalConfig.h"
#import "KMEmotionGridView.h"
#import "KMEmotionManager.h"
#import "KMEmotionTag.h"
#import "KMURLHelper.h"

#import "UIImageView+AFNetworking.h"

@interface KMEmotionDownloadViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *groupName;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UILabel *introLabel;
@property (strong, nonatomic) KMEmotionGridView *emotionGridView;

@end

@implementation KMEmotionDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
}

- (void)viewDidLayoutSubviews
{
    CGRect frame = CGRectMake(HorizontalMargin, CGRectGetMaxY(self.downloadBtn.frame) + 40, CGRectGetWidth(self.view.frame) - HorizontalMargin*2, 0);
    self.emotionGridView.frame = frame;
    [self.emotionGridView layoutEmotionTiles];
    frame = self.emotionGridView.frame;
    CGSize contentSize = self.scrollView.contentSize;
    contentSize.height = CGRectGetMaxY(frame);
    self.scrollView.contentSize = contentSize;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupUI
{
    self.coverImageView.layer.cornerRadius = 8.0f;
    self.downloadBtn.layer.cornerRadius = 5.0f;
    self.emotionGridView = [KMEmotionGridView new];
    [self.scrollView addSubview:self.emotionGridView];
    
    if (self.emotionTag)
    {
        NSString *name = self.emotionTag.name;
        self.navigationItem.title = name;
        self.groupName.text = name;
        self.introLabel.text = self.emotionTag.desc;
        [[KMEmotionManager sharedManager] getImageWithName:self.emotionTag.thumbName completionBlock:^(NSString *imagePath, NSError *error) {
            if (!error) {
                UIImage *coverImg = [UIImage imageWithContentsOfFile:imagePath];
                [self.coverImageView setImage:coverImg];
            }
        }];
        self.scrollView.contentSize = self.scrollView.bounds.size;
        
        [self.emotionGridView setDisplayType:GridViewType_Normal];
        [self.emotionGridView setUpEmotionsWithArray:self.emotionTag.itemArray];
    }
    
    [self updateUI];
}

- (void)updateUI
{
    if ([self.emotionTag isDownloaded])
    {
        [self.downloadBtn setTitle:@"已下载，点击查看" forState:UIControlStateNormal];
    }
    else
    {
        [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
    }
}

- (IBAction)didClickeddownloadBtn:(id)sender
{
    if ([self.emotionTag isDownloaded])
    {
        //TODO: Share to friends
        [self.tabBarController setSelectedIndex:1];
        [[KMEmotionManager sharedManager] setSelectedEmotion:self.emotionTag];
    }
    else
    {
        [[KMEmotionManager sharedManager] downloadEmotionTag:self.emotionTag];
        [self setupUI];
    }
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
