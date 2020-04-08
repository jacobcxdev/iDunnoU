//
//  Tweak.x
//  iDunnoU
//
//  Created by Jacob Clayden on 08/02/2020.
//  Copyright © 2020 JacobCXDev. All rights reserved.
//

#import "Tweak.h"

// Static Variables

static bool shouldShowButton = true;
static NSString *shouldShowButtonKey = @"shouldShowButton";
static bool shouldToggleWhenShaken = false;
static NSString *shouldToggleWhenShakenKey = @"shouldToggleWhenShaken";
static bool shouldToggleWhenVolumePressedSimultaneously = false;
static NSString *shouldToggleWhenVolumePressedSimultaneouslyKey = @"shouldToggleWhenVolumePressedSimultaneously";
static bool shouldToggleWhenRingerSwitched = false;
static NSString *shouldToggleWhenRingerSwitchedKey = @"shouldToggleWhenRingerSwitched";
static bool shouldHideUnknownUnreadCountFromSBBadge = false;
static NSString *shouldHideUnknownUnreadCountFromSBBadgeKey = @"shouldHideUnknownUnreadCountFromSBBadge";
static bool shouldHideButtonBadge = false;
static NSString *shouldHideButtonBadgeKey = @"shouldHideButtonBadge";
static bool shouldSecureUnknownList = false;
static NSString *shouldSecureUnknownListKey = @"shouldSecureUnknownList";
static bool showUnknownArray = false;
static NSString *showUnknownArrayKey = @"showUnknownArray";

static NSUInteger knownUnreadCount = 0;
static NSString *knownUnreadCountKey = @"knownUnreadCount";
static NSUInteger unknownUnreadCount = 0;
static NSString *unknownUnreadCountKey = @"unknownUnreadCount";

static NSMutableArray *conversationBlacklist;
static NSString *conversationBlacklistKey = @"com.jacobcxdev.idunnou.conversationBlacklist";
static NSMutableArray *conversationWhitelist;
static NSString *conversationWhitelistKey = @"com.jacobcxdev.idunnou.conversationWhitelist";

static NSString *toggleShowUnknownArrayNotificationName = @"com.jacobcxdev.idunnou.showUnknownArray.toggle";
static NSString *localUpdateNotificationName = @"com.jacobcxdev.idunnou.local.update";
static NSString *localRequestNotificationName = @"com.jacobcxdev.idunnou.local.request";
static NSString *iCloudPersistNotificationName = @"com.jacobcxdev.idunnou.iCloud.persist";
static NSString *iCloudRestoreNotificationName = @"com.jacobcxdev.idunnou.iCloud.restore";
static NSString *userDefaultsDidUpdateNotificationName = @"com.jacobcxdev.idunnou.userDefaults.didUpdate";

static NSUserDefaults *userDefaults;
static NSUbiquitousKeyValueStore *store;

static NSUInteger ringerSwitchedCount;
static NSDate *lastRingerSwitch;

static iDUNotificationCentre *notificationCentre;
static CKConversationListController *ckclc;
static IMDBadgeUtilities *imdbu;
static iDUBadgeButton *button;
static UIBarButtonItem *bbi;

// Static Functions

static void updateBadgeCount() {
    if (!button) return;
    button.badgeCount = shouldHideButtonBadge ? 0 : showUnknownArray ? knownUnreadCount : unknownUnreadCount;
}

static void restoreDefaultsState() {
    if (!userDefaults) return;
    knownUnreadCount = [userDefaults integerForKey:knownUnreadCountKey];
    unknownUnreadCount = [userDefaults integerForKey:unknownUnreadCountKey];
    conversationBlacklist = [userDefaults arrayForKey:conversationBlacklistKey] ? [[userDefaults arrayForKey:conversationBlacklistKey] mutableCopy] : [[NSMutableArray alloc] init];
    conversationWhitelist = [userDefaults arrayForKey:conversationWhitelistKey] ? [[userDefaults arrayForKey:conversationWhitelistKey] mutableCopy] : [[NSMutableArray alloc] init];
}

static void restoreiCloudState() {
    if (!store) return;
    [store synchronize];
    conversationBlacklist = [store arrayForKey:conversationBlacklistKey] ? [[store arrayForKey:conversationBlacklistKey] mutableCopy] : [[NSMutableArray alloc] init];
    conversationWhitelist = [store arrayForKey:conversationWhitelistKey] ? [[store arrayForKey:conversationWhitelistKey] mutableCopy] : [[NSMutableArray alloc] init];
}

static void persistDefaultsState() {
    if (!userDefaults) return;
    [userDefaults setBool:showUnknownArray forKey:showUnknownArrayKey];
    [userDefaults setInteger:knownUnreadCount forKey:knownUnreadCountKey];
    [userDefaults setInteger:unknownUnreadCount forKey:unknownUnreadCountKey];
    [userDefaults setObject:conversationBlacklist forKey:conversationBlacklistKey];
    [userDefaults setObject:conversationWhitelist forKey:conversationWhitelistKey];
}

