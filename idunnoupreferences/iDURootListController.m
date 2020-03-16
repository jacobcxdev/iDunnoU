#include "iDURootListController.h"

@implementation iDURootListController
- (instancetype)init {
    [iDUPackageInfo retrieveControl];
    return [super init];
}
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    return _specifiers;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(killall)];
    self.navigationItem.rightBarButtonItem = button;
}
- (void)killall {
    NSTask *killallIMAgent = [[NSTask alloc] init];
    [killallIMAgent setLaunchPath:@"/usr/bin/killall"];
    [killallIMAgent setArguments:@[@"-9", @"imagent"]];
    [killallIMAgent launch];
    NSTask *killallSpringBoard = [[NSTask alloc] init];
    [killallSpringBoard setLaunchPath:@"/usr/bin/killall"];
    [killallSpringBoard setArguments:@[@"-9", @"SpringBoard"]];
    [killallSpringBoard launch];
}
@end
