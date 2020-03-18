#import "iDUBadgeButton.h"

@implementation iDUBadgeButton
- (instancetype)init {
    self = [super init];
    [self setup];
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [self setup];
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setup];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [_badgeLabel sizeToFit];
    CGFloat height = MAX(18, (CGFloat)_badgeLabel.frame.size.height + 5.0);
    CGFloat width = MAX(height, (CGFloat)_badgeLabel.frame.size.width + 10.0);
    _badgeLabel.frame = CGRectMake(self.frame.size.width - 5, -_badgeLabel.frame.size.height / 2, width, height);
    _badgeLabel.layer.cornerRadius = _badgeLabel.frame.size.height / 2;
    _badgeLabel.layer.masksToBounds = true;
}
- (void)setup {
    _badgeLabel = [[UILabel alloc] init];
    _badgeLabel.textColor = [UIColor whiteColor];
    _badgeLabel.backgroundColor = [UIColor systemRedColor];
    _badgeLabel.textAlignment = NSTextAlignmentCenter;
    _badgeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _badgeLabel.alpha = 0;
    [self addSubview:_badgeLabel];
    [self updateBadge];
}
- (void)setBadgeCount:(NSUInteger)badgeCount {
    _badgeCount = badgeCount;
    [self updateBadge];
}
- (void)updateBadge {
    if (_badgeCount != 0) _badgeLabel.text = _badgeCount == 0 ? @" " : [NSString stringWithFormat:@"%lu", _badgeCount];
    [UIView animateWithDuration:0.25 animations:^{
        _badgeLabel.alpha = self.badgeCount == 0 ? 0 : 1;
    }];
    [self layoutSubviews];
}
@end