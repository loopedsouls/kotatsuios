#import "MainTabBarController.h"
#import "LibraryViewController.h"
#import "SourceListViewController.h"
#import "SettingsViewController.h"

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    LibraryViewController *library = [[LibraryViewController alloc] init];
    UINavigationController *libraryNav = [[UINavigationController alloc] initWithRootViewController:library];
    libraryNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Library", nil)
                                                          image:[UIImage systemImageNamed:@"books.vertical"]
                                                            tag:0];
    libraryNav.navigationBar.prefersLargeTitles = YES;

    SourceListViewController *sources = [[SourceListViewController alloc] init];
    UINavigationController *sourcesNav = [[UINavigationController alloc] initWithRootViewController:sources];
    sourcesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Sources", nil)
                                                          image:[UIImage systemImageNamed:@"globe"]
                                                            tag:1];
    sourcesNav.navigationBar.prefersLargeTitles = YES;

    SettingsViewController *settings = [[SettingsViewController alloc] init];
    UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settings];
    settingsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil)
                                                           image:[UIImage systemImageNamed:@"gearshape"]
                                                             tag:2];
    settingsNav.navigationBar.prefersLargeTitles = YES;

    self.viewControllers = @[libraryNav, sourcesNav, settingsNav];
}

@end
