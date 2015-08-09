//
//  KeyboardViewController.m
//  Kmoji-keyboard
//
//  Created by yangx2 on 9/22/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KeyboardViewController.h"
#import "GlobalConfig.h"
#import "GroupSelectView.h"
#import "KMEmotionView.h"
#import "WXApi.h"
#import "UIPureColorButton.h"
#import "YLCToastManager.h"
#import "KMEmotionTag.h"
#import "KMEmotionItem.h"
#import "KMEmotionKeyboardDataBase.h"
#import "KMEmotionManager.h"
#import "KMTopBarView.h"
#import "OpenShare+Weixin.h"
#import "OpenShare+QQ.h"

#import <FIR/FIR.h>

NSURL *containerURL;
NSURL *sharedDirURL;
NSURL *sharedEmotionsDirURL;
NSURL *emotionsDirURL;
NSURL *favoritePlistURL;
NSURL *sharedSettingsPlistURL;

#define Keyboard_Height 251.0f
#define Top_Bar_Height 53.0f
#define Bottom_Bar_Height 37.0f
#define More_Button_Width 51.0f

@interface KeyboardViewController () <GroupSelectViewDelegate, KMEmotionViewDelegate>
{
    BOOL needInformUserLater;
    NSLayoutConstraint *_heightConstraint;
}

@property (nonatomic, strong) NSArray *plistData;
@property (nonatomic, strong) NSArray *emotionTags;
@property (nonatomic, strong) KMEmotionView *emotionsView;
@property (nonatomic, strong) UIButton *nextKeyboardButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) GroupSelectView *bottomScrollView;
@property (nonatomic, strong) KMTopBarView *topBarView;
@property (nonatomic, strong) UIView *topLineView;

@end

@implementation KeyboardViewController

- (void)updateViewConstraints {
    [super updateViewConstraints];
    // Add custom view sizing constraints here
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [OpenShare connectWeixinWithAppId:@"wxb692717f834207df"];
    [OpenShare connectQQWithAppId:@"1104724845"];
    [FIR handleCrashWithKey:@"1b7695f33e48b173bbe04c1a1a2c4689"];
    
    containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:AppGroupID];
    sharedDirURL = [NSURL URLWithString:@"Library/Caches/" relativeToURL:containerURL];
    sharedEmotionsDirURL = [NSURL URLWithString:@"emotions/" relativeToURL:sharedDirURL];
    favoritePlistURL = [NSURL URLWithString:@"favorite.plist" relativeToURL:sharedDirURL];
    sharedSettingsPlistURL = [NSURL URLWithString:@"sharedSettings.plist" relativeToURL:sharedDirURL];
    NSLog(@"Shared Directory: %@", sharedDirURL.path);
    
    [self readEmotionData];
    
    // Perform custom UI setup here
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __func__);
    [super viewWillAppear:animated];
    
    UILabel *dummyView = [UILabel new];
    [dummyView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:dummyView];
    
    [self.view removeConstraint:_heightConstraint];
    _heightConstraint =
    [NSLayoutConstraint constraintWithItem: self.view
                                 attribute: NSLayoutAttributeHeight
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: nil
                                 attribute: NSLayoutAttributeNotAnAttribute
                                multiplier: 0.0
                                  constant: Keyboard_Height];
    [self.view addConstraint: _heightConstraint];
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)viewDidLayoutSubviews
{
    CGRect frame = self.view.frame;
    if (needInformUserLater && CGRectGetWidth(frame) && CGRectGetHeight(frame))
    {
        [[YLCToastManager sharedInstance] showToastWithStyle:YLCToastTypeConfirm message:@"你还没有添加表情哦，请确认设置->通用->键盘->MUA表情键盘->允许完全访问功能已打开，并点击加号添加表情。" onView:self.view];
        needInformUserLater = NO;
    }
    [self arrangeUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    
}

- (void)textWillChange:(id<UITextInput>)textInput {
    // The app is about to change the document's contents. Perform any preparation here.
}

- (void)textDidChange:(id<UITextInput>)textInput {
    // The app has just changed the document's contents, the document context has been updated.
    
    UIColor *textColor = nil;
    if (self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearanceDark) {
        textColor = [UIColor whiteColor];
    } else {
        textColor = [UIColor blackColor];
    }
    [self.nextKeyboardButton setTitleColor:textColor forState:UIControlStateNormal];
}

- (BOOL)readEmotionData
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:sharedSettingsPlistURL];
    BOOL success = [dict writeToURL:sharedSettingsPlistURL atomically:YES];
    if (success)
    {
        self.emotionTags = [[KMEmotionKeyboardDataBase sharedInstance] getDownloadedEmotionTagArray];
        return YES;
    }
    else
    {
        NSLog(@"Fail to access shared resource.");
        needInformUserLater = YES;
        return NO;
    }
}

