//
//  KMSettingViewController.m
//  Kmoji-objc
//
//  Created by yangx2 on 10/18/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMMyEmotionViewController.h"
#import "GlobalConfig.h"
#import "KMEmotionCell.h"
#import "KMDownloadedEmotionViewController.h"
#import "KMEmotionManager.h"

@interface KMMyEmotionViewController ()
{
}

@property (nonatomic, weak) NSArray *downloadedEmotions;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, weak) IBOutlet UIScrollView *favoriteScrollView;
@property (nonatomic, strong) KMEmotionGridView *favoriteView;

@end

@implementation KMMyEmotionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _downloadedEmotions = [KMEmotionManager sharedManager].downloadedEmotionInfo;
    _favoriteView = [KMEmotionGridView new];
    _favoriteView.delegate = self;
    [_favoriteScrollView addSubview:_favoriteView];
    
    [self selectSegmentIndex:0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
    NSDictionary *selectedEmotion = [[KMEmotionManager sharedManager] selectedEmotion];
    NSUInteger index = [[[KMEmotionManager sharedManager] downloadedEmotionInfo] indexOfObject:selectedEmotion];
    if (NSNotFound != index)
    {
        [self selectSegmentIndex:0];
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [[KMEmotionManager sharedManager] setSelectedEmotion:nil];
    }
}

- (void)viewDidLayoutSubviews
{
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
    CGFloat topOffset = isLandscape?32.0f:64.0f;
    
    self.favoriteView.frame = CGRectMake(HorizontalMargin, topOffset+20, self.view.bounds.size.width-HorizontalMargin*2, self.view.bounds.size.height-topOffset-49-10);
    [self.favoriteView layoutEmotionButtons];
    CGRect frame = self.favoriteView.frame;
    self.favoriteScrollView.contentSize = CGSizeMake(frame.size.width, CGRectGetMaxY(frame) + 10 + 49);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleEditing
{
    if (self.segmentControl.selectedSegmentIndex == 0)
    {
        if ([self.tableView isEditing])
        {
            [self.editButton setTitle:@"编辑"];
            [self.tableView setEditing:NO animated:YES];
        }
        else
        {
            [self.editButton setTitle:@"完成"];
            [self.tableView setEditing:YES animated:YES];
        }
    }
    else
    {
        if ([self.favoriteView isEditing])
        {
            [self.editButton setTitle:@"编辑"];
            [self.favoriteView setIsEditing:NO];
        }
        else
        {
            [self.editButton setTitle:@"取消"];
            [self.favoriteView setIsEditing:YES];
        }
    }
}

- (IBAction)selectSegment:(id)sender
{
    UISegmentedControl *segControl = (UISegmentedControl *)sender;
    [self selectSegmentIndex:segControl.selectedSegmentIndex];
}

- (void)selectSegmentIndex:(NSInteger)index
{
    if (index == 0)
    {
        [self.favoriteScrollView setHidden:YES];
    }
    else
    {
        NSArray *favoriteEmotionArray = [[KMEmotionManager sharedManager] getFavoriteEmotionArray];
        [_favoriteView setDisplayType:GridViewType_Favorite];
        [_favoriteView setUpEmotionsWithArray:favoriteEmotionArray];
        [self.favoriteScrollView setHidden:NO];
    }
    [self.segmentControl setSelectedSegmentIndex:index];
    [self.editButton setTitle:@"编辑"];
    [self.tableView setEditing:NO animated:YES];
    [self.favoriteView setIsEditing:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.downloadedEmotions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KMEmotionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadedCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *dict = self.downloadedEmotions[indexPath.row];
    NSString *folder = dict[@"folder"];
    NSString *name = dict[@"name"];
    NSString *coverImgPath = [NSString stringWithFormat:@"%@/%@/%@", sharedEmotionsDirURL.path, folder, CoverImageName];
    UIImage *coverImg = [UIImage imageWithContentsOfFile:coverImgPath];
    cell.emotionName.text = name;
    cell.shortDecription.text = dict[@"desc"];
    [cell.coverImage setImage:coverImg];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    return HeightForCell;
}

// For 8.0 and later.
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        [[KMEmotionManager sharedManager] deleteEmotion:self.downloadedEmotions[indexPath.row]];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    return @[deleteAction];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = self.downloadedEmotions[indexPath.row];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    KMDownloadedEmotionViewController *emotionDetatilView = (KMDownloadedEmotionViewController *)[storyboard instantiateViewControllerWithIdentifier:@"downloadedEmotion"];
    [emotionDetatilView setEmotionInfo:dict];
    [self.navigationController pushViewController:emotionDetatilView animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

// For 7.0.
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [[KMEmotionManager sharedManager] deleteEmotion:self.downloadedEmotions[indexPath.row]];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [[KMEmotionManager sharedManager] moveEmotionFromIndex:(int)fromIndexPath.row toIndex:(int)toIndexPath.row];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

#pragma mark - KMEmotionGridViewDelegate

- (void)didFinishEditing
{
    [self.editButton setTitle:@"编辑"];
}

@end
