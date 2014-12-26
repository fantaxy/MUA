//
//  YLCToastManager.m
//  clientUI
//
//  Created by chaowei on 14-1-21.
//
//

#import "YLCToastManager.h"

@implementation YLCToastView

- (id)initWithType:(YLCToastType)type message:(NSString *)message
{
    self = [super init];
    if (self)
    {
        self.backgroundView = [UIView new];
        self.backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.9];
        self.backgroundView.layer.cornerRadius = 6.f;
        
        [self addSubview:self.backgroundView];
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.textColor = [UIColor whiteColor];
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.text = message;
        
        [self.backgroundView addSubview:self.messageLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat maxWidth,minWidth,minHeight,horiMargin,vertMargin;
    
    {
        maxWidth = 190.f;
        minWidth = 110.f;
        minHeight = 95.f;
        horiMargin = 20.f;
        vertMargin = 15.f;
    }
    
    CGSize messageSingleLineSize = [self.messageLabel.text sizeWithAttributes:@{NSFontAttributeName: self.messageLabel.font}];
    CGRect messageLabelFrame = [self.messageLabel.text boundingRectWithSize:CGSizeMake(maxWidth - 2*horiMargin, FLT_MAX)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                 attributes:@{NSFontAttributeName:self.messageLabel.font}
                                                                    context:nil];
    CGFloat width,height;
    if (messageSingleLineSize.width < maxWidth-2*horiMargin) //Message is single line
    {
        width = MAX(messageSingleLineSize.width+2*horiMargin,minWidth);
        height = 2*vertMargin+messageSingleLineSize.height;
    }
    else
    {
        width = maxWidth;
        height = 2*vertMargin+CGRectGetHeight(messageLabelFrame);
    }
    
    height = MAX(height,minHeight);
    self.backgroundView.frame = CGRectMake(0.f,0.f,width,height);
    self.backgroundView.center = self.center;
    
    messageLabelFrame.origin.x = (CGRectGetWidth(self.backgroundView.bounds)-messageLabelFrame.size.width)/2;
    messageLabelFrame.origin.y = (CGRectGetHeight(self.backgroundView.bounds)-messageLabelFrame.size.height)/2;
    self.messageLabel.frame = messageLabelFrame;
}

@end


const NSTimeInterval toastDisappearTimer = 1.;

@interface YLCToastManager()

@property (nonatomic,retain) YLCToastView *toastView;
@property (nonatomic,retain) NSTimer *dismissTimer;

@end

@implementation YLCToastManager

+ (YLCToastManager *)sharedInstance
{
    static YLCToastManager *instance;
    if (instance == nil)
    {
        instance = [[YLCToastManager alloc] init];
    }
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

- (void)showToastWithStyle:(YLCToastType)type message:(NSString *)message onView:(UIView *)targetView autoDismiss:(BOOL)autoDismiss
{
    if (self.toastView)
    {
        [self dismissToastView];
    }
    
    self.toastView = [[YLCToastView alloc] initWithType:type message:message];
    
    self.toastView.frame = targetView.frame;
    [targetView addSubview:self.toastView];
    
    self.toastView.alpha = 0.f;
    [UIView animateWithDuration:.2 animations:^(void){
        self.toastView.alpha = 1.f;
    }];
    
    if (autoDismiss)
    {
        self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:toastDisappearTimer target:self selector:@selector(dismissToastView) userInfo:nil repeats:NO];
    }
}

-(void)showToastWithStyle:(YLCToastType)type message:(NSString *)message onView:(UIView *)targetView
{
    [self showToastWithStyle:type message:message onView:targetView autoDismiss:NO];
}

- (void)dismissToastView
{
    if (self.toastView == nil)
        return;
    
    [self.dismissTimer invalidate];
    self.dismissTimer = nil;
    
    [self.toastView removeFromSuperview];
    self.toastView = nil;
}

- (BOOL)isToastShown
{
    return self.toastView.superview != nil;
}

@end