- (void)setupUI
{
    [self setupTopBarView];
    [self setupBottomView];
    [self setupEmotionsView];
    [self arrangeUI];

    CGFloat viewWidth = [UIScreen mainScreen].applicationFrame.size.width;
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 0.5)];
    [topLineView setBackgroundColor:UIColorWithRGB(220, 220, 220)];
    [topLineView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.view addSubview:topLineView];
    NSData *tempArchive = [NSKeyedArchiver archivedDataWithRootObject:topLineView];
    UIView *topLineViewCopy = [NSKeyedUnarchiver unarchiveObjectWithData:tempArchive];
    [self.bottomView addSubview:topLineViewCopy];
    
    //If there's no item in favorite, show the second group of emotions.
    NSNumber *selectedGroup = (NSNumber *)[KMEmotionManager getSharedSettingsForKey:@"selectedGroup"];
    NSNumber *selectedPage = (NSNumber *)[KMEmotionManager getSharedSettingsForKey:@"selectedPage"];
    if (selectedGroup)
    {
        [self.bottomScrollView selectPreviousGroup];
        if (selectedPage)
        {
            [self.emotionsView scrollToPreviousPage];
        }
    }
    else
    {
        if ([[KMEmotionManager sharedManager] getFavoriteItemArray].count)
        {
            [self.bottomScrollView selectGroupAtIndex:0];
        }
        else
        {
            [self.bottomScrollView selectGroupAtIndex:1];
        }
    }
    
    NSNumber *bottomoffset = [[NSUserDefaults standardUserDefaults] objectForKey:@"bottomoffset"];
    [self.bottomScrollView setContentOffset:CGPointMake([bottomoffset floatValue], 0)];
}

- (void)setupTopBarView
{
    self.topBarView = [KMTopBarView new];
    self.topBarView.backgroundColor = UIColorWithRGB(253,253,253);
    [self.view addSubview:self.topBarView];
}

- (void)setupBottomView
{
    self.bottomView = [[UIView alloc] init];
    [self.bottomView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.bottomView.backgroundColor = UIColorWithRGB(253,253,253);
    [self.view addSubview:self.bottomView];
    
    [self setupSwitchButton];
    [self setupMoreButton];
    [self setupBottomScrollView];
}

- (void)setupMoreButton
{
    self.moreButton = [UIButton new];
    [self.moreButton setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [self.moreButton setImage:[UIImage imageNamed:@"add_pressed"] forState:UIControlStateHighlighted];
//    [self.moreButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.moreButton addTarget:self action:@selector(didSelectMoreButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.moreButton];
}

- (void)setupSwitchButton
{
    self.nextKeyboardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, Bottom_Bar_Height, Bottom_Bar_Height)];
    [self.nextKeyboardButton setBackgroundColor:UIColorWithRGBHex(0xf3f3f3)];
    [self.nextKeyboardButton setImage:[UIImage imageNamed:@"switch"] forState:UIControlStateNormal];
    [self.nextKeyboardButton setImage:[UIImage imageNamed:@"switch_pressed"] forState:UIControlStateHighlighted];
//    [self.nextKeyboardButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.nextKeyboardButton addTarget:self action:@selector(advanceToNextInputMode) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.nextKeyboardButton];
}

- (void)setupBottomScrollView
{
    CGFloat width = [[UIScreen mainScreen] applicationFrame].size.width;
    self.bottomScrollView = [GroupSelectView new];
    self.bottomScrollView.groupSelectViewDelegate = self;
    self.bottomScrollView.frame = CGRectMake(Bottom_Bar_Height, 0, width-Bottom_Bar_Height-More_Button_Width, Bottom_Bar_Height);
    [self.bottomScrollView setupWithGroups:self.emotionTags];
    [self.bottomView addSubview:self.bottomScrollView];
}

- (void)setupEmotionsView
{
    self.emotionsView = [KMEmotionView new];
    self.emotionsView.delegate = self;
    [self.view addSubview:self.emotionsView];
}