static void persistiCloudState() {
    if (!store) return;
    [store setArray:conversationBlacklist forKey:conversationBlacklistKey];
    [store setArray:conversationWhitelist forKey:conversationWhitelistKey];
}

// Messages Hooks

%group Messages
%hook CKConversation
%new
- (void)blacklist {
    [conversationBlacklist addObject:[self uniqueIdentifier]];
}
%new
- (void)removeFromBlacklist {
    [conversationBlacklist removeObject:[self uniqueIdentifier]];
}
%new
- (BOOL)isBlacklisted {
    return [conversationBlacklist indexOfObject:[self uniqueIdentifier]] != NSNotFound;
}
%new
- (void)whitelist {
    [conversationWhitelist addObject:[self uniqueIdentifier]];
}
%new
- (void)removeFromWhitelist {
    [conversationWhitelist removeObject:[self uniqueIdentifier]];
}
%new
- (BOOL)isWhitelisted {
    return [conversationWhitelist indexOfObject:[self uniqueIdentifier]] != NSNotFound;
}
%end

%hook CKConversationList
- (NSMutableArray *)conversations {
    NSMutableArray *orig = %orig;
    NSMutableArray *knownArray = [[NSMutableArray alloc] init];
    NSMutableArray *unknownArray = [[NSMutableArray alloc] init];
    knownUnreadCount = 0;
    unknownUnreadCount = 0;
    for (CKConversation *conversation in orig) {
        if (([conversation isKnownSender] && ![conversation isBlacklisted]) || (![conversation isKnownSender] && [conversation isWhitelisted])) {
            [knownArray addObject:conversation];
            knownUnreadCount += [conversation unreadCount];
        } else {
            [unknownArray addObject:conversation];
            unknownUnreadCount += [conversation unreadCount];
        }
    }
    updateBadgeCount();
    [notificationCentre postNotificationUsingPostHandlerWithName:localUpdateNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
    return showUnknownArray ? unknownArray : knownArray;
}
%end

%hook CKConversationListController
- (instancetype)init {
    id orig = %orig;
    ckclc = orig;
    return orig;
}
- (void)_chatUnreadCountDidChange:(NSNotification *)notification {
    [[self conversationList] conversations];
    return %orig;
}
- (void)viewDidLayoutSubviews {
    if (shouldShowButton && !self.navigationItem.leftBarButtonItem) {
        if (!bbi) {
            if (!button) {
                button = [iDUBadgeButton buttonWithType:UIButtonTypeCustom];
                [button setImage:[UIImage systemImageNamed:@"questionmark.circle"] forState:UIControlStateNormal];
                [button setImage:[UIImage systemImageNamed:@"person.crop.circle"] forState:UIControlStateSelected];
                [button addTarget:self action:@selector(toggleShowUnknownArray) forControlEvents:UIControlEventTouchUpInside];
                button.backgroundColor = [UIColor secondarySystemFillColor];
                button.frame = CGRectMake(0, 0, 30, 30);
                button.layer.cornerRadius = 15;
            }
            bbi = [[UIBarButtonItem alloc] initWithCustomView:button];
        }
        self.navigationItem.leftBarButtonItem = bbi;
    }
    updateBadgeCount();
    return %orig;
}
%new
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    CKConversationListCell *cell = (CKConversationListCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    CKConversation *conversation = [cell conversation];
    CKEntity *recipient = [conversation recipient];
    UIContextualAction *blacklistAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:([conversation isKnownSender] && [conversation isBlacklisted]) || (![conversation isKnownSender] && ![conversation isWhitelisted]) ? @"Unhide" : @"Hide" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        if ([conversation isKnownSender]) {
            if ([conversation isBlacklisted]) [conversation removeFromBlacklist];
            else [conversation blacklist];
        } else {
            if ([conversation isWhitelisted]) [conversation removeFromWhitelist];
            else [conversation whitelist];
        }
        [self updateConversationList];
        persistDefaultsState();
        [notificationCentre postNotificationWithName:iCloudPersistNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
        completionHandler(true);
    }];
    blacklistAction.backgroundColor = [conversation isBlacklisted] || (![conversation isKnownSender] && ![conversation isWhitelisted]) ? [UIColor systemTealColor] : [UIColor systemBlueColor];
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    [actions addObject:blacklistAction];
    if (recipient && [[recipient cnContact] handles].count != 0) {
        CNContactToggleBlockCallerAction *cnBlockAction = [[%c(CNContactToggleBlockCallerAction) alloc] initWithContact:[recipient cnContact]];
        UIContextualAction *blockAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:[cnBlockAction isBlocked] ? @"Unblock" : @"Block" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            if ([cnBlockAction isBlocked]) [cnBlockAction unblock];
            else [cnBlockAction block];
            completionHandler(true);
        }];
        blockAction.backgroundColor = [cnBlockAction isBlocked] ? [UIColor systemPurpleColor] : [UIColor systemOrangeColor];
        [actions addObject:blockAction];
    }
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}
%new
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (shouldToggleWhenShaken && motion == UIEventSubtypeMotionShake) [self toggleShowUnknownArray];
}
%new
- (void)toggleShowUnknownArray {
    if (shouldSecureUnknownList && !showUnknownArray) {
        LAContext *context = [[LAContext alloc] init];
        NSError *error = nil;
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error])
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"iDunnoU" reply:^(BOOL success, NSError *error) {
                if (success) dispatch_async(dispatch_get_main_queue(), ^{
                    [self _toggleShowUnknownArray];
                });
            }];
    } else [self _toggleShowUnknownArray];
}
%new
- (void)_toggleShowUnknownArray {
    showUnknownArray = !showUnknownArray;
    if (button) button.selected = showUnknownArray;
    [self updateConversationList];
    persistDefaultsState();
}
%end

