#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LibraryViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