- (void)arrangeUI
{
    CGFloat totalWidth = [[UIScreen mainScreen] applicationFrame].size.width;
    CGFloat totalHeight = Keyboard_Height;
    
    self.topBarView.frame = CGRectMake(0, 0, totalWidth, Top_Bar_Height);
    self.bottomView.frame = CGRectMake(0, totalHeight-Bottom_Bar_Height, totalWidth, Bottom_Bar_Height);
    self.nextKeyboardButton.frame = CGRectMake(0, 0, Bottom_Bar_Height, Bottom_Bar_Height);
    self.bottomScrollView.frame = CGRectMake(Bottom_Bar_Height+1, 0, totalWidth-Bottom_Bar_Height-1-More_Button_Width, Bottom_Bar_Height);
    self.moreButton.frame = CGRectMake(totalWidth-More_Button_Width, 0, More_Button_Width, Bottom_Bar_Height);
    self.emotionsView.frame = CGRectMake(0, Top_Bar_Height, totalWidth, totalHeight-Top_Bar_Height-Bottom_Bar_Height);
}

- (void)didSelectMoreButton:(id)sender
{
    NSLog(@"%s", __func__);
    [self jumpWithURL:@"mua://go"];
}

- (void)jumpWithURL:(NSString *)urlString
{
    UIResponder* responder = self;
    while ((responder = [responder nextResponder]) != nil)
    {
        NSLog(@"responder = %@", responder);
        if([responder respondsToSelector:@selector(openURL:)] == YES)
        {
            [responder performSelector:@selector(openURL:) withObject:[NSURL URLWithString:urlString]];
        }
    }
}

#pragma mark - GroupViewDelegate

- (void)didSelectGroup:(KMEmotionTag *)tag
{
    NSLog(@"%s - %@", __func__, tag.name);
    if ([FavoriteGroupName isEqualToString:tag.name])
    {
        [self.emotionsView setupEmotionsForFavorite];
    }
    else
    {
        [self.emotionsView setupEmotionsWithGroup:tag];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        NSLog(@"%f", scrollView.contentOffset.x);
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:[NSNumber numberWithFloat:scrollView.contentOffset.x] forKey:@"bottomoffset"];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"%f", scrollView.contentOffset.x);
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:[NSNumber numberWithFloat:scrollView.contentOffset.x] forKey:@"bottomoffset"];
}

#pragma mark - KMEmotionViewDelegate

- (void)didSendEmotionWithImagePath:(NSString *)path
{
    NSLog(@"%s - %@", __func__, path);
    [self sendGifContent:path];
}


- (void)sendGifContent:(NSString *)imgPath
{
    UIImage *img = [UIImage imageWithContentsOfFile:imgPath];
    
    OSMessage *msg=[[OSMessage alloc]init];
    msg.title = @"MUA表情";
    msg.image = [[NSData alloc] initWithContentsOfFile:imgPath];
    msg.thumbnail = UIImageJPEGRepresentation(img, 0);
    msg.desc = @"分享快乐";
    
    switch (self.topBarView.shareTo) {
        case KMSharingDestination_Wechat:
//            [OpenShare shareToWeixinSession:msg Success:^(OSMessage *message) {
//                NSLog(@"微信分享到会话成功：\n%@",message);
//            } Fail:^(OSMessage *message, NSError *error) {
//                NSLog(@"微信分享到会话失败：\n%@\n%@",error,message);
//            }];
            [self jumpWithURL:[OpenShare genWeixinShareUrl:msg to:0]];
            break;
        case KMSharingDestination_QQ:
//            [OpenShare shareToQQFriends:msg Success:^(OSMessage *message) {
//                NSLog(@"QQ分享到会话成功：\n%@",message);
//            } Fail:^(OSMessage *message, NSError *error) {
//                NSLog(@"QQ分享到会话失败：\n%@\n%@",error,message);
//            }];
            [self jumpWithURL:[OpenShare genShareUrl:msg to:0]];
            break;
        case KMSharingDestination_WechatTimeline:
//            [OpenShare shareToWeixinTimeline:msg Success:^(OSMessage *message) {
//                NSLog(@"微信分享到朋友圈成功：\n%@",message);
//            } Fail:^(OSMessage *message, NSError *error) {
//                NSLog(@"微信分享到朋友圈失败：\n%@\n%@",error,message);
//            }];
            [self jumpWithURL:[OpenShare genWeixinShareUrl:msg to:1]];
            break;
    }
}

@end
