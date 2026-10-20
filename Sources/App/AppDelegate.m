#import "AppDelegate.h"
#import "MainTabBarController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    MainTabBarController *tabBar = [[MainTabBarController alloc] init];
    self.window.rootViewController = tabBar;

    [self.window makeKeyAndVisible];
    return YES;
}

@end
