//
//  ControllerSetting.h
//  iOrange
//
//  Created by Yoon on 8/13/15.
//  Copyright © 2015 yinxiangkai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ControllerBase.h"

@interface ControllerSetting : ControllerBase

@property (weak, nonatomic,readonly) IBOutlet UIView *ViewContain;
@property (weak, nonatomic,readonly) IBOutlet UIView *ViewSettingSum;
@property (weak, nonatomic,readonly) IBOutlet UIView *viewBottom;
@property (weak, nonatomic,readonly) IBOutlet UIButton *buttonDown;
@property (nonatomic,strong,readonly) UIScrollView *scrollViewSetting;
@property (weak, nonatomic) id delegateMian;

- (void)showSettingView:(void(^)())completion;

@end
