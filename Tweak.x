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
static bool shouldShowButtonAfterAuthentication = false;
static NSString *shouldShowButtonAfterAuthenticationKey = @"shouldShowButtonAfterAuthentication";
static bool shouldAutoHideUnknownList = false;
static NSString *shouldAutoHideUnknownListKey = @"shouldAutoHideUnknownList";
static bool shouldHideSwipeActions = false;
static NSString *shouldHideSwipeActionsKey = @"shouldHideSwipeActions";
static bool showUnknownArray = false;
static NSString *showUnknownArrayKey = @"showUnknownArray";

static UIWindow *blurWindow;
static bool isAuthenticated = false;
static bool shouldHideCurrentConversation = false;

static NSUInteger knownUnreadCount = 0;
static NSString *knownUnreadCountKey = @"knownUnreadCount";
static NSUInteger unknownUnreadCount = 0;
static NSString *unknownUnreadCountKey = @"unknownUnreadCount";

static NSMutableArray *mutedConversationList;
static NSString *mutedConversationListKey = @"com.jacobcxdev.idunnou.mutedConversationList";
static NSMutableArray *pinnedConversationList;
static NSString *pinnedConversationListKey = @"com.jacobcxdev.idunnou.pinnedConversationList";
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

static JCXNotificationCentre *notificationCentre;
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
    mutedConversationList = [userDefaults arrayForKey:mutedConversationListKey] ? [[userDefaults arrayForKey:mutedConversationListKey] mutableCopy] : [NSMutableArray new];
    pinnedConversationList = [userDefaults arrayForKey:pinnedConversationListKey] ? [[userDefaults arrayForKey:pinnedConversationListKey] mutableCopy] : [NSMutableArray new];
    conversationBlacklist = [userDefaults arrayForKey:conversationBlacklistKey] ? [[userDefaults arrayForKey:conversationBlacklistKey] mutableCopy] : [NSMutableArray new];
    conversationWhitelist = [userDefaults arrayForKey:conversationWhitelistKey] ? [[userDefaults arrayForKey:conversationWhitelistKey] mutableCopy] : [NSMutableArray new];
}

static void restoreiCloudState() {
    if (!store) return;
    [store synchronize];
    mutedConversationList = [store arrayForKey:mutedConversationListKey] ? [[store arrayForKey:mutedConversationListKey] mutableCopy] : [NSMutableArray new];
    pinnedConversationList = [store arrayForKey:pinnedConversationListKey] ? [[store arrayForKey:pinnedConversationListKey] mutableCopy] : [NSMutableArray new];
    conversationBlacklist = [store arrayForKey:conversationBlacklistKey] ? [[store arrayForKey:conversationBlacklistKey] mutableCopy] : [NSMutableArray new];
    conversationWhitelist = [store arrayForKey:conversationWhitelistKey] ? [[store arrayForKey:conversationWhitelistKey] mutableCopy] : [NSMutableArray new];
}

static void persistDefaultsState() {
    if (!userDefaults) return;
    [userDefaults setBool:showUnknownArray forKey:showUnknownArrayKey];
    [userDefaults setInteger:knownUnreadCount forKey:knownUnreadCountKey];
    [userDefaults setInteger:unknownUnreadCount forKey:unknownUnreadCountKey];
    [userDefaults setObject:mutedConversationList forKey:mutedConversationListKey];
    [userDefaults setObject:pinnedConversationList forKey:pinnedConversationListKey];
    [userDefaults setObject:conversationBlacklist forKey:conversationBlacklistKey];
    [userDefaults setObject:conversationWhitelist forKey:conversationWhitelistKey];
}

static void persistiCloudState() {
    if (!store) return;
    [store setArray:mutedConversationList forKey:mutedConversationListKey];
    [store setArray:pinnedConversationList forKey:pinnedConversationListKey];
    [store setArray:conversationBlacklist forKey:conversationBlacklistKey];
    [store setArray:conversationWhitelist forKey:conversationWhitelistKey];
}

