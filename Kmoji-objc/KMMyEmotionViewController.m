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
#import "KMEmotionTag.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface KMMyEmotionViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate>
{
}

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, weak) IBOutlet UIScrollView *favoriteScrollView;
@property (nonatomic, strong) KMEmotionGridView *favoriteView;
@property (nonatomic, strong, readonly) NSArray *emotionTags;
@property (nonatomic, strong) NSData *importedImageData;

@end

@implementation KMMyEmotionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _favoriteView = [KMEmotionGridView new];
    _favoriteView.delegate = self;
    [_favoriteScrollView addSubview:_favoriteView];
    self.navigationController.navigationBar.barTintColor = BLUE_COLOR;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    [self selectSegmentIndex:0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
    KMEmotionTag *selectedEmotion = [[KMEmotionManager sharedManager] selectedEmotion];
    NSUInteger index = [self.emotionTags indexOfObject:selectedEmotion];
    if (NSNotFound != index)
    {
        [self selectSegmentIndex:0];
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [[KMEmotionManager sharedManager] setSelectedEmotion:nil];
    }
}

- (void)viewDidLayoutSubviews
{
    self.favoriteView.frame = CGRectInset(self.view.bounds, 20, 20);
    [self.favoriteView layoutEmotionTiles];
    CGRect frame = self.favoriteView.frame;
    self.favoriteScrollView.contentSize = CGSizeMake(frame.size.width, CGRectGetMaxY(frame) + 10 + 49);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)emotionTags
{
    return [[KMEmotionManager sharedManager] getDownloadedEmotionTags];
}

- (IBAction)toggleEditing
{
    if (self.segmentControl.selectedSegmentIndex == 0)
    {
        if ([self.tableView isEditing])
        {
            [self.editButton setTitle:@"编辑"];
            [self.editButton setStyle:UIBarButtonItemStyleBordered];
            [self.tableView setEditing:NO animated:YES];
        }
        else
        {
            [self.editButton setTitle:@"完成"];
            [self.editButton setStyle:UIBarButtonItemStyleDone];
            [self.tableView setEditing:YES animated:YES];
        }
    }
    else
    {
        if ([self.favoriteView isEditing])
        {
            [self.editButton setTitle:@"编辑"];
            [self.editButton setStyle:UIBarButtonItemStyleBordered];
            [self.favoriteView setIsEditing:NO];
        }
        else
        {
            [self.editButton setTitle:@"取消"];
            [self.favoriteView setIsEditing:YES];
        }
    }
}

- (IBAction)onAddBtnClicked:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *imagePicker = [UIImagePickerController new];
        imagePicker.delegate = self;
        imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [self presentViewController:imagePicker animated:YES completion:^{
            
        }];
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
    [self.editButton setStyle:UIBarButtonItemStyleBordered];
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
    return self.emotionTags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KMEmotionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadedCell" forIndexPath:indexPath];
    
    // Configure the cell...
    KMEmotionTag *tag = self.emotionTags[indexPath.row];
    NSString *name = tag.name;
    NSString *coverImgPath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, tag.thumbName];
    UIImage *coverImg = [UIImage imageWithContentsOfFile:coverImgPath];
    cell.emotionName.text = name;
    cell.shortDecription.text = tag.desc;
    [cell.coverImageView setImage:coverImg];
    
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
        [[KMEmotionManager sharedManager] deleteEmotionTag:self.emotionTags[indexPath.row]];
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
    KMEmotionTag *tag = self.emotionTags[indexPath.row];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    KMDownloadedEmotionViewController *emotionDetatilView = (KMDownloadedEmotionViewController *)[storyboard instantiateViewControllerWithIdentifier:@"downloadedEmotion"];
    [emotionDetatilView setEmotionTag:tag];
    [self.navigationController pushViewController:emotionDetatilView animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

// For 7.0.
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [[KMEmotionManager sharedManager] deleteEmotionTag:self.emotionTags[indexPath.row]];
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
    [self.editButton setStyle:UIBarButtonItemStyleBordered];
}

#pragma mark - UIKitDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"请输入标签" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]){
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *representation = [asset defaultRepresentation];
            NSUInteger bufferSize = (NSUInteger)representation.size;
            Byte *buffer = (Byte*)malloc(bufferSize);
            NSUInteger buffered = [representation getBytes:buffer fromOffset:0 length:bufferSize error:nil];
            NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
            self.importedImageData = data;
        } failureBlock:^(NSError *error) {
            self.importedImageData = nil;
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        NSString *tag = [[alertView textFieldAtIndex:0] text];
        if (tag && self.importedImageData) {
            [[KMEmotionManager sharedManager] addEmotion:self.importedImageData withTag:tag];
        }
    }
    [self.tableView reloadData];
}

@end
