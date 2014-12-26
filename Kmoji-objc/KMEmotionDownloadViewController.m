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
    CGRect frame = CGRectMake(HorizontalMargin, CGRectGetMaxY(self.downloadBtn.frame) + 12, CGRectGetWidth(self.view.frame) - HorizontalMargin*2, 0);
    self.emotionGridView.frame = frame;
    [self.emotionGridView layoutEmotionButtons];
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
    
    if (self.emotionInfo)
    {
        NSString *folder = self.emotionInfo[@"folder"];
        NSString *name = self.emotionInfo[@"name"];
        self.navigationItem.title = name;
        NSString *coverImgPath = [NSString stringWithFormat:@"%@/%@/%@", emotionsDirURL.path, folder, CoverImageName];
        UIImage *coverImg = [UIImage imageWithContentsOfFile:coverImgPath];
        self.groupName.text = name;
        self.introLabel.text = self.emotionInfo[@"desc"];
        [self.coverImageView setImage:coverImg];
        self.scrollView.contentSize = self.scrollView.bounds.size;
        
        [self.emotionGridView setDisplayType:GridViewType_Normal];
        [self.emotionGridView setUpEmotionsWithGroupName:folder];
    }
    
    [self updateUI];
}

- (void)updateUI
{
    if ([[KMEmotionManager sharedManager].downloadedEmotionInfo containsObject:self.emotionInfo])
    {
        [self.downloadBtn setTitle:@"已下载,点击查看" forState:UIControlStateNormal];
    }
    else
    {
        [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
    }
}

- (IBAction)didClickeddownloadBtn:(id)sender
{
    if ([[KMEmotionManager sharedManager].downloadedEmotionInfo containsObject:self.emotionInfo])
    {
        //TODO: Share to friends
        [self.tabBarController setSelectedIndex:1];
        [[KMEmotionManager sharedManager] setSelectedEmotion:self.emotionInfo];
    }
    else
    {
        [[KMEmotionManager sharedManager] downloadEmotion:self.emotionInfo];
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
