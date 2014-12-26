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

NSURL *containerURL;
NSURL *sharedDirURL;
NSURL *sharedPlistURL;
NSURL *sharedEmotionsDirURL;
NSURL *emotionsDirURL;
NSURL *favoritePlistURL;

#define Keyboard_Height 216.0f
#define Bottom_Bar_Height 37.0f
#define More_Button_Width 60.0f

@interface KeyboardViewController () <GroupSelectViewDelegate, WXApiDelegate>
{
    BOOL needInformUserLater;
}

@property (nonatomic, strong) NSArray *plistData;
@property (nonatomic, strong) NSArray *groupArray;
@property (nonatomic, strong) KMEmotionView *emotionsView;
@property (nonatomic, strong) UIButton *nextKeyboardButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) GroupSelectView *bottomScrollView;
@property (nonatomic, strong) UIView *topLineView;
@property (nonatomic, strong) UIWebView *webView;

@end

@implementation KeyboardViewController

- (void)updateViewConstraints {
    [super updateViewConstraints];
    // Add custom view sizing constraints here
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [WXApi registerApp:@"wxb692717f834207df"];
    self.webView = [[UIWebView alloc] init];
    
    containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:AppGroupID];
    sharedDirURL = [NSURL URLWithString:@"Library/Caches/" relativeToURL:containerURL];
    sharedPlistURL = [NSURL URLWithString:@"emotions.plist" relativeToURL:sharedDirURL];
    sharedEmotionsDirURL = [NSURL URLWithString:@"emotions/" relativeToURL:sharedDirURL];
    favoritePlistURL = [NSURL URLWithString:@"favorite.plist" relativeToURL:sharedDirURL];
    NSLog(@"Shared Directory: %@", sharedDirURL.path);
    
    [self readEmotionData];
    
    // Perform custom UI setup here
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __func__);
    [super viewWillAppear:animated];
    
    NSLayoutConstraint *_heightConstraint =
    [NSLayoutConstraint constraintWithItem: self.view
                                 attribute: NSLayoutAttributeHeight
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: nil
                                 attribute: NSLayoutAttributeNotAnAttribute
                                multiplier: 0.0
                                  constant: Keyboard_Height];
    [self.view addConstraint: _heightConstraint];
    
    NSNumber *bottomoffset = [[NSUserDefaults standardUserDefaults] objectForKey:@"bottomoffset"];
    [self.bottomScrollView setContentOffset:CGPointMake([bottomoffset floatValue], 0)];
}

- (void)viewDidLayoutSubviews
{
    CGRect frame = self.view.frame;
    if (needInformUserLater && CGRectGetWidth(frame) && CGRectGetHeight(frame))
    {
        [[YLCToastManager sharedInstance] showToastWithStyle:YLCToastTypeConfirm message:@"请确认设置->通用->键盘->MUA表情键盘->允许完全访问功能已打开。" onView:self.emotionsView];
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
    NSError *error = nil;
    [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sharedDirURL.path error:&error];
    if (!error && [[NSFileManager defaultManager] fileExistsAtPath:sharedPlistURL.path])
    {
        self.plistData = [NSArray arrayWithContentsOfFile:sharedPlistURL.path];
        NSLog(@"Data: %@", self.plistData);
        
        NSMutableArray *groupArray = [NSMutableArray new];
        //First group should be the favorite
        [groupArray addObject:FavoriteGroupName];
        for (NSDictionary *dict in self.plistData)
        {
            NSString *groupName = dict[@"folder"];
            if (groupName)
            {
                [groupArray addObject:groupName];
            }
        }
        self.groupArray = groupArray;
        return YES;
    }
    else
    {
        NSLog(@"Fail to access shared resource with error: %@.", error);
        if (257 == error.code)
        {
            needInformUserLater = YES;
        }
        return NO;
    }
}

- (void)setupUI
{
    [self setupBottomView];
    [self setupEmotionsView];
    [self arrangeUI];

    CGFloat viewWidth = [UIScreen mainScreen].applicationFrame.size.width;
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 0.5)];
    [topLineView setBackgroundColor:UIColorWithRGB(180, 197, 207)];
    [topLineView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.view addSubview:topLineView];
    NSData *tempArchive = [NSKeyedArchiver archivedDataWithRootObject:topLineView];
    UIView *topLineViewCopy = [NSKeyedUnarchiver unarchiveObjectWithData:tempArchive];
    [self.bottomView addSubview:topLineViewCopy];
    
    //If there's no item in favorite, show the second group of emotions.
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSNumber *selectedGroup = (NSNumber *)[ud valueForKey:@"selectedGroup"];
    NSNumber *selectedPage = (NSNumber *)[ud valueForKey:@"selectedPage"];
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
        if (self.emotionsView.favoriteEmotionArray.count)
        {
            [self.bottomScrollView selectGroupAtIndex:0];
        }
        else
        {
            [self.bottomScrollView selectGroupAtIndex:1];
        }
    }
}

- (void)setupBottomView
{
    self.bottomView = [[UIView alloc] init];
//    [self.bottomView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.bottomView.backgroundColor = UIColorWithRGB(243, 248, 250);
    [self.view addSubview:self.bottomView];
    
    [self setupSwitchButton];
    [self setupMoreButton];
    [self setupBottomScrollView];
}

