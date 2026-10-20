#import "LibraryViewController.h"
#import "Manga.h"
#import "MangaDexParser.h"
#import "MangaDetailsViewController.h"

static NSString * const kCellIdentifier = @"MangaCell";

#pragma mark - MangaCell (forward declaration)

@interface MangaCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
- (void)configureWithManga:(Manga *)manga;
@end

@interface LibraryViewController ()
@property (nonatomic, strong) NSMutableArray<Manga *> *mangaItems;
@property (nonatomic, strong) NSMutableArray<Manga *> *filteredItems;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, copy) NSString *searchQuery;
@end

@implementation LibraryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Library", nil);
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.mangaItems = [NSMutableArray array];
    self.filteredItems = [NSMutableArray array];
    self.currentPage = 0;
    self.hasMore = YES;
    self.isLoading = NO;

    [self setupCollectionView];
    [self setupSearchController];
    [self setupRefreshControl];
    [self loadFirstPage];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 8.0;
    layout.minimumLineSpacing = 16.0;
    layout.sectionInset = UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0);

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                             collectionViewLayout:layout];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundColor = [UIColor systemBackgroundColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[MangaCell class] forCellWithReuseIdentifier:kCellIdentifier];
    [self.view addSubview:self.collectionView];
}

- (void)setupSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = NSLocalizedString(@"Search manga", nil);
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
}

- (void)setupRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
}

#pragma mark - Data loading

- (void)loadFirstPage {
    if (self.isLoading) return;
    self.isLoading = YES;
    self.currentPage = 1;
    self.isSearching = NO;
    self.searchQuery = nil;

    __weak typeof(self) weakSelf = self;
    [[MangaDexParser sharedParser] fetchPopularWithPage:1
        completion:^(NSArray<Manga *> *mangas, BOOL hasMore, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                strongSelf.isLoading = NO;
                [strongSelf.refreshControl endRefreshing];
                if (error) {
                    [strongSelf showError:error];
                    return;
                }
                [strongSelf.mangaItems removeAllObjects];
                [strongSelf.mangaItems addObjectsFromArray:mangas];
                [strongSelf.filteredItems removeAllObjects];
                [strongSelf.filteredItems addObjectsFromArray:mangas];
                [strongSelf reloadData];
            });
        }];
}

- (void)loadNextPage {
    if (self.isLoading || !self.hasMore) return;
    if (self.isSearching) return;
    self.isLoading = YES;
    NSInteger next = self.currentPage + 1;

    __weak typeof(self) weakSelf = self;
    [[MangaDexParser sharedParser] fetchPopularWithPage:next
        completion:^(NSArray<Manga *> *mangas, BOOL hasMore, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                strongSelf.isLoading = NO;
                if (error) return;
                strongSelf.currentPage = next;
                strongSelf.hasMore = hasMore;
                [strongSelf.mangaItems addObjectsFromArray:mangas];
                [strongSelf.filteredItems addObjectsFromArray:mangas];
                [strongSelf reloadData];
            });
        }];
}

- (void)performSearch:(NSString *)query {
    if (self.isLoading) return;
    self.isLoading = YES;
    self.isSearching = YES;
    self.searchQuery = query;

    __weak typeof(self) weakSelf = self;
    [[MangaDexParser sharedParser] searchWithQuery:query page:1
        completion:^(NSArray<Manga *> *mangas, BOOL hasMore, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                strongSelf.isLoading = NO;
                if (error) {
                    [strongSelf showError:error];
                    return;
                }
                [strongSelf.filteredItems removeAllObjects];
                [strongSelf.filteredItems addObjectsFromArray:mangas];
                [strongSelf reloadData];
            });
        }];
}

- (void)handleRefresh {
    if (self.isSearching && self.searchQuery.length > 0) {
        [self performSearch:self.searchQuery];
    } else {
        [self loadFirstPage];
    }
}

- (void)showError:(NSError *)error {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                         message:error.localizedDescription
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reloadData {
    [self.collectionView reloadData];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *query = searchController.searchBar.text;
    if (query.length == 0) {
        if (self.isSearching) {
            self.isSearching = NO;
            self.searchQuery = nil;
            [self.filteredItems removeAllObjects];
            [self.filteredItems addObjectsFromArray:self.mangaItems];
            [self reloadData];
        }
        return;
    }
    // Debounce simples: busca ao digitar (com cancelamento de requisição anterior implícito)
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearch:) object:query];
    [self performSelector:@selector(performSearch:) withObject:query afterDelay:0.5];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MangaCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    Manga *manga = self.filteredItems[indexPath.item];
    [cell configureWithManga:manga];

    // Infinite scroll
    if (indexPath.item >= self.filteredItems.count - 5 && !self.isSearching) {
        [self loadNextPage];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (collectionView.bounds.size.width - 12.0 - 16.0 - 8.0) / 2.0;
    return CGSizeMake(width, width * 1.7);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    Manga *manga = self.filteredItems[indexPath.item];
    MangaDetailsViewController *details = [[MangaDetailsViewController alloc] initWithManga:manga];
    [self.navigationController pushViewController:details animated:YES];
}

@end

#pragma mark - MangaCell

@implementation MangaCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 12.0;
        self.contentView.clipsToBounds = YES;
        self.contentView.backgroundColor = [UIColor secondarySystemBackgroundColor];

        self.coverImageView = [[UIImageView alloc] init];
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.coverImageView.clipsToBounds = YES;
        self.coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.coverImageView];

        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
        self.spinner.hidesWhenStopped = YES;
        [self.contentView addSubview:self.spinner];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        self.titleLabel.textColor = [UIColor labelColor];
        self.titleLabel.numberOfLines = 2;
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.titleLabel];

        [NSLayoutConstraint activateConstraints:@[
            [self.coverImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [self.coverImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [self.coverImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [self.coverImageView.heightAnchor constraintEqualToAnchor:self.contentView.heightAnchor
                                                           multiplier:0.78],

            [self.spinner.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [self.spinner.centerYAnchor constraintEqualToAnchor:self.coverImageView.centerYAnchor],

            [self.titleLabel.topAnchor constraintEqualToAnchor:self.coverImageView.bottomAnchor constant:6.0],
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8.0],
            [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8.0],
            [self.titleLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-6.0],
        ]];
    }
    return self;
}

- (void)configureWithManga:(Manga *)manga {
    self.titleLabel.text = manga.title;
    self.coverImageView.image = nil;

    if (manga.coverURL.length == 0) return;
    NSURL *url = [NSURL URLWithString:manga.coverURL];
    if (!url) return;

    __weak typeof(self) weakSelf = self;
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
    [[[NSURLSession sharedSession] dataTaskWithURL:url
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error || data.length == 0) return;
            UIImage *img = [UIImage imageWithData:data];
            if (!img) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                // Evita imagem errada em célula reciclada
                if (![strongSelf.titleLabel.text isEqualToString:manga.title]) return;
                strongSelf.coverImageView.image = img;
                [strongSelf.spinner stopAnimating];
            });
        }] resume];
}

@end