static NSMutableArray *filterConversations(NSArray *conversations, bool updateUnreadCount) {
    NSMutableArray *pendingKnownArray = [NSMutableArray new];
    NSMutableArray *knownArray = [NSMutableArray new];
    NSMutableArray *pendingUnknownArray = [NSMutableArray new];
    NSMutableArray *unknownArray = [NSMutableArray new];
    NSUInteger pendingKnownUnreadCount = 0;
    NSUInteger pendingUnknownUnreadCount = 0;
    for (CKConversation *conversation in conversations)
        if (([[conversation chat] hasKnownParticipants] && ![conversation isBlacklisted]) || (![[conversation chat] hasKnownParticipants] && [conversation isWhitelisted])) {
            pendingKnownUnreadCount += [conversation unreadCount];
            if ([conversation isPinned]) [knownArray addObject:conversation];
            else [pendingKnownArray addObject:conversation];
        } else {
            pendingUnknownUnreadCount += [conversation unreadCount];
            if ([conversation isPinned]) [unknownArray addObject:conversation];
            else [pendingUnknownArray addObject:conversation];
        }
    [knownArray sortUsingComparator:^NSComparisonResult(CKConversation* a, CKConversation* b) {
        return [@([pinnedConversationList indexOfObject:[a uniqueIdentifier]]) compare:@([pinnedConversationList indexOfObject:[b uniqueIdentifier]])];
    }];
    [unknownArray sortUsingComparator:^NSComparisonResult(CKConversation* a, CKConversation* b) {
        return [@([pinnedConversationList indexOfObject:[a uniqueIdentifier]]) compare:@([pinnedConversationList indexOfObject:[b uniqueIdentifier]])];
    }];
    [knownArray addObjectsFromArray:pendingKnownArray];
    [unknownArray addObjectsFromArray:pendingUnknownArray];
    if (updateUnreadCount) {
        knownUnreadCount = pendingKnownUnreadCount;
        unknownUnreadCount = pendingUnknownUnreadCount;
        updateBadgeCount();
        [notificationCentre postNotificationUsingPostHandlerWithName:localUpdateNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
    }
    return showUnknownArray ? unknownArray : knownArray;
}

static UISwipeActionsConfiguration *tableViewLeadingSwipeActionsConfigurationForRowAtIndexPath(CKConversationListController *self, UITableView *tableView, NSIndexPath *indexPath) {
    if (shouldHideSwipeActions) return nil;
    CKConversationListStandardCell *cell = (CKConversationListStandardCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    CKConversation *conversation = [cell conversation];
    CKEntity *recipient = [conversation recipient];
    UIContextualAction *hideUnhideAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:([[conversation chat] hasKnownParticipants] && [conversation isBlacklisted]) || (![[conversation chat] hasKnownParticipants] && ![conversation isWhitelisted]) ? @"Unhide" : @"Hide" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        if ([[conversation chat] hasKnownParticipants]) {
            if ([conversation isBlacklisted]) [conversation removeFromBlacklist];
            else [conversation blacklist];
        } else {
            if ([conversation isWhitelisted]) [conversation removeFromWhitelist];
            else [conversation whitelist];
        }
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        completionHandler(true);
    }];
    hideUnhideAction.backgroundColor = [conversation isBlacklisted] || (![[conversation chat] hasKnownParticipants] && ![conversation isWhitelisted]) ? [UIColor systemTealColor] : [UIColor systemBlueColor];
    NSMutableArray *actions = [NSMutableArray new];
    [actions addObject:hideUnhideAction];
    if (recipient && [[recipient cnContact] handles].count != 0) {
        CNContactToggleBlockCallerAction *cnBlockAction = [[%c(CNContactToggleBlockCallerAction) alloc] initWithContact:[recipient cnContact]];
        UIContextualAction *blockAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:[cnBlockAction isBlocked] ? @"Unblock" : @"Block" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            if ([cnBlockAction isBlocked]) [cnBlockAction unblock];
            else [cnBlockAction block];
            completionHandler(true);
        }];
        blockAction.backgroundColor = [UIColor systemRedColor];
        [actions addObject:blockAction];
    }
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}

// Messages Hooks

