//
//  Tweak.h
//  iDunnoU
//
//  Created by Jacob Clayden on 05/04/2020.
//  Copyright © 2020 JacobCXDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "iDUBadgeButton.h"
#import "iDUNotificationCentre.h"

// Messages Interfaces

@interface CNContact : NSObject
- (NSArray *)handles;
@end

@interface CKEntity : NSObject
- (CNContact *)cnContact;
@end

@interface CKConversation : NSObject
- (void)blacklist;
- (BOOL)isBlacklisted;
- (BOOL)isWhitelisted;
- (BOOL)isKnownSender;
- (CKEntity *)recipient;
- (void)removeFromBlacklist;
- (void)removeFromWhitelist;
- (NSString *)uniqueIdentifier;
- (unsigned long long)unreadCount;
- (void)whitelist;
@end

@interface CKConversationList : NSObject
- (NSMutableArray *)conversations;
@end

@interface CKConversationListCell : UITableViewCell
- (CKConversation *)conversation;
@end

@interface CKConversationListController : UITableViewController<UITableViewDelegate, UITableViewDataSource>
- (void)_chatUnreadCountDidChange:(NSNotification *)notification;
- (void)_toggleShowUnknownArray;
- (CKConversationList *)conversationList;
- (void)toggleShowUnknownArray;
- (void)updateConversationList;
@end

@interface CNContactToggleBlockCallerAction : NSObject
- (BOOL)isBlocked;
- (void)block;
- (void)unblock;
- (instancetype)initWithContact:(CNContact *)contact;
@end

@interface SMSApplication : UIApplication<UIApplicationDelegate>
- (void)applicationWillTerminate;
- (NSInteger)applicationIconBadgeNumber;
- (void)setApplicationBadgeString:(id)string;
- (void)setApplicationIconBadgeNumber:(NSInteger)number;
@end

// IMAgent Interfaces

@interface IMDBadgeUtilities : NSObject
- (void)updateBadgeForUnreadCountChangeIfNeeded:(long long)count;
@end

// TCCd Interfaces

@interface TCCDService : NSObject
@property (retain, nonatomic) NSString *name;
- (void)setDefaultAllowedIdentifiersList:(NSArray *)list;
@end

// SpringBoard Interfaces

@interface SpringBoard : NSObject
- (BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)event;
- (void)_ringerChanged:(void *)event;
@end