//
//  YLCToastManager.h
//  clientUI
//
//  Created by chaowei on 14-1-21.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef enum
{
    YLCToastTypeConfirm,
    YLCToastTypeWarning,
    YLCToastTypeConnecting,
    YLCToastTypeLoading
} YLCToastType;

@interface YLCToastView : UIView

@property (nonatomic,retain) UIView *backgroundView;
@property (nonatomic,retain) UIImageView *iconView;
@property (nonatomic,retain) UILabel *messageLabel;

- (id)initWithType:(YLCToastType)type message:(NSString *)message;

@end

@interface YLCToastManager : NSObject

+ (YLCToastManager *)sharedInstance;

//A self-managed toast that will disappear on receiving notifications if it's set or disappear after a period of time if notification is set to nil
- (void)showToastWithStyle:(YLCToastType)type message:(NSString *)message onView:(UIView *)targetView autoDismiss:(BOOL)autoDismiss;



//Show a toast that will never dismissed by itself, need to be dismissed manually
- (void)showToastWithStyle:(YLCToastType)type message:(NSString *)message onView:(UIView *)targetView;
//dismissToast will dismiss toast forcely, recommend to work with
- (void)dismissToastView;

- (BOOL)isToastShown;

@end
