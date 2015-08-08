//
//  KMTableViewController.m
//  Kmoji-objc
//
//  Created by yangx2 on 10/7/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMTableViewController.h"
#import "GlobalConfig.h"
#import "KMEmotionCell.h"
#import "KMEmotionDownloadViewController.h"
#import "KMDownloadedEmotionViewController.h"
#import "WXApi.h"
#import "UIImage+animatedGIF.h"
#import "UIPureColorButton.h"
#import "KMEmotionManager.h"
#import "KMEmotionTag.h"
#import "KMURLHelper.h"

#import "UIRefreshControl+AFNetworking.h"
#import "UIAlertView+AFNetworking.h"
#import "UIImageView+AFNetworking.h"

@interface KMTableViewController () <WXApiDelegate>
{
    KMEmotionManager *_emotionManager;
}

//@property (nonatomic, weak) IBOutlet UIScrollView *bannerScrollView;
@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation KMTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self performSelector:@selector(crash) withObject:nil];
    
    self.refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, 100.0f)];
    [self.refreshControl addTarget:self action:@selector(reload:) forControlEvents:UIControlEventValueChanged];
    [self.tableView.tableHeaderView addSubview:self.refreshControl];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],NSFontAttributeName:[UIFont fontWithName:@"ArialMT" size:18.0]}];
    
    _emotionManager = [KMEmotionManager sharedManager];
    self.dataSource = [_emotionManager getEmotionTags];
    [self initializeUI];
    
    [self reload:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initializeUI
{
    UITabBar *tabBar = self.tabBarController.tabBar;
    [tabBar setTintColor:BLUE_COLOR];
    
    UITabBarItem *tabBarItem = [[tabBar items] objectAtIndex:0];
    UIImage *selectedIcon = [UIImage imageNamed:@"mua_selected"];
    [tabBarItem setSelectedImage:selectedIcon];
    
    tabBarItem = [[tabBar items] objectAtIndex:1];
    selectedIcon = [UIImage imageNamed:@"my_selected"];
    [tabBarItem setSelectedImage:selectedIcon];
    
    tabBarItem = [[tabBar items] objectAtIndex:2];
    selectedIcon = [UIImage imageNamed:@"setting_selected"];
    [tabBarItem setSelectedImage:selectedIcon];
    
    for (UITabBarItem *item in [tabBar items]) {
        [item setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:TABBAR_TITLE_FONT_SIZE], NSForegroundColorAttributeName:BLACK_COLOR} forState:UIControlStateNormal];
        [item setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:TABBAR_TITLE_FONT_SIZE], NSForegroundColorAttributeName:BLUE_COLOR} forState:UIControlStateSelected];
    }
}

- (void)reload:(id)sender
{
    NSURLSessionTask *task = [_emotionManager createRefreshTaskWithCompletionBlock:^(NSError *error) {
        if (!error) {
            self.dataSource = [_emotionManager getEmotionTags];
            [self.tableView reloadData];
        }
        else {
            NSLog(@"%@", error);
        }
    }];
    
    [UIAlertView showAlertViewForTaskWithErrorOnCompletion:task delegate:nil];
    [self.refreshControl setRefreshingWithStateOfTask:task];
}

- (IBAction)onDownloadBtnClicked:(id)sender
{
    KMEmotionCell *cell = (KMEmotionCell *)[[(UIButton *)sender superview] superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [[KMEmotionManager sharedManager] downloadEmotionTagWithIndex:indexPath.row];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KMEmotionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"emotionCell" forIndexPath:indexPath];
    
    // Configure the cell...
    KMEmotionTag *tag = self.dataSource[indexPath.row];
//    NSString *coverImgPath = [NSString stringWithFormat:@"%@/%@", emotionsDirURL.path, tag.thumbName];
//    UIImage *coverImg = [UIImage imageWithContentsOfFile:coverImgPath];
    cell.emotionName.text = tag.name;
    cell.shortDecription.text = tag.desc;
    [[KMEmotionManager sharedManager] getImageWithName:tag.thumbName completionBlock:^(NSString *imagePath, NSError *error) {
        if (!error) {
            UIImage *coverImg = [UIImage imageWithContentsOfFile:imagePath];
            [cell.coverImageView setImage:coverImg];
        }
    }];
    if ([[[KMEmotionManager sharedManager] getDownloadedEmotionTags] containsObject:tag])
    {
        [cell.downloadButton setHidden:YES];
        [cell.checkmark setHidden:NO];
    }
    else
    {
        [cell.downloadButton setHidden:NO];
        [cell.checkmark setHidden:YES];
    }
    return cell;
}    
    
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return HeightForCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KMEmotionTag *tag = [_emotionManager getEmotionTagWithIndex:indexPath.row];
    UIViewController *vc = nil;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    if ([tag isDownloaded]) {
        KMDownloadedEmotionViewController *emotionDetatilView = (KMDownloadedEmotionViewController *)[storyboard instantiateViewControllerWithIdentifier:@"downloadedEmotion"];
        [emotionDetatilView setEmotionTag:tag];
        vc = emotionDetatilView;
    }
    else {
        KMEmotionDownloadViewController *emotionDownloadView = (KMEmotionDownloadViewController *)[storyboard instantiateViewControllerWithIdentifier:@"downloadPage"];
        [emotionDownloadView setEmotionTag:tag];
        vc = emotionDownloadView;
    }
    [self.navigationController pushViewController:vc animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