- (void)setupMoreButton
{
    self.moreButton = [[UIPureColorButton alloc] initWithBgColor:UIColorWithRGB(255, 135, 0) highlightedColor:UIColorWithRGB(236, 102, 0)];
    [self.moreButton setImage:[UIImage imageNamed:@"btn_add"] forState:UIControlStateNormal];
//    [self.moreButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.moreButton addTarget:self action:@selector(didSelectMoreButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.moreButton];
}

- (void)setupSwitchButton
{
    self.nextKeyboardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, Bottom_Bar_Height, Bottom_Bar_Height)];
    [self.nextKeyboardButton setBackgroundImage:[UIImage imageNamed:@"btn_switch"] forState:UIControlStateNormal];
//    [self.nextKeyboardButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.nextKeyboardButton addTarget:self action:@selector(advanceToNextInputMode) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.nextKeyboardButton];
}

- (void)setupBottomScrollView
{
    CGFloat width = [[UIScreen mainScreen] applicationFrame].size.width;
    self.bottomScrollView = [GroupSelectView new];
    self.bottomScrollView.delegate = self;
    self.bottomScrollView.frame = CGRectMake(Bottom_Bar_Height, 0, width-Bottom_Bar_Height-More_Button_Width, Bottom_Bar_Height);
    [self.bottomScrollView setupWithGroups:self.groupArray];
    [self.bottomView addSubview:self.bottomScrollView];
}

- (void)setupEmotionsView
{
    self.emotionsView = [KMEmotionView new];
    [self.view addSubview:self.emotionsView];
}

- (void)arrangeUI
{
    CGFloat totalWidth = [[UIScreen mainScreen] applicationFrame].size.width;
    CGFloat totalHeight = Keyboard_Height;
    
    self.bottomView.frame = CGRectMake(0, totalHeight-Bottom_Bar_Height, totalWidth, Bottom_Bar_Height);
    self.nextKeyboardButton.frame = CGRectMake(0, 0, Bottom_Bar_Height, Bottom_Bar_Height);
    self.bottomScrollView.frame = CGRectMake(Bottom_Bar_Height, 0, totalWidth-Bottom_Bar_Height-More_Button_Width, Bottom_Bar_Height);
    self.moreButton.frame = CGRectMake(totalWidth-More_Button_Width, 0, More_Button_Width, Bottom_Bar_Height);
    self.emotionsView.frame = CGRectMake(0, 0, totalWidth, totalHeight-Bottom_Bar_Height);
}

- (void)didSelectMoreButton:(id)sender
{
    NSLog(@"%s", __func__);
    [self goToContainingApp];
}

- (void)goToContainingApp
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"wx689fb6eef31dc0b2://go"]];
    [self.webView loadRequest:request];
}

#pragma mark GroupViewDelegate

- (void)didSelectGroupWithName:(NSString *)groupName
{
    NSLog(@"%s - %@", __func__, groupName);
    if ([FavoriteGroupName isEqualToString:groupName])
    {
        [self.emotionsView setupEmotionsForFavorite];
    }
    else
    {
        [self.emotionsView setupEmotionsWithGroupName:groupName];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"%f", scrollView.contentOffset.x);
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:[NSNumber numberWithFloat:scrollView.contentOffset.x] forKey:@"bottomoffset"];
}

//- (void)addConstraintForBottomView
//{
//    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:37.0];
//    
//    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
//    [self.bottomView addConstraint:heightConstraint];
//    [self.view addConstraints:@[leftConstraint, rightConstraint, bottomConstraint]];
//}
//
//- (void)addConstraintForEmotionsView
//{
//    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.emotionsView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.emotionsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.emotionsView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.emotionsView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
//    
//    [self.view addConstraints:@[topConstraint, bottomConstraint, leftConstraint, rightConstraint]];
//}
//
//- (void)addConstraintForSwitchButton
//{
//    NSLayoutConstraint *widthEqualHeightConstraint = [NSLayoutConstraint constraintWithItem:self.nextKeyboardButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.nextKeyboardButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.nextKeyboardButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.nextKeyboardButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.nextKeyboardButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.bottomScrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.nextKeyboardButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
//    [self.bottomView addConstraints:@[widthEqualHeightConstraint, heightConstraint, leftConstraint, rightConstraint, bottomConstraint]];
//}
//
//- (void)addConstraintForBottomScrollView
//{
//    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomScrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.bottomScrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.nextKeyboardButton attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomScrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.moreButton attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomScrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
//    [self.bottomView addConstraints:@[heightConstraint, leftConstraint, rightConstraint, bottomConstraint]];
//}
//
//- (void)addConstraintForMoreButton
//{
//    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.moreButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:60.0];
//    
//    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.moreButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.moreButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.bottomScrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.moreButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
//    
//    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.moreButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
//    [self.moreButton addConstraint:widthConstraint];
//    [self.bottomView addConstraints:@[heightConstraint, leftConstraint, rightConstraint, bottomConstraint]];
//}

@end