%group Messages_LeadingSwipeActionsExist
%hook CKConversationListController
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwipeActionsConfiguration *orig = %orig;
    UISwipeActionsConfiguration *config = tableViewLeadingSwipeActionsConfigurationForRowAtIndexPath(self, tableView, indexPath);
    if (!config) return orig;
    NSMutableArray *actions = [config.actions mutableCopy];
    if (orig) {
        [actions addObjectsFromArray:orig.actions];
    }
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}
%end
%end

%group Messages_LeadingSwipeActionsDoNotExist
%hook CKConversationListController
%new
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableViewLeadingSwipeActionsConfigurationForRowAtIndexPath(self, tableView, indexPath);
}
%end
%end

%group Messages
%hook CKConversation
+ (BOOL)pinnedConversationsEnabled {
    return true;
}
- (BOOL)isMuted {
    return [mutedConversationList containsObject:[self uniqueIdentifier]];
}
- (void)setMutedUntilDate:(NSDate *)date {
    [mutedConversationList addObject:[self uniqueIdentifier]];
    persistDefaultsState();
    [notificationCentre postNotificationWithName:iCloudPersistNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
    return %orig;
}
- (void)unmute {
    [mutedConversationList removeObject:[self uniqueIdentifier]];
    persistDefaultsState();
    [notificationCentre postNotificationWithName:iCloudPersistNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
    return %orig;
}
- (BOOL)isPinned {
    return [pinnedConversationList containsObject:[self uniqueIdentifier]];
}
- (void)setPinned:(BOOL)pinned {
    if (pinned) [pinnedConversationList addObject:[self uniqueIdentifier]];
    else [pinnedConversationList removeObject:[self uniqueIdentifier]];
    persistDefaultsState();
    [notificationCentre postNotificationWithName:iCloudPersistNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
    return %orig;
}
%new
- (void)blacklist {
    [conversationBlacklist addObject:[self uniqueIdentifier]];
    persistDefaultsState();
    [notificationCentre postNotificationWithName:iCloudPersistNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
}
%new
- (void)removeFromBlacklist {
    [conversationBlacklist removeObject:[self uniqueIdentifier]];
    persistDefaultsState();
    [notificationCentre postNotificationWithName:iCloudPersistNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
}
%new
- (BOOL)isBlacklisted {
    return [conversationBlacklist containsObject:[self uniqueIdentifier]];
}
%new
- (void)whitelist {
    [conversationWhitelist addObject:[self uniqueIdentifier]];
    persistDefaultsState();
    [notificationCentre postNotificationWithName:iCloudPersistNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
}
%new
- (void)removeFromWhitelist {
    [conversationWhitelist removeObject:[self uniqueIdentifier]];
    persistDefaultsState();
    [notificationCentre postNotificationWithName:iCloudPersistNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
}
%new
- (BOOL)isWhitelisted {
    return [conversationWhitelist containsObject:[self uniqueIdentifier]];
}
%end

%hook CKConversationList
- (NSMutableArray *)conversations {
    return filterConversations(%orig, true);
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
- (NSArray *)activeConversations {
    return [filterConversations(%orig, false) copy];
}
- (void)viewDidLayoutSubviews {
    if (!self.navigationItem.leftBarButtonItem) {
        if (!bbi) {
            if (!button) {
                button = [iDUBadgeButton buttonWithType:UIButtonTypeCustom];
                [button setImage:[UIImage systemImageNamed:@"questionmark.circle"] forState:UIControlStateNormal];
                [button setImage:[UIImage systemImageNamed:@"person.crop.circle"] forState:UIControlStateSelected];
                [button addTarget:self action:@selector(toggleShowUnknownArray) forControlEvents:UIControlEventTouchUpInside];
                button.backgroundColor = [UIColor secondarySystemFillColor];
                button.frame = CGRectMake(0, 0, 30, 30);
                button.layer.cornerRadius = 15;
                button.alpha = shouldShowButton ? 1 : 0;
                button.hidden = !shouldShowButton;
            }
            bbi = [[UIBarButtonItem alloc] initWithCustomView:button];
        }
        self.navigationItem.leftBarButtonItem = bbi;
    }
    updateBadgeCount();
    return %orig;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CKConversationListStandardCell *cell = (CKConversationListStandardCell *)%orig;
    if (![cell isKindOfClass:%c(CKConversationListStandardCell)]) return cell;
    if ([[cell conversation] isPinned]) {
        UIImageView *unreadIndicatorView = [cell valueForKey:@"_unreadIndicatorImageView"];
        if (unreadIndicatorView) {
            unreadIndicatorView.tintColor = [UIColor systemOrangeColor];
            CKUIBehavior *uiBehavior = [%c(CKUIBehavior) sharedBehaviors];
            if ([[cell conversation] hasUnreadMessages]) {
                if ([[cell conversation] isMuted]) unreadIndicatorView.image = [[uiBehavior unreadDNDImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                else unreadIndicatorView.image = [[uiBehavior unreadPinnedImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [UIView animateKeyframesWithDuration:1 delay:0 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat animations:^{
                    [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5 animations:^{
                        unreadIndicatorView.tintColor = [UIColor systemBlueColor];
                    }];
                    [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
                        unreadIndicatorView.tintColor = [UIColor systemOrangeColor];
                    }];
                } completion:nil];
            } else {
                if ([[cell conversation] isMuted]) unreadIndicatorView.image = [[uiBehavior readDNDImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                else unreadIndicatorView.image = [[uiBehavior readPinnedImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
        }
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSMutableArray *pinnedConversations = [NSMutableArray new];
    for (CKConversation *conversation in [self activeConversations])
        if ([conversation isPinned]) [pinnedConversations addObject:conversation];
    CKConversation *mobileConversation = pinnedConversations[sourceIndexPath.row];
    [pinnedConversations removeObject:mobileConversation];
    [pinnedConversations insertObject:mobileConversation atIndex:destinationIndexPath.row];
    for (CKConversation *conversation in pinnedConversations) {
        [pinnedConversationList removeObject:[conversation uniqueIdentifier]];
        [conversation setPinned:true];
    }
    return %orig;
}
%new
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (shouldToggleWhenShaken && motion == UIEventSubtypeMotionShake) [self toggleShowUnknownArray];
}
%new
- (void)toggleShowUnknownArray {
    if (shouldSecureUnknownList && !isAuthenticated && !showUnknownArray) {
        LAContext *context = [LAContext new];
        NSError *error = nil;
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error])
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"iDunnoU" reply:^(BOOL success, NSError *error) {
                if (success) dispatch_async(dispatch_get_main_queue(), ^{
                    isAuthenticated = true;
                    [self _toggleShowUnknownArray];
                });
            }];
    } else [self _toggleShowUnknownArray];
}
%new
- (void)setButtonHidden:(bool)hidden {
    if (!button || button.hidden == hidden) return;
    if (button.hidden) button.hidden = false;
    [UIView animateWithDuration:0.25 animations:^{
        button.alpha = hidden ? 0 : 1;
    } completion:^(BOOL finished) {
        button.hidden = hidden;
    }];
}
%new
- (void)_toggleShowUnknownArray {
    showUnknownArray = !showUnknownArray;
    if (button) {
        button.selected = showUnknownArray;
        if (shouldShowButtonAfterAuthentication) [self setButtonHidden:false];
    }
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
        return %orig([mutableList copy]);
    }
    return %orig;
}
%end
%end

// SpringBoard Hooks

%group SpringBoard
%hook SpringBoard
- (BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)event {
    if (shouldToggleWhenVolumePressedSimultaneously) {
        bool containsVolumeUp = false;
        bool containsVolumeDown = false;
        for (UIPress *press in event.allPresses)
            if (press.force == 1) {
                if (!containsVolumeUp) containsVolumeUp = press.type == 102;
                if (!containsVolumeDown) containsVolumeDown = press.type == 103;
            }
        if (containsVolumeUp && containsVolumeDown && notificationCentre)
            [notificationCentre postNotificationWithName:toggleShowUnknownArrayNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
    }
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
        shouldShowButtonAfterAuthentication = [settings objectForKey:shouldShowButtonAfterAuthenticationKey] && [[settings objectForKey:shouldShowButtonAfterAuthenticationKey] boolValue];
        shouldAutoHideUnknownList = [settings objectForKey:shouldAutoHideUnknownListKey] && [[settings objectForKey:shouldAutoHideUnknownListKey] boolValue];
        shouldHideSwipeActions = [settings objectForKey:shouldHideSwipeActionsKey] && [[settings objectForKey:shouldHideSwipeActionsKey] boolValue];
    }

    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.tccd"]) %init(TCCd);
    else {
        notificationCentre = [JCXNotificationCentre centre];
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
                if ([notification.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
                    if (blurWindow && !blurWindow.hidden) {
                        [UIView animateWithDuration:0.25 animations:^{
                            blurWindow.alpha = 0;
                        } completion:^(BOOL finished){
                            blurWindow.hidden = true;
                        }];
                    }
                } else if ([notification.name isEqualToString:UIApplicationWillEnterForegroundNotification]) {
                    if (ckclc) {
                        [ckclc.tableView reloadData];
                        if (shouldHideCurrentConversation) {
                            shouldHideCurrentConversation = false;
                            [[ckclc messagesController] showConversationList:true];
                        }
                    }
                    if (ckclc && !shouldShowButton) [ckclc setButtonHidden:true];
                } else if ([notification.name isEqualToString:UIApplicationWillResignActiveNotification]) {
                    if ((shouldSecureUnknownList || shouldAutoHideUnknownList) && showUnknownArray) {
                        if (!blurWindow) {
                            UIWindowScene *scene = (UIWindowScene *)[UIApplication.sharedApplication.connectedScenes.allObjects firstObject];
                            if (!scene) return;
                            blurWindow = [[UIWindow alloc] initWithWindowScene:scene];
                            blurWindow.frame = UIScreen.mainScreen.bounds;
                            blurWindow.windowLevel = UIWindowLevelAlert;
                            blurWindow.alpha = 0;
                            UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]];
                            blurEffectView.frame = blurWindow.frame;
                            [blurWindow addSubview:blurEffectView];
                        }
                        blurWindow.hidden = false;
                        [UIView animateWithDuration:0.25 animations:^{
                            blurWindow.alpha = 1;
                        }];
                        [blurWindow makeKeyAndVisible];
                    }
                } else if ([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
                    isAuthenticated = false;
                    if (shouldAutoHideUnknownList && showUnknownArray) {
                        showUnknownArray = false;
                        shouldHideCurrentConversation = true;
                        if (ckclc) [ckclc updateConversationList];
                    }
                } else if ([notification.name isEqualToString:toggleShowUnknownArrayNotificationName]) {
                    if (ckclc && [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                        [ckclc toggleShowUnknownArray];
                } else if ([notification.name isEqualToString:localRequestNotificationName]) {
                    [notificationCentre postNotificationUsingPostHandlerWithName:localUpdateNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
                } else if ([notification.name isEqualToString:userDefaultsDidUpdateNotificationName]) {
                    restoreDefaultsState();
                    if (ckclc) [ckclc updateConversationList];
                }
            };
            [notificationCentre observeNotificationsWithName:UIApplicationDidBecomeActiveNotification from:[NSNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:UIApplicationWillEnterForegroundNotification from:[NSNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:UIApplicationWillResignActiveNotification from:[NSNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:UIApplicationDidEnterBackgroundNotification from:[NSNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:toggleShowUnknownArrayNotificationName from:[NSDistributedNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:localRequestNotificationName from:[NSDistributedNotificationCenter defaultCenter]];
            [notificationCentre observeNotificationsWithName:userDefaultsDidUpdateNotificationName from:[NSDistributedNotificationCenter defaultCenter]];
            [notificationCentre postNotificationWithName:iCloudRestoreNotificationName to:[NSDistributedNotificationCenter defaultCenter]];
            %init(Messages);
            if ([%c(CKConversationListController) instancesRespondToSelector:@selector(tableView:leadingSwipeActionsConfigurationForRowAtIndexPath:)]) {
                %init(Messages_LeadingSwipeActionsExist);
            } else {
                %init(Messages_LeadingSwipeActionsDoNotExist);
            }
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