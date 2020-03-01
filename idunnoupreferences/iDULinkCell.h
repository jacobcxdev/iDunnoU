#import "iDUTableCell.h"

@interface iDULinkCell : iDUTableCell {
    NSURL *_avatarURL;
    UIView *_avatarView;
    UIImageView *_avatarImageView;
    UIImage *_avatar;
    NSString *_avatarImageSystemName;
    NSString *_accessoryImageSystemName;
    NSURL *_linkURL;
    BOOL _shouldDisplayAvatar;
}
- (void)loadAvatarIfNeeded;
- (void)setAvatar:(UIImage *)image;
- (void)setAvatarHidden:(bool)hidden;
- (void)setLinkURL:(NSURL *)url;
@end
