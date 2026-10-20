#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SourceListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *sources;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
