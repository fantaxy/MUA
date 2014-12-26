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
#import "WXApi.h"
#import "UIImage+animatedGIF.h"
#import "UIPureColorButton.h"
#import "KMEmotionManager.h"

@interface KMTableViewController () <WXApiDelegate>
{
    KMEmotionManager *_emotionManager;
}

//@property (nonatomic, weak) IBOutlet UIScrollView *bannerScrollView;

@end

@implementation KMTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _emotionManager = [KMEmotionManager sharedManager];
    [WXApi registerApp:@"wx689fb6eef31dc0b2"];
    [self initializeUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initializeUI
{
    UITabBar *tabBar = self.tabBarController.tabBar;
    [tabBar setTintColor:UIColorWithRGB(255, 126, 0)];
    
    UITabBarItem *tabBarItem = [[tabBar items] objectAtIndex:0];
    UIImage *selectedIcon = [UIImage imageNamed:@"MUA_selected"];
    [tabBarItem setSelectedImage:selectedIcon];
    
    tabBarItem = [[tabBar items] objectAtIndex:1];
    selectedIcon = [UIImage imageNamed:@"my_selected"];
    [tabBarItem setSelectedImage:selectedIcon];
    
    tabBarItem = [[tabBar items] objectAtIndex:2];
    selectedIcon = [UIImage imageNamed:@"setting_selected"];
    [tabBarItem setSelectedImage:selectedIcon];
}

- (IBAction)onDownloadBtnClicked:(id)sender
{
    KMEmotionCell *cell = (KMEmotionCell *)[[(UIButton *)sender superview] superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath.row < _emotionManager.emotionsData.count)
    {
        NSDictionary *dict = _emotionManager.emotionsData[indexPath.row];
        [_emotionManager downloadEmotion:dict];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _emotionManager.emotionsData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KMEmotionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"emotionCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *dict = _emotionManager.emotionsData[indexPath.row];
    NSString *folder = dict[@"folder"];
    NSString *name = dict[@"name"];
    NSString *coverImgPath = [NSString stringWithFormat:@"%@/%@/%@", emotionsDirURL.path, folder, CoverImageName];
    UIImage *coverImg = [UIImage imageWithContentsOfFile:coverImgPath];
    cell.emotionName.text = name;
    cell.shortDecription.text = dict[@"desc"];
    [cell.coverImage setImage:coverImg];
    if ([_emotionManager.downloadedEmotionInfo containsObject:dict])
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
    NSDictionary *dict = _emotionManager.emotionsData[indexPath.row];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    KMEmotionDownloadViewController *emotionDetatilView = (KMEmotionDownloadViewController *)[storyboard instantiateViewControllerWithIdentifier:@"downloadPage"];
    [emotionDetatilView setEmotionInfo:dict];
    [self.navigationController pushViewController:emotionDetatilView animated:YES];
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
