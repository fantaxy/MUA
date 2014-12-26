//
//  KMSettingViewController.m
//  Kmoji-objc
//
//  Created by yangx2 on 11/23/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMSettingViewController.h"

typedef NS_ENUM(NSUInteger, KMSettingCellTag) {
    KMSettingCell_Install,
    KMSettingCell_Usage,
    KMSettingCell_Thanks
};

@interface KMSettingViewController ()

@property (nonatomic, strong) NSArray *sectionArray;
@property (nonatomic, strong) UIAlertView *installAlertView;
@property (nonatomic, strong) UIAlertView *usageAlertView;
@property (nonatomic, strong) UIAlertView *thanksAlertView;

@end

@implementation KMSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UITableViewCell *installCell = [self createCellWithTitle:@"安装方法" tag:KMSettingCell_Install];
    UITableViewCell *usageCell = [self createCellWithTitle:@"使用方法" tag:KMSettingCell_Usage];
    NSArray *instructionSection = @[installCell, usageCell];
    
    UITableViewCell *thanksCell = [self createCellWithTitle:@"鸣谢" tag:KMSettingCell_Thanks];
    NSArray *thanksSection = @[thanksCell];
    
    self.installAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"在iOS8系统上，进入设置->通用->键盘->添加新键盘->MUA,再次选择MUA表情键盘并打开允许完全访问。" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
    self.usageAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"下载你喜欢的表情后，打开微信聊天窗口,切换输入法至MUA表情键盘,即可发送你已下载的表情。" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
    self.thanksAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"当你看到这段文字时,相信你跟我们一样是聊天表情的爱好者,同时也是我们最信任的朋友,衷心感谢您的使用,如果您对MUA表情有任何意见和建议,欢迎加入我们的微信用户群和我们交流。" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
    
    _sectionArray = @[instructionSection, thanksSection];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return _sectionArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return ((NSArray *)_sectionArray[section]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _sectionArray[indexPath.section][indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    switch (cell.tag)
    {
        case KMSettingCell_Install:
        {
            [self.installAlertView show];
            break;
        }
        case KMSettingCell_Usage:
        {
            [self.usageAlertView show];
            break;
        }
        case KMSettingCell_Thanks:
        {
            [self.thanksAlertView show];
            break;
        }
            
        default:
            break;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
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

- (UITableViewCell *)createCellWithTitle:(NSString *)title tag:(KMSettingCellTag)tag
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingCell"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = title;
    cell.tag = tag;
    return cell;
}

@end