%hook SMSApplication
- (void)applicationWillTerminate {
    persistDefaultsState();
    return %orig;
}
%end
%end

// IMAgent Hooks

%group IMAgent
%hook IMDBadgeUtilities
- (instancetype)init {
    id orig = %orig;
    imdbu = orig;
    return orig;
}
- (void)updateBadgeForUnreadCountChangeIfNeeded:(long long)count {
    return shouldHideUnknownUnreadCountFromSBBadge ? %orig(knownUnreadCount) : %orig;
}
%end
%end

// TCCd Hooks

%group TCCd
%hook TCCDService
- (void)setDefaultAllowedIdentifiersList:(NSArray *)list {
    if ([self.name isEqual:@"kTCCServiceFaceID"]) {
        NSMutableArray *mutableList = [list mutableCopy];
        [mutableList addObject:@"com.apple.MobileSMS"];
        return %orig(mutableList);
    }
    return %orig;
}
%end
%end

// SpringBoard Hooks

%group SpringBoard
%hook SpringBoard
- (BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)event {
    bool containsVolumeUp = false;
    bool containsVolumeDown = false;
    for (UIPress *press in event.allPresses)
        if (press.force == 1) {
            if (!containsVolumeUp) containsVolumeUp = press.type == 102;
            if (!containsVolumeDown) containsVolumeDown = press.type == 103;
        }
    if (containsVolumeUp && containsVolumeDown && notificationCentre)
        [notificationCentre postNotificationWithName:toggleShowUnknownArrayNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
    return %orig;
}
- (void)_ringerChanged:(void *)event {
    if (shouldToggleWhenRingerSwitched) {
        if (lastRingerSwitch && [lastRingerSwitch timeIntervalSinceNow] > -2) ringerSwitchedCount++;
        else ringerSwitchedCount = 1;
        lastRingerSwitch = [NSDate date];
        if (shouldToggleWhenRingerSwitched && ringerSwitchedCount == 3) {
            ringerSwitchedCount = 0;
            if (notificationCentre) [notificationCentre postNotificationWithName:toggleShowUnknownArrayNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
        }
    }
    return %orig;
}
%end
%end

// Constructor

%ctor {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.jacobcxdev.idunnou.plist"];
    if (settings) {
        bool enabled = [settings objectForKey:@"enabled"] ? [[settings objectForKey:@"enabled"] boolValue] : true;
        if (!enabled) return;
        shouldShowButton = [settings objectForKey:shouldShowButtonKey] ? [[settings objectForKey:shouldShowButtonKey] boolValue] : true;
        shouldToggleWhenShaken = [settings objectForKey:shouldToggleWhenShakenKey] && [[settings objectForKey:shouldToggleWhenShakenKey] boolValue];
        shouldToggleWhenVolumePressedSimultaneously = [settings objectForKey:shouldToggleWhenVolumePressedSimultaneouslyKey] && [[settings objectForKey:shouldToggleWhenVolumePressedSimultaneouslyKey] boolValue];
        shouldToggleWhenRingerSwitched = [settings objectForKey:shouldToggleWhenRingerSwitchedKey] && [[settings objectForKey:shouldToggleWhenRingerSwitchedKey] boolValue];
        shouldHideUnknownUnreadCountFromSBBadge = [settings objectForKey:shouldHideUnknownUnreadCountFromSBBadgeKey] && [[settings objectForKey:shouldHideUnknownUnreadCountFromSBBadgeKey] boolValue];
        shouldHideButtonBadge = [settings objectForKey:shouldHideButtonBadgeKey] && [[settings objectForKey:shouldHideButtonBadgeKey] boolValue];
        shouldSecureUnknownList = [settings objectForKey:shouldSecureUnknownListKey] && [[settings objectForKey:shouldSecureUnknownListKey] boolValue];
    }

    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.tccd"]) %init(TCCd);
    else {
        notificationCentre = [iDUNotificationCentre centre];
        NSString *mainBundleID = [NSBundle mainBundle].bundleIdentifier;
        if ([mainBundleID isEqualToString:@"com.apple.MobileSMS"]) {
            userDefaults = [NSUserDefaults standardUserDefaults];
            showUnknownArray = shouldSecureUnknownList ? false : [userDefaults boolForKey:showUnknownArrayKey];
            notificationCentre.postHandler = ^NSDictionary *(NSString *name) {
                if ([name isEqualToString:localUpdateNotificationName]) {
                    return @{
                        shouldHideUnknownUnreadCountFromSBBadgeKey: @(shouldHideUnknownUnreadCountFromSBBadge),
                        knownUnreadCountKey: @(knownUnreadCount),
                        unknownUnreadCountKey: @(unknownUnreadCount)
                    };
                }
                return nil;
            };
            notificationCentre.receivedHandler = ^(NSNotification *notification) {
                if ([notification.name isEqualToString:toggleShowUnknownArrayNotificationName]) {
                    if (ckclc && [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                        [ckclc toggleShowUnknownArray];
                } else if ([notification.name isEqualToString:localRequestNotificationName]) {
                    [notificationCentre postNotificationUsingPostHandlerWithName:localUpdateNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
                } else if ([notification.name isEqualToString:userDefaultsDidUpdateNotificationName]) {
                    restoreDefaultsState();
                    if (ckclc) [ckclc updateConversationList];
                }
            };
            [notificationCentre observeNotificationsWithName:toggleShowUnknownArrayNotificationName from:[NSDistributedNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:localRequestNotificationName from:[NSDistributedNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:userDefaultsDidUpdateNotificationName from:[NSDistributedNotificationCenter defaultCenter]];
            [notificationCentre postNotificationWithName:iCloudRestoreNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
            %init(Messages);
        } else if ([mainBundleID isEqualToString:@"com.apple.imagent"]) {
            userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.apple.MobileSMS"];
            notificationCentre.receivedHandler = ^(NSNotification *notification) {
                if ([notification.name isEqualToString:localUpdateNotificationName]) {
                    shouldHideUnknownUnreadCountFromSBBadge = [notification.userInfo objectForKey:shouldHideUnknownUnreadCountFromSBBadgeKey] && [[notification.userInfo objectForKey:shouldHideUnknownUnreadCountFromSBBadgeKey] boolValue];
                    knownUnreadCount = [notification.userInfo objectForKey:knownUnreadCountKey] ? [[notification.userInfo objectForKey:knownUnreadCountKey] intValue] : [userDefaults integerForKey:knownUnreadCountKey];
                    unknownUnreadCount = [notification.userInfo objectForKey:unknownUnreadCountKey] ? [[notification.userInfo objectForKey:unknownUnreadCountKey] intValue] : [userDefaults integerForKey:unknownUnreadCountKey];
                    if (imdbu) [imdbu updateBadgeForUnreadCountChangeIfNeeded:knownUnreadCount + unknownUnreadCount];
                }
            };
            [notificationCentre observeNotificationsWithName:localUpdateNotificationName from:[NSDistributedNotificationCenter defaultCenter]];
            [notificationCentre postNotificationWithName:localRequestNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
            %init(IMAgent);
        } else if ([mainBundleID isEqualToString:@"com.apple.springboard"]) {
            userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.apple.MobileSMS"];
            store = [NSUbiquitousKeyValueStore defaultStore];
            notificationCentre.receivedHandler = ^(NSNotification *notification) {
                if ([notification.name isEqualToString:iCloudPersistNotificationName]) {
                    restoreDefaultsState();
                    persistiCloudState();
                } else if ([notification.name isEqualToString:iCloudRestoreNotificationName] || [notification.name isEqualToString:NSUbiquitousKeyValueStoreDidChangeExternallyNotification]) {
                    restoreiCloudState();
                    persistDefaultsState();
                    [notificationCentre postNotificationWithName:userDefaultsDidUpdateNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
                }
            };
            [notificationCentre observeNotificationsWithName:iCloudPersistNotificationName from:[NSDistributedNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:iCloudRestoreNotificationName from:[NSDistributedNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store from:[NSNotificationCenter defaultCenter]];
            %init(SpringBoard);
        } else return;

        restoreDefaultsState();
        if (imdbu) [imdbu updateBadgeForUnreadCountChangeIfNeeded:knownUnreadCount + unknownUnreadCount];
    }

    NSLog(@"iDunnoU loaded");
}