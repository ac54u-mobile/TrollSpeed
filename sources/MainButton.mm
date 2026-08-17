//
//  MainButton.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import "MainButton.h"

@implementation MainButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (UIAccessibilityIsReduceMotionEnabled()) {
        self.alpha = highlighted ? 0.72 : 1.0;
        return;
    }
    if (highlighted)
    {
        [UIView animateWithDuration:0.20 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.transform = CGAffineTransformMakeScale(0.96, 0.96);
        } completion:nil];
    }
    else
    {
        [UIView animateWithDuration:0.24 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

@end